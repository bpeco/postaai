#!/usr/bin/env python3
"""
Dedupe + rank items emitted by extract-items.py and select the top N.

Input:  argv[1] = items.json (extract-items output)
Output: stdout (JSON array of top items, default top 15)

Flags:
  --top N               cap output to N items (default 15)
  --max-age HOURS       filter items older than HOURS (default 48)
  --max-per-source N    cap items per source in final selection (default 3)

Scoring:
  score = source_weight * recency_factor + engagement_boost

Dedup:
  - same URL (normalized: lower, strip trailing /, strip ?utm_* params)
  - OR title Jaccard similarity >= 0.85 (lowercase, stopword-free)
  → keep the one with higher source_weight, then higher score

Stdlib only.
"""
from __future__ import annotations

import argparse
import json
import math
import re
import sys
from datetime import datetime, timezone, timedelta
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode

# ── source weights (matches plan) ────────────────────────────────────────

SOURCE_WEIGHTS: dict[str, float] = {
    # tier 3 — frontier labs
    "anthropic_news": 3.0,
    "anthropic_engineering": 3.0,
    "anthropic_research": 3.0,
    "openai": 3.0,
    "deepmind": 3.0,
    "google_ai": 3.0,
    "meta_ai": 3.0,
    "mistral_news": 3.0,
    # tier 2.5 — curated newsletters
    "tldr_ai": 2.5,
    "latent_space": 2.5,
    "the_rundown": 2.5,
    "last_week_in_ai": 2.5,
    "the_batch": 2.5,
    # tier 2 — domain-specific
    "arxiv_ai": 2.0,
    "import_ai": 2.0,
    "bens_bites": 2.0,
    "anthropic_claude_code_changelog": 2.0,
    # tier 1.5 — community / aggregators
    "hn_ai": 1.5,
    # tier 1 — raw social
    "reddit_localllama": 1.0,
    "reddit_singularity": 1.0,
    "reddit_machinelearning": 1.0,
}
DEFAULT_WEIGHT = 1.0


# ── helpers ──────────────────────────────────────────────────────────────


def log(msg: str) -> None:
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] rank-items: {msg}", file=sys.stderr)


def source_weight(source: str) -> float:
    return SOURCE_WEIGHTS.get(source, DEFAULT_WEIGHT)


def normalize_url(u: str) -> str:
    """Normalize URLs to dedupe near-equivalents."""
    if not u:
        return ""
    try:
        s = urlsplit(u.strip().lower())
    except ValueError:
        return u.strip().lower()
    # strip tracking params
    keep = [(k, v) for k, v in parse_qsl(s.query, keep_blank_values=False)
            if not k.startswith("utm_") and k not in {"ref", "ref_src", "source"}]
    new_q = urlencode(keep)
    path = s.path.rstrip("/")
    return urlunsplit((s.scheme, s.netloc, path, new_q, ""))


_TOKEN_RE = re.compile(r"[a-záéíóúñü0-9]+")
STOPWORDS_ES = {
    "el","la","los","las","un","una","unos","unas","de","del","al","a","y","o","u",
    "que","con","en","por","para","sobre","entre","sin","como","es","son","fue","ser",
    "se","lo","le","les","si","no","más","menos","ya","muy","mucho","poco",
}
STOPWORDS_EN = {
    "the","a","an","of","to","in","on","for","with","and","or","is","are","was","were",
    "be","been","by","at","as","it","this","that","these","those","from","but","not",
}
STOPWORDS = STOPWORDS_ES | STOPWORDS_EN


def title_tokens(t: str) -> set[str]:
    return {w for w in _TOKEN_RE.findall(t.lower()) if w not in STOPWORDS and len(w) > 2}


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    inter = len(a & b)
    union = len(a | b)
    return inter / union if union else 0.0


def parse_iso(s: str | None) -> datetime | None:
    if not s:
        return None
    try:
        return datetime.fromisoformat(s)
    except ValueError:
        return None


def recency_factor(dt: datetime | None, now: datetime) -> float:
    if dt is None:
        return 0.2
    age_h = (now - dt).total_seconds() / 3600.0
    if age_h < 0:
        return 1.0  # future-dated, treat as fresh
    if age_h < 12:
        return 1.0
    if age_h < 24:
        return 0.7
    if age_h < 48:
        return 0.4
    return 0.1


def engagement_boost(eng: dict | None) -> float:
    if not eng:
        return 0.0
    score = eng.get("score", 0)
    if score <= 0:
        return 0.0
    return min(0.5, math.log10(score + 1) / 10.0)


def score_item(item: dict, now: datetime) -> float:
    w = source_weight(item["source"])
    r = recency_factor(parse_iso(item.get("published_at")), now)
    e = engagement_boost(item.get("engagement"))
    return w * r + e


# ── main ─────────────────────────────────────────────────────────────────


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("items_json")
    ap.add_argument("--top", type=int, default=15)
    ap.add_argument("--max-age", type=int, default=48, help="hours")
    ap.add_argument("--max-per-source", type=int, default=3,
                    help="cap items per source in final selection")
    args = ap.parse_args()

    with open(args.items_json) as f:
        items: list[dict] = json.load(f)
    log(f"loaded {len(items)} items")

    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(hours=args.max_age)

    # Filter by recency (items with no date pass through — many news items lack dates)
    fresh: list[dict] = []
    for it in items:
        dt = parse_iso(it.get("published_at"))
        if dt is None or dt >= cutoff:
            fresh.append(it)
    log(f"after {args.max_age}h cutoff: {len(fresh)}")

    # Score each item
    for it in fresh:
        it["_score"] = score_item(it, now)
        it["_weight"] = source_weight(it["source"])

    # Sort descending by score for dedup pass (we keep the higher-scored item)
    fresh.sort(key=lambda it: (it["_score"], it["_weight"]), reverse=True)

    # Dedup
    deduped: list[dict] = []
    seen_urls: set[str] = set()
    seen_token_sets: list[set[str]] = []
    for it in fresh:
        nurl = normalize_url(it.get("url", ""))
        if nurl and nurl in seen_urls:
            continue
        toks = title_tokens(it.get("title", ""))
        if any(jaccard(toks, ts) >= 0.85 for ts in seen_token_sets):
            continue
        deduped.append(it)
        if nurl:
            seen_urls.add(nurl)
        if toks:
            seen_token_sets.append(toks)
    log(f"after dedup: {len(deduped)}")

    # Per-source quota for diversity — at most max_per_source in the final list
    max_per_source = args.max_per_source
    top: list[dict] = []
    per_source: dict[str, int] = {}
    for it in deduped:
        src = it["source"]
        if per_source.get(src, 0) >= max_per_source:
            continue
        top.append(it)
        per_source[src] = per_source.get(src, 0) + 1
        if len(top) >= args.top:
            break
    log(f"selected top {len(top)} (cap {max_per_source} per source)")

    # Strip internal score fields before emitting
    for it in top:
        it.pop("_score", None)
        it.pop("_weight", None)

    json.dump(top, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
