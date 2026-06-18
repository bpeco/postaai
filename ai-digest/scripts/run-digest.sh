#!/usr/bin/env bash
# Orchestrator: fetch → extract → rank → 3× claude (digest, ideas, reels) → cards (Pool) → 2 emails → publish CDN.
#
# Single entry point for both manual runs and launchd.
# Live progress to stderr; full log at /tmp/ai-digest-<STAMP>.log.
#
# Flags:
#   --dry-run     skip claude phases (4-7), emails (8-9) y publish (10). Tests phases 1-3 only.
#   --no-email    skip the email phases (8-9) but still generate digest/ideas/reels + Pool + publish.
#   --no-publish  skip phase 10 (no push al CDN). Útil para tests locales.
#   --pool-only   solo lo que necesita la app: fases 1-3 + 7 (Pool) + 10 (publish). Saltea
#                 digest/ideas/reels (4-6) y emails (8-9). 1 sola llamada a claude. Es el modo
#                 del cron en la nube (Etapa 5): el digest/reels es workflow de creador, va a mano.

set -euo pipefail

# Explicit PATH so this script runs identically under launchd (clean env) and interactively.
# Locations cover every binary the pipeline uses: claude, python3, jq, msmtp, curl, pandoc, base64.
# En CI (GitHub Actions) NO lo pisamos: el runner ubuntu tiene su propio PATH y las deps las
# instala el workflow (claude en ~/.local/bin vía $GITHUB_PATH, python3 de actions/setup-python).
if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
  export PATH="/Users/Bauti/.local/bin:/Users/Bauti/.pyenv/shims:/opt/anaconda3/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
fi

# DIR = raíz de ai-digest, derivado del path del script → portable Mac/CI (no más hardcode).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

STAMP="$(date +%Y-%m-%d-%H)"
LOG="/tmp/ai-digest-$STAMP.log"
RAW="/tmp/digest-raw-$STAMP.json"
ITEMS="/tmp/digest-items-$STAMP.json"
TOP="/tmp/digest-top-$STAMP.json"

DRY_RUN=0
NO_EMAIL=0
NO_PUBLISH=0
POOL_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)    DRY_RUN=1 ;;
    --no-email)   NO_EMAIL=1 ;;
    --no-publish) NO_PUBLISH=1 ;;
    --pool-only)  POOL_ONLY=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

# --pool-only saltea digest/ideas/reels → los emails (que los consumen) no tienen qué mandar.
if (( POOL_ONLY )); then
  NO_EMAIL=1
fi

# Estos paths se setean en las fases 4-6; con --pool-only se saltean, así que los inicializamos
# vacíos para que el log final no reviente con `set -u`.
digest_path=""
ideas_path=""
reels_path=""

log() {
  local msg="[$(date +%H:%M:%S)] $*"
  echo "$msg" >&2
  echo "$msg" >> "$LOG"
}

# claude_cap: corre `claude` con un timeout duro. Sin esto, un `claude -p` headless se puede
# colgar indefinidamente (visto: 8.8h local) y en CI choca contra timeout-minutes:15 → el job
# muere SIN producir Pool. Con el cap, un cuelgue corta a CLAUDE_TIMEOUT (default 300s, holgado
# vs ~217s que tarda la fase 7 sana) y devuelve no-cero → el caller reintenta o falla ruidoso.
# Portable: timeout (CI/linux) → gtimeout (mac+coreutils) → sin cap con warning. Se usa en pipe
# (cat X | claude_cap -p ...): como función bash, hereda stdin transparente.
# 420s: holgura sobre los ~265s que tardó la fase 7 sana en una corrida real, y 2 intentos
# (840s) entran en los 900s del job de CI. Un cuelgue real (indefinido) igual corta acá.
CLAUDE_TIMEOUT="${CLAUDE_TIMEOUT:-420}"
if command -v timeout >/dev/null 2>&1; then
  _TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  _TIMEOUT_BIN="gtimeout"
