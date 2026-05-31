#!/usr/bin/env bash
# Fetch every source in sources.json in parallel and emit a single JSON array to stdout.
# Each record: {source, type, url, status, body_b64}.
# The body is base64-encoded so it survives JSON embedding regardless of content (RSS XML, etc.).
#
# Dependencies: curl, jq, base64 (all macOS-builtin / standard).
#
# Usage:
#   ./fetch-sources.sh                       # writes JSON to stdout
#   ./fetch-sources.sh > /tmp/digest-raw.json

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCES="$DIR/sources.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 ai-digest/1.0 (claude-code daily digest; contact bautista.peco.97@gmail.com)"
TIMEOUT=30
MAX_PARALLEL=10

fetch_one() {
  local name="$1" type="$2" url="$3"
  local body_file="$TMP/$name.body"
  local meta_file="$TMP/$name.meta"
  local status

  status="$(curl -sS -L -A "$UA" --max-time "$TIMEOUT" \
    -o "$body_file" -w '%{http_code}' "$url" 2>/dev/null || echo "000")"

  local b64_file="$TMP/$name.b64"
  if [[ -f "$body_file" ]]; then
    base64 < "$body_file" | tr -d '\n' > "$b64_file"
  else
    : > "$b64_file"
  fi

  # Use --rawfile to avoid "Argument list too long" for large feed bodies.
  jq -nc \
    --arg source "$name" \
    --arg type "$type" \
    --arg url "$url" \
    --argjson status "${status:-0}" \
    --rawfile body_b64 "$b64_file" \
    '{source:$source, type:$type, url:$url, status:$status, body_b64:$body_b64}' \
    > "$meta_file"
}

# Spawn one background job per source, throttled at MAX_PARALLEL.
pids=()
while IFS=$'\t' read -r name type url; do
  # Throttle: wait if too many running
  while (( $(jobs -rp | wc -l) >= MAX_PARALLEL )); do
    sleep 0.05
  done
  fetch_one "$name" "$type" "$url" &
  pids+=($!)
done < <(jq -r '.sources[] | [.name, .type, .url] | @tsv' "$SOURCES")

# Wait for all to finish
for pid in "${pids[@]}"; do
  wait "$pid" 2>/dev/null || true
done

# Combine into single JSON array
cat "$TMP"/*.meta | jq -s '.'
