#!/usr/bin/env python3
"""
Enriquece items con summary flaco bajando el artículo real de la fuente.

Algunos feeds (ej. anthropic_research, anthropic_news) entregan SOLO el título, sin cuerpo
→ `summary` vacío → claude no tiene material y genera cards huecas ("el posteo no trae más
detalles..."). Esta fase baja la URL del item, le saca el texto, y lo usa como summary para que
la llamada de cards.md escriba una card con sustancia. NO resume con LLM: pasa el texto limpio
truncado y la propia llamada de cards.md lo condensa.

Se corre DESPUÉS del rank (sobre los ~35 items que van a cards), no sobre los 400 crudos.

Input:  argv[1] = items.json (array, salida de rank-items.py)
Output: stdout (mismo array; los items flacos enriquecidos traen summary nuevo + "_enriched": true)

Graceful por diseño: si un fetch falla (timeout, 403, muro JS, no-HTML, error), el item sale
con su summary original sin tocar. Nunca crashea la fase. Stdlib-only.

Flags:
  --min-summary N   solo enriquecer items con len(summary) < N (default 200)
  --max-chars N     truncar el texto extraído a N chars (default 2000)
  --timeout S       timeout por request en segundos (default 15)
  --workers N       fetches en paralelo (default 8)
"""
from __future__ import annotations

import argparse
import html
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from urllib.request import Request, urlopen

# ── strip HTML → texto (mismo enfoque que extract-items.py, + bloques de boilerplate) ──

_BLOCK_RE = re.compile(r"<(script|style|nav|header|footer|aside|form|svg)[^>]*>.*?</\1>",
                       re.S | re.I)
_TAG_RE = re.compile(r"<[^>]+>")
_WS_RE = re.compile(r"\s+")
_CTRL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")

# Señales de que bajamos un muro de bot / página que exige JS en vez del artículo real.
_WALL_RE = re.compile(
    r"enable javascript|are you human|verify you are|captcha|cf-browser-verification|"
    r"checking your browser|access denied|請啟用|robot check",
    re.I,
)

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def log(msg: str) -> None:
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] enrich-items: {msg}", file=sys.stderr)


def html_to_text(raw: str) -> str:
    raw = _BLOCK_RE.sub(" ", raw)
    txt = _TAG_RE.sub(" ", raw)
    txt = html.unescape(txt)
    txt = _WS_RE.sub(" ", txt).strip()
    return _CTRL_RE.sub("", txt)


def truncate(s: str, n: int) -> str:
    if len(s) <= n:
        return s
    cut = s[:n]
    sp = cut.rfind(" ")
    return (cut[:sp] if sp > n // 2 else cut) + "…"


def fetchable(url: str) -> bool:
    if not url or not url.lower().startswith(("http://", "https://")):
        return False
    # PDFs y binarios: no se pueden strip-ear a texto.
    return not url.lower().split("?")[0].endswith((".pdf", ".zip", ".png", ".jpg", ".mp4"))


def fetch_text(url: str, timeout: int, max_chars: int) -> str | None:
    """Baja la URL y devuelve texto limpio usable, o None si no se pudo."""
    try:
        req = Request(url, headers={"User-Agent": UA, "Accept": "text/html,*/*"})
        with urlopen(req, timeout=timeout) as resp:
            ctype = resp.headers.get("Content-Type", "")
            if "html" not in ctype and "xml" not in ctype and ctype:
                return None  # no-HTML (pdf, json, imagen): no sirve
            raw = resp.read(2_000_000).decode("utf-8", errors="ignore")
    except Exception:
        return None
    txt = html_to_text(raw)
    # Muy corto o muro de bot → no usable.
    if len(txt) < 200 or _WALL_RE.search(txt[:600]):
        return None
    return truncate(txt, max_chars)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("items_json")
    ap.add_argument("--min-summary", type=int, default=200)
    ap.add_argument("--max-chars", type=int, default=2000)
    ap.add_argument("--timeout", type=int, default=15)
    ap.add_argument("--workers", type=int, default=8)
    args = ap.parse_args()

    with open(args.items_json) as f:
        items: list[dict] = json.load(f)

    # Candidatos: summary flaco + URL bajable.
    targets = [
        it for it in items
        if len((it.get("summary") or "").strip()) < args.min_summary
        and fetchable(it.get("url", ""))
    ]
    log(f"{len(items)} items, {len(targets)} candidatos a enriquecer (summary < {args.min_summary} chars)")

    if targets:
        def work(it: dict) -> tuple[dict, str | None]:
            return it, fetch_text(it["url"], args.timeout, args.max_chars)

        enriched = 0
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            for it, text in ex.map(work, targets):
                if text:
                    it["summary"] = text
                    it["_enriched"] = True
                    enriched += 1
        log(f"enriquecidos: {enriched}/{len(targets)} (el resto se dejó sin tocar)")

    json.dump(items, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