else
  _TIMEOUT_BIN=""
fi
# --tools "" : el pipeline es una transformación pura texto→texto/JSON, NO necesita tools. Con
#   tools habilitados (default del CLI), claude a veces intenta usar uno y en headless con
#   ~/.claude limpio (CI) se cuelga esperando aprobación para siempre (local anda porque Bauti
#   tiene permisos pre-aprobados). Sin tools = nada que aprobar = no se cuelga. Era la causa del
#   cron muerto desde ~16/06. (Probado: --tools "" → JSON OK; --bare suprime el output de -p, no usar.)
CLAUDE_FLAGS=(--tools "")
# DIAG TEMPORAL: --debug para capturar por qué claude se cuelga en CI (va a stderr → $LOG).
if [ "${CLAUDE_DEBUG:-}" = "1" ]; then CLAUDE_FLAGS+=(--debug); fi
claude_cap() {
  if [ -n "$_TIMEOUT_BIN" ]; then
    "$_TIMEOUT_BIN" "$CLAUDE_TIMEOUT" claude "${CLAUDE_FLAGS[@]}" "$@"
  else
    claude "${CLAUDE_FLAGS[@]}" "$@"
  fi
}

T0=$SECONDS

if [ -z "$_TIMEOUT_BIN" ]; then
  log "WARN: ni 'timeout' ni 'gtimeout' disponibles — las llamadas a claude corren SIN cap (instalá coreutils en Mac: brew install coreutils)"
fi

log "=== run-digest START stamp=$STAMP dry_run=$DRY_RUN no_email=$NO_EMAIL no_publish=$NO_PUBLISH ==="
log "log file: $LOG"

mkdir -p digests ideas reels

# ── Phase 1: fetch ───────────────────────────────────────────────────────
log "[1/10] fetching sources from sources.json..."
t=$SECONDS
./scripts/fetch-sources.sh > "$RAW" 2>>"$LOG"
ok_count="$(jq '[.[] | select(.status==200)] | length' "$RAW")"
total_count="$(jq 'length' "$RAW")"
log "[1/10] done in $((SECONDS - t))s — $ok_count/$total_count sources OK"

# ── Phase 2: extract ─────────────────────────────────────────────────────
log "[2/10] parsing items (extract-items.py)..."
t=$SECONDS
python3 ./scripts/extract-items.py "$RAW" > "$ITEMS" 2>>"$LOG"
items_count="$(jq 'length' "$ITEMS")"
log "[2/10] done in $((SECONDS - t))s — $items_count items extracted"

# ── Phase 3: rank ────────────────────────────────────────────────────────
log "[3/10] ranking + dedup (rank-items.py)..."
t=$SECONDS
python3 ./scripts/rank-items.py "$ITEMS" > "$TOP" 2>>"$LOG"
top_count="$(jq 'length' "$TOP")"
log "[3/10] done in $((SECONDS - t))s — top $top_count selected"

if (( DRY_RUN )); then
  log "DRY RUN — skipping phases 4-9. Top items file: $TOP"
  log "=== run-digest END (dry) total $((SECONDS - T0))s ==="
  exit 0
fi

if (( POOL_ONLY )); then
  log "[4-6/10] skipping digest/ideas/reels (--pool-only — solo Pool para la app)"
else

# ── Phase 4: digest (claude -p) ──────────────────────────────────────────
log "[4/10] generating digest via claude -p (~1-2 min)..."
t=$SECONDS
prompt_digest="$(sed "s|STAMP_PLACEHOLDER|$STAMP|g" prompts/digest.md)"
digest_path="digests/$STAMP.md"
if cat "$TOP" | claude_cap -p "$prompt_digest" > "$digest_path" 2>>"$LOG"; then
  bytes=$(wc -c < "$digest_path" | tr -d ' ')
  log "[4/10] done in $((SECONDS - t))s — $digest_path ($bytes bytes)"
