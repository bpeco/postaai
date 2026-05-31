# ai-digest

Pipeline diaria que junta noticias AI de 21 fuentes y genera **3 outputs** + **2 emails HTML** en rioplatense. Corre 2x al día (09:00 y 18:00) vía **launchd** nativo de macOS.

**Outputs por run:**
- `digests/STAMP.md` — resumen del día (15 noticias, TL;DR, take editorial)
- `ideas/STAMP.md` — 8 ideas de Shorts **técnicas** (para audiencia dev/AI)
- `reels/STAMP.md` — 10 ideas de Reels **masivas** (para acercar AI a no-devs, con TED-talk + opinión)

**Emails por run:**
- **Email A** (`AI digest STAMP`) — digest + ideas técnicas (modo "me pongo al día")
- **Email B** (`Reels ideas STAMP`) — reels masivos (modo "hoy produzco contenido")

Ambos llegan renderizados en HTML, no markdown crudo.

## Cómo correr

```bash
cd /Users/Bauti/XP-SAM/ai-digest
./scripts/run-digest.sh
```

Progreso en vivo (8 fases):

```
[12:00:00] === run-digest START stamp=2026-05-11-12 dry_run=0 no_email=0 ===
[12:00:00] [1/8] fetching sources from sources.json...
[12:00:03] [1/8] done in 3s — 21/21 sources OK
[12:00:03] [2/8] parsing items (extract-items.py)...
[12:00:04] [2/8] done in 1s — 445 items extracted
[12:00:04] [3/8] ranking + dedup (rank-items.py)...
[12:00:04] [3/8] done in 0s — top 15 selected
[12:00:04] [4/8] generating digest via claude -p (~1-2 min)...
[12:01:02] [4/8] done in 58s — digests/STAMP.md
[12:01:02] [5/8] generating ideas técnico via claude -p (~1-2 min)...
[12:03:02] [5/8] done in 120s — ideas/STAMP.md
[12:03:02] [6/8] generating reels masivo via claude -p (~1-2 min)...
[12:05:27] [6/8] done in 145s — reels/STAMP.md
[12:05:27] [7/8] sending email A (digest + ideas técnico)...
[12:05:31] [7/8] done in 4s — email A sent
[12:05:31] [8/8] sending email B (reels masivo)...
[12:05:35] [8/8] done in 4s — email B sent
[12:05:35] === run-digest END total 335s ===
```

Tiempo total típico: **~5-6 minutos**.

### Flags

```bash
./scripts/run-digest.sh --dry-run     # solo phases 1-3 (sin claude, sin email) — ~5s
./scripts/run-digest.sh --no-email    # phases 1-6 (sin enviar emails) — ~5min
```

## Schedule automático (launchd)

Cargado en `~/Library/LaunchAgents/com.bauti.ai-digest.plist`. Corre a las **9:00 y 18:00**.

```bash
launchctl list | grep ai-digest                                     # ver status
launchctl unload ~/Library/LaunchAgents/com.bauti.ai-digest.plist   # pausar
launchctl load   ~/Library/LaunchAgents/com.bauti.ai-digest.plist   # reactivar
launchctl start  com.bauti.ai-digest                                # disparar ahora
```

Para cambiar horarios: editá el plist + `unload` + `load`.

## Dependencias

Ya instaladas:
- `jq`, `curl`, `python3`, `base64` (built-in / anaconda)
- `claude` CLI (Claude Code, vía Max OAuth)
- `msmtp` (Gmail SMTP — config en `~/.msmtprc` con App Password)
- **`pandoc`** (markdown → HTML para los emails) — instalado con `brew install pandoc`

## Arquitectura (pipeline de 8 fases)

```
run-digest.sh  ← entry point
   │
   ├─[1] fetch-sources.sh      → /tmp/digest-raw-STAMP.json    (~8MB, 21 fuentes paralelo)
   │
   ├─[2] extract-items.py      → /tmp/digest-items-STAMP.json  (~230KB, schema unificado)
   │     parsea RSS/Atom/HN/Reddit, decode base64, strip HTML
   │
   ├─[3] rank-items.py         → /tmp/digest-top-STAMP.json    (~5KB, top 15)
   │     dedup (URL + Jaccard 0.85), score, cap 3 por fuente
   │
   ├─[4] claude -p (digest)    → digests/STAMP.md   (~8KB)
   │     prompt: prompts/digest.md
   │
   ├─[5] claude -p (ideas téc) → ideas/STAMP.md     (~10KB)
   │     prompt: prompts/ideas.md  — 8 ideas para devs/AI insiders
   │
   ├─[6] claude -p (reels mas) → reels/STAMP.md     (~17KB)
   │     prompt: prompts/reels.md  — 10 ideas para gente no-tech, TED-talk + take
   │
   ├─[7] send-email.py digest  → Email A (digest + ideas técnico)
   │
   └─[8] send-email.py reels   → Email B (reels masivo)
```

**Por qué funciona en `claude -p`:** las 3 invocaciones a Claude son **stdin + prompt string**, **cero tool calls** → cero permission prompts. Claude solo trabaja sobre ~5KB de items curados.

## Estructura de archivos

