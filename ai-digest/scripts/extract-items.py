#!/usr/bin/env python3
"""
Parse the raw fetch output into a clean JSON array of items.

Input:  argv[1] = /tmp/digest-raw-<STAMP>.json (from fetch-sources.sh)
Output: stdout (clean JSON array)

Each output item:
  {
    "source": "openai",
    "title": "...",
    "url": "...",
    "summary": "first ~400 chars, HTML-stripped",
    "published_at": "ISO8601 UTC" or null,
    "engagement": {"score": int, "comments": int} or null,
    "subreddit": "..." or null
  }

Stdlib-only. Designed to keep ALL items at this stage (no filtering by score);
ranking + cutoff happens in rank-items.py.
"""
from __future__ import annotations

import base64
import html
import json
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime

# ── helpers ───────────────────────────────────────────────────────────────

_TAG_RE = re.compile(r"<[^>]+>")
_WS_RE = re.compile(r"\s+")
# C0 control characters except \t (\x09) and \n (\x0a) — they break json.dump
_CTRL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
ATOM_NS = "{http://www.w3.org/2005/Atom}"
MAX_ITEMS_PER_SOURCE = 30  # most recent N per feed; rank-items will trim more


def clean(s: str | None) -> str:
    """Drop C0 control chars that break JSON encoding."""
    if not s:
        return ""
    return _CTRL_RE.sub("", s)


def strip_html(s: str | None) -> str:
    if not s:
        return ""
    s = _TAG_RE.sub(" ", s)
    s = html.unescape(s)
    s = _WS_RE.sub(" ", s).strip()
    return clean(s)


def truncate(s: str, n: int = 400) -> str:
    if len(s) <= n:
        return s
    cut = s[:n]
    # Try not to cut mid-word
    sp = cut.rfind(" ")
    return (cut[:sp] if sp > 200 else cut) + "…"


def parse_date(s: str | None) -> str | None:
    if not s:
        return None
    s = s.strip()
    # Try RFC 2822 (most RSS uses this)
    try:
        dt = parsedate_to_datetime(s)
        if dt is not None:
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt.astimezone(timezone.utc).isoformat()
    except (TypeError, ValueError):
        pass
    # Try ISO 8601 (Atom uses this)
    try:
        s_iso = s.replace("Z", "+00:00")
        dt = datetime.fromisoformat(s_iso)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc).isoformat()
    except ValueError:
        pass
    return None


def log(msg: str) -> None:
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] extract-items: {msg}", file=sys.stderr)


# ── parsers ───────────────────────────────────────────────────────────────


def parse_rss(source: str, body: bytes) -> list[dict]:
    items: list[dict] = []
    try:
        root = ET.fromstring(body)
    except ET.ParseError as e:
        log(f"  {source}: XML parse error {e}")
        return items

    ns = {
        "content": "http://purl.org/rss/1.0/modules/content/",
        "dc": "http://purl.org/dc/elements/1.1/",
    }

    # RSS 2.0
    for item in root.iter("item"):
        title = (item.findtext("title") or "").strip()
        link = (item.findtext("link") or "").strip()
        if not title or not link:
            continue
        pubdate = item.findtext("pubDate") or item.findtext("dc:date", namespaces=ns)
        desc = item.findtext("content:encoded", namespaces=ns) or item.findtext("description") or ""
        items.append({
            "source": source,
            "title": strip_html(title),
            "url": clean(link),
            "summary": truncate(strip_html(desc)),
            "published_at": parse_date(pubdate),
            "engagement": None,
            "subreddit": None,
        })

    # Atom
    for entry in root.iter(f"{ATOM_NS}entry"):
        title = (entry.findtext(f"{ATOM_NS}title") or "").strip()
        link_el = entry.find(f"{ATOM_NS}link")
        link = link_el.get("href") if link_el is not None else ""
        if not title or not link:
            continue
        pubdate = entry.findtext(f"{ATOM_NS}published") or entry.findtext(f"{ATOM_NS}updated")
        desc = (
            entry.findtext(f"{ATOM_NS}summary")
            or entry.findtext(f"{ATOM_NS}content")
            or ""
        )
        items.append({
            "source": source,
            "title": strip_html(title),
            "url": clean(link),
            "summary": truncate(strip_html(desc)),
            "published_at": parse_date(pubdate),
            "engagement": None,
            "subreddit": None,
        })

    # Cap at most recent N items. Items with no date go to the end (treated oldest).
    def _key(it: dict) -> str:
        return it["published_at"] or "0"
    items.sort(key=_key, reverse=True)
    return items[:MAX_ITEMS_PER_SOURCE]