else
  log "[4/10] FAILED (claude exit $?) — see $LOG"
  exit 1
fi

# ── Phase 5: ideas técnico (claude -p) ───────────────────────────────────
log "[5/10] generating ideas técnico via claude -p (~1-2 min)..."
t=$SECONDS
prompt_ideas="$(cat prompts/ideas.md)"
ideas_path="ideas/$STAMP.md"
if cat "$TOP" | claude_cap -p "$prompt_ideas" > "$ideas_path" 2>>"$LOG"; then
  bytes=$(wc -c < "$ideas_path" | tr -d ' ')
  log "[5/10] done in $((SECONDS - t))s — $ideas_path ($bytes bytes)"
else
  log "[5/10] FAILED (claude exit $?) — see $LOG"
  exit 1
fi

# ── Phase 6: reels masivo (claude -p) ────────────────────────────────────
log "[6/10] generating reels masivo via claude -p (~1-2 min)..."
t=$SECONDS
prompt_reels="$(cat prompts/reels.md)"
reels_path="reels/$STAMP.md"
if cat "$TOP" | claude_cap -p "$prompt_reels" > "$reels_path" 2>>"$LOG"; then
  bytes=$(wc -c < "$reels_path" | tr -d ' ')
  log "[6/10] done in $((SECONDS - t))s — $reels_path ($bytes bytes)"
else
  log "[6/10] FAILED (claude exit $?) — see $LOG"
  exit 1
fi

fi  # end del skip de fases 4-6 (--pool-only)

# ── Phase 7: cards / Pool JSON (claude -p) ───────────────────────────────
# Ensancha el rank a top ~35 (cap 5/source) y corre cards.md sobre ese set.
# El Pool va a /tmp/ y de ahí lo publica la fase 10 al CDN (postaai-content → Vercel).
log "[7/10] generating Pool JSON (wider rank + claude -p cards.md, ~1-2 min)..."
t=$SECONDS

TOP_POOL="/tmp/digest-top-pool-$STAMP.json"
python3 ./scripts/rank-items.py "$ITEMS" --top 35 --max-per-source 5 > "$TOP_POOL" 2>>"$LOG"
top_pool_count="$(jq 'length' "$TOP_POOL")"
log "[7/10]   wider rank: $top_pool_count items (target 30-40)"

# Compute edition meta (placeholder-grade — Etapa 3 lo refina con locale es_AR).
HOUR="${STAMP##*-}"
DATE_ONLY="${STAMP%-*}"  # YYYY-MM-DD
NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [ "$HOUR" -lt 12 ]; then
  EDITION_LABEL="Edición de la mañana · 09:00"
  EDITION_OFFSET=1
  POOL_SLOT="morning"
else
  EDITION_LABEL="Edición de la tarde · 18:00"
  EDITION_OFFSET=2
  POOL_SLOT="evening"
fi
NUMBER="$(python3 -c "
from datetime import date
ref = date(2026, 1, 1)
now = date.fromisoformat('$DATE_ONLY')
print((now - ref).days * 2 + $EDITION_OFFSET)
")"

# Build the wrapper input {meta, items} that prompts/cards.md expects.
CARDS_INPUT="/tmp/digest-cards-input-$STAMP.json"
jq -n \
  --arg date "$DATE_ONLY" \
  --arg edition "$EDITION_LABEL" \
  --argjson number "$NUMBER" \
  --arg now "$NOW_ISO" \
  --slurpfile items "$TOP_POOL" \
  '{meta: {date: $date, edition: $edition, number: $number, now_iso: $now}, items: $items[0]}' \
  > "$CARDS_INPUT"

POOL_FILE="/tmp/digest-pool-$STAMP.json"
POOL_RAW="/tmp/digest-pool-raw-$STAMP.txt"
prompt_cards="$(cat prompts/cards.md)"