```
ai-digest/
├── README.md
├── sources.json                  # 21 fuentes — editá libremente
├── scripts/
│   ├── run-digest.sh             # orchestrator (entry point)
│   ├── fetch-sources.sh          # curl paralelo
│   ├── extract-items.py          # parser RSS/JSON → schema unificado
│   ├── rank-items.py             # dedup + scoring + top 15
│   └── send-email.py             # multipart HTML email (pandoc + msmtp)
├── prompts/
│   ├── digest.md                 # phase 4 (resumen del día)
│   ├── ideas.md                  # phase 5 (8 ideas técnicas)
│   └── reels.md                  # phase 6 (10 ideas masivas)
├── digests/                      # YYYY-MM-DD-HH.md
├── ideas/                        # YYYY-MM-DD-HH.md
└── reels/                        # YYYY-MM-DD-HH.md
```

Fuera del repo:
- `~/.msmtprc` (config msmtp con App Password de Gmail)
- `~/Library/LaunchAgents/com.bauti.ai-digest.plist` (schedule)

## Editar las fuentes

`sources.json` tiene 21 fuentes pre-validadas. Para sumar/sacar:

```json
{
  "name": "nombre_interno",
  "type": "rss",                         // rss | hn_algolia | reddit_json | webfetch
  "url": "https://..."
}
```

Tipos soportados:
- `rss` — feed RSS 2.0 o Atom (extract-items.py parsea ambos)
- `hn_algolia` — endpoint de la HN Algolia API
- `reddit_json` — `https://www.reddit.com/r/X/top.json?...` (rate limit: 10 req/min sin auth)
- `webfetch` — placeholder, requiere implementación manual

Pesos de ranking (en `scripts/rank-items.py`):
- **3.0** — frontier labs (anthropic_*, openai, deepmind, google_ai, meta_ai, mistral_*)
- **2.5** — newsletters curadas (tldr_ai, latent_space, the_rundown, last_week_in_ai, the_batch)
- **2.0** — domain-specific (arxiv_ai, import_ai, bens_bites, anthropic_claude_code_changelog)
- **1.5** — hn_ai
- **1.0** — reddit_*

Si agregás una fuente nueva, sumala al dict `SOURCE_WEIGHTS` con su peso.

## Editar los prompts

Los 3 prompts viven en `prompts/`:

| Archivo | Salida | Audiencia | Cantidad |
|---|---|---|---|
| `digest.md` | `digests/STAMP.md` | tu, para mantenerte al día | 15 noticias + TL;DR |
| `ideas.md` | `ideas/STAMP.md` | Shorts/Reels para devs/AI insiders | 8 ideas (3 noticia + 3 explainer + 2 hot take) |
| `reels.md` | `reels/STAMP.md` | Reels para gente NO técnica | 10 ideas (mix te-cambia-el-día / mythbusting / explainer / futuro / cuidado) |

Cambios surten efecto en el próximo run. No necesitás tocar código.

## Debugging

**Log del último run:** `/tmp/ai-digest-<STAMP>.log` (un archivo por hora).

```bash
ls -t /tmp/ai-digest-*.log | head -1 | xargs cat                  # último log

cat /tmp/ai-digest-launchd.out                                    # logs launchd
cat /tmp/ai-digest-launchd.err
```

**Si falla una fase específica:**

```bash
# phase 1
./scripts/fetch-sources.sh > /tmp/test.json
jq -r '.[] | "\(.status)\t\(.source)"' /tmp/test.json | sort

# phase 2
python3 scripts/extract-items.py /tmp/test.json > /tmp/items.json
jq 'group_by(.source) | .[] | "\(length)\t\(.[0].source)"' /tmp/items.json

# phase 3
python3 scripts/rank-items.py /tmp/items.json > /tmp/top.json
jq -r '.[] | "\(.source)\t\(.title[:80])"' /tmp/top.json

# phase 4 / 5 / 6 aislada con un STAMP existente
cat /tmp/digest-top-STAMP.json | claude -p "$(cat prompts/digest.md)" > /tmp/test-digest.md
cat /tmp/digest-top-STAMP.json | claude -p "$(cat prompts/ideas.md)"  > /tmp/test-ideas.md
cat /tmp/digest-top-STAMP.json | claude -p "$(cat prompts/reels.md)"  > /tmp/test-reels.md

# phase 7 / 8 — reenviar emails de un STAMP existente
./scripts/send-email.py digest 2026-05-11-09
./scripts/send-email.py reels  2026-05-11-09
```

**Email no llega:**

```bash
tail ~/.msmtp.log                                                  # ¿errores SMTP?
echo "Subject: test" | msmtp -a gmail bautista.peco.97@gmail.com   # smoke aislado
```

Si Gmail rechaza la App Password (`535 5.7.8 Authentication failed`), regenerá la password en https://myaccount.google.com/apppasswords y actualizá `~/.msmtprc`.

**Email llega pero se ve mal:** verificar pandoc:

```bash
pandoc --version | head -1                # debe ser 3.x
echo "# test\n\n- bullet" | pandoc -f markdown -t html5
```

## Costo

Cada run consume ~5-6 minutos con 3 llamadas a `claude -p` (digest + ideas + reels). En cuota Max es trivial — 6 invocaciones/día, sobra holgado.

## Referencias

- Claude Code headless mode: <https://code.claude.com/docs/en/headless>
- launchd (StartCalendarInterval): `man launchd.plist`
- Pandoc: <https://pandoc.org/>
- RSS feeds comunitarios usados para Anthropic/Meta/The Batch: <https://github.com/Olshansk/rss-feeds>
