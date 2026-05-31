#!/usr/bin/env bash
# Fase 10 del pipeline: publica el Pool generado al repo postaai-content.
#
# Uso: ./publish-pool.sh <POOL_FILE>
#
# Asume:
#   - Un clone/checkout de postaai-content con remote 'origin' válido y permisos de push.
#     Local (Mac): ~/postaai-content. En CI: lo pasa el workflow vía $CONTENT_REPO.
#   - Slot inferido del horario local (hora < 14 = morning, else evening). En CI el workflow
#     corre con TZ=America/Argentina/Buenos_Aires, así que `date` da hora ART (09/18) y la
#     inferencia coincide con la Mac. Se puede forzar con $SLOT (morning|evening) si hace falta.

set -euo pipefail

# CONTENT_REPO override por env (CI lo apunta al checkout del workspace); default Mac local.
CONTENT_REPO="${CONTENT_REPO:-$HOME/postaai-content}"
POOL_FILE="${1:-}"

if [ -z "$POOL_FILE" ]; then
  echo "publish-pool: ERROR — falta arg POOL_FILE" >&2
  exit 2
fi
if [ ! -f "$POOL_FILE" ]; then
  echo "publish-pool: ERROR — POOL_FILE no existe: $POOL_FILE" >&2
  exit 2
fi
if [ ! -d "$CONTENT_REPO/.git" ]; then
  echo "publish-pool: ERROR — clone esperado en $CONTENT_REPO no encontrado (¿hiciste git clone?)" >&2
  exit 2
fi

# Slot e ISO date. $SLOT se puede forzar por env; si no, se infiere de la hora local.
DATE="$(date +%Y-%m-%d)"
if [ -z "${SLOT:-}" ]; then
  HOUR="$(date +%H)"
  if [ "$HOUR" -lt 14 ]; then
    SLOT="morning"
  else
    SLOT="evening"
  fi
fi
NOW_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "publish-pool: $DATE/$SLOT (UTC $NOW_UTC) ← $POOL_FILE" >&2

mkdir -p "$CONTENT_REPO/archive"
cp "$POOL_FILE" "$CONTENT_REPO/latest.json"
cp "$POOL_FILE" "$CONTENT_REPO/archive/$DATE-$SLOT.json"

cd "$CONTENT_REPO"

# Pull primero por si Bauti tocó algo desde otro lugar (kill-switch desde el celu, edit web).
git pull --rebase --autostash >&2

git add latest.json "archive/$DATE-$SLOT.json"

# Si no hay cambios (Pool idéntico al anterior, raro pero posible), no committeamos.
if git diff --cached --quiet; then
  echo "publish-pool: sin cambios respecto al último Pool, skip commit" >&2
  exit 0
fi

git commit -m "$DATE $SLOT ($NOW_UTC)" >&2
git push >&2

echo "publish-pool: pushed OK" >&2