# claude -p a veces desobedece y envuelve el JSON en ```json…``` o le mete prosa, aunque el
# prompt pida "solo JSON". En un cron desatendido eso tira el drop. Blindaje: sanitizamos
# (extraemos del primer { al último }) y reintentamos una vez si el JSON sigue inválido.
pool_ok=0
for attempt in 1 2; do
  if ! cat "$CARDS_INPUT" | claude_cap -p "$prompt_cards" > "$POOL_RAW" 2>>"$LOG"; then
    log "[7/10] intento $attempt/2: claude falló — reintento"
    continue
  fi
  python3 - "$POOL_RAW" > "$POOL_FILE" <<'PY'
import sys
raw = open(sys.argv[1], encoding="utf-8").read()
i, j = raw.find("{"), raw.rfind("}")
sys.stdout.write(raw[i:j + 1] if i != -1 and j > i else raw)
PY
  # Válido = JSON parseable CON al menos MIN_CARDS cards. Un {"cards":[]} pasa `jq empty`
  # (sintaxis OK) pero es un drop vacío que no sirve publicar — lo tratamos como fallo y
  # reintentamos. MIN_CARDS configurable; default 3 (holgado vs los ~15-19 de un día sano).
  n_cards="$(jq -e '.cards | length' "$POOL_FILE" 2>>"$LOG" || echo -1)"
  if [ "$n_cards" -ge "${MIN_CARDS:-3}" ]; then
    pool_ok=1
    break
  fi
  log "[7/10] intento $attempt/2: Pool inválido o con pocas cards ($n_cards < ${MIN_CARDS:-3}) — reintento"
done

if (( ! pool_ok )); then
  log "[7/10] FAILED — Pool JSON inválido o vacío tras 2 intentos; ver $POOL_FILE y $LOG"
  exit 1
fi
cards_count="$(jq '.cards | length' "$POOL_FILE")"
bytes=$(wc -c < "$POOL_FILE" | tr -d ' ')
log "[7/10] done in $((SECONDS - t))s — $POOL_FILE ($cards_count cards, $bytes bytes)"

# ── Phase 8: email A (digest + ideas técnico) ────────────────────────────
if (( NO_EMAIL )); then
  log "[8/10] skipping email A (--no-email)"
else
  log "[8/10] sending email A (digest + ideas técnico)..."
  t=$SECONDS
  if ./scripts/send-email.py digest "$STAMP" 2>>"$LOG"; then
    log "[8/10] done in $((SECONDS - t))s — email A sent"
  else
    log "[8/10] WARN email A failed (continuing) — see $LOG"
  fi
fi

# ── Phase 9: email B (reels masivo) ──────────────────────────────────────
if (( NO_EMAIL )); then
  log "[9/10] skipping email B (--no-email)"
else
  log "[9/10] sending email B (reels masivo)..."
  t=$SECONDS
  if ./scripts/send-email.py reels "$STAMP" 2>>"$LOG"; then
    log "[9/10] done in $((SECONDS - t))s — email B sent"
  else
    log "[9/10] WARN email B failed (continuing) — see $LOG"
  fi
fi

# ── Phase 10: publish Pool al CDN (postaai-content repo → Vercel) ────────
if (( NO_PUBLISH )); then
  log "[10/10] skipping publish (--no-publish)"
else
  log "[10/10] publishing Pool to CDN repo (slot=$POOL_SLOT)..."
  t=$SECONDS
  # Pasamos SLOT derivado de la edición → archive y etiqueta salen de la misma fuente
  # (sino, en runs a horario raro, publish-pool podía inferir un slot distinto al label).
  if SLOT="$POOL_SLOT" ./scripts/publish-pool.sh "$POOL_FILE" 2>>"$LOG"; then
    log "[10/10] done in $((SECONDS - t))s — Pool pushed"
  else
    log "[10/10] WARN publish failed (continuing) — see $LOG"
  fi
fi

log "=== run-digest END total $((SECONDS - T0))s — $digest_path $ideas_path $reels_path $POOL_FILE ==="