def parse_hn_algolia(source: str, body: bytes) -> list[dict]:
    out: list[dict] = []
    try:
        data = json.loads(body)
    except Exception as e:
        log(f"  {source}: JSON parse error {e}")
        return out
    for hit in data.get("hits", []):
        title = hit.get("title") or hit.get("story_title") or ""
        url = (
            hit.get("url")
            or hit.get("story_url")
            or f"https://news.ycombinator.com/item?id={hit.get('objectID')}"
        )
        if not title:
            continue
        out.append({
            "source": source,
            "title": clean(title),
            "url": clean(url),
            "summary": "",
            "published_at": parse_date(hit.get("created_at")),
            "engagement": {
                "score": int(hit.get("points") or 0),
                "comments": int(hit.get("num_comments") or 0),
            },
            "subreddit": None,
        })
    return out[:MAX_ITEMS_PER_SOURCE]


def parse_reddit_json(source: str, body: bytes) -> list[dict]:
    out: list[dict] = []
    try:
        data = json.loads(body)
    except Exception as e:
        log(f"  {source}: JSON parse error {e}")
        return out
    for child in data.get("data", {}).get("children", []):
        d = child.get("data", {})
        title = d.get("title", "")
        if not title:
            continue
        permalink = d.get("permalink", "")
        url = (
            d.get("url_overridden_by_dest")
            or d.get("url")
            or (f"https://www.reddit.com{permalink}" if permalink else "")
        )
        created = d.get("created_utc")
        published = (
            datetime.fromtimestamp(created, tz=timezone.utc).isoformat()
            if created
            else None
        )
        out.append({
            "source": source,
            "title": clean(title),
            "url": clean(url),
            "summary": truncate(clean(d.get("selftext", "") or "")),
            "published_at": published,
            "engagement": {
                "score": int(d.get("score") or 0),
                "comments": int(d.get("num_comments") or 0),
            },
            "subreddit": d.get("subreddit"),
        })
    return out[:MAX_ITEMS_PER_SOURCE]


def parse_webfetch(source: str, body: bytes) -> list[dict]:
    # Placeholder — webfetch sources (like Mistral) are skipped in this pipeline.
    # Could be implemented later by passing to claude as a separate stdin step.
    return []


PARSERS = {
    "rss": parse_rss,
    "hn_algolia": parse_hn_algolia,
    "reddit_json": parse_reddit_json,
    "webfetch": parse_webfetch,
}


# ── main ──────────────────────────────────────────────────────────────────


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: extract-items.py <raw.json>", file=sys.stderr)
        return 2

    raw_path = sys.argv[1]
    log(f"loading {raw_path}")
    with open(raw_path) as f:
        raw = json.load(f)

    log(f"parsing {len(raw)} sources")
    all_items: list[dict] = []
    stats: dict[str, int] = {}

    for entry in raw:
        source = entry["source"]
        type_ = entry["type"]
        status = entry.get("status", 0)
        if status != 200:
            log(f"  skip {source}: HTTP {status}")
            stats[source] = 0
            continue
        body_b64 = entry.get("body_b64", "")
        if not body_b64:
            stats[source] = 0
            continue
        try:
            body = base64.b64decode(body_b64)
        except Exception as e:
            log(f"  {source}: b64 decode error {e}")
            stats[source] = 0
            continue
        parser = PARSERS.get(type_)
        if not parser:
            log(f"  {source}: unknown type {type_}")
            stats[source] = 0
            continue
        items = parser(source, body)
        stats[source] = len(items)
        all_items.extend(items)

    log(f"total items: {len(all_items)}")
    log(f"per source: {json.dumps(stats)}")

    json.dump(all_items, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
