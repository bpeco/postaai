#!/usr/bin/env bash
# Fase 10 del pipeline: publica el Pool generado al repo postaai-content.
#
# Uso: ./publish-pool.sh <POOL_FILE>
#
# Asume:
#   - Clone local en ~/postaai-content con remote 'origin' válido y permisos de push.
#   - Slot inferido del horario (hora local < 14 = morning, else evening) — Etapa 5
#     reemplaza esto con env vars del cron de GH Actions.

set -euo pipefail

CONTENT_REPO="$HOME/postaai-content"
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

# Slot e ISO date
HOUR="$(date +%H)"
DATE="$(date +%Y-%m-%d)"
if [ "$HOUR" -lt 14 ]; then
  SLOT="morning"
else
  SLOT="evening"
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
