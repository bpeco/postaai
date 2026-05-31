#!/usr/bin/env python3
"""
Send a daily digest email as multipart/alternative (text/plain + text/html).

Usage:
  ./send-email.py digest <STAMP>    # sends digests/STAMP.md + ideas/STAMP.md (Email A)
  ./send-email.py reels  <STAMP>    # sends reels/STAMP.md                    (Email B)

Renders markdown → HTML via pandoc. Pipes the MIME message to msmtp.
Stdlib only beyond pandoc + msmtp (already required by the project).
"""
from __future__ import annotations

import os
import subprocess
import sys
from datetime import datetime
from email.message import EmailMessage
from pathlib import Path

DIR = Path(__file__).resolve().parent.parent
TO = "bautista.peco.97@gmail.com"
FROM = "bautista.peco.97@gmail.com"

# Inline CSS — keeps the email readable in Gmail's HTML view without external deps.
HTML_HEAD = """\
<style>
body { font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif;
       max-width: 720px; margin: 0 auto; padding: 16px; color: #1f1f1f; line-height: 1.55; }
h1 { font-size: 22px; border-bottom: 2px solid #e5e5e5; padding-bottom: 8px; margin-top: 24px; }
h2 { font-size: 18px; margin-top: 28px; color: #1a1a1a; }
h3 { font-size: 16px; margin-top: 20px; color: #2a2a2a; }
p, li { font-size: 15px; }
a { color: #1a73e8; text-decoration: none; }
a:hover { text-decoration: underline; }
ul { padding-left: 22px; }
li { margin: 4px 0; }
code { background: #f5f5f5; padding: 1px 5px; border-radius: 3px; font-size: 14px; }
blockquote { border-left: 3px solid #e5e5e5; padding-left: 12px; color: #555; margin-left: 0; }
hr { border: 0; border-top: 1px solid #e5e5e5; margin: 24px 0; }
.footer { color: #888; font-size: 12px; margin-top: 32px; }
</style>
"""


def log(msg: str) -> None:
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] send-email: {msg}", file=sys.stderr)


def must_exist(p: Path) -> Path:
    if not p.is_file():
        sys.exit(f"send-email: missing file {p}")
    return p


def md_to_html(markdown: str) -> str:
    """Convert markdown to HTML via pandoc, returning the inner body content."""
    try:
        result = subprocess.run(
            ["pandoc", "-f", "markdown", "-t", "html5"],
            input=markdown,
            capture_output=True,
            text=True,
            check=True,
        )
    except FileNotFoundError:
        sys.exit("send-email: pandoc not installed. Run: brew install pandoc")
    except subprocess.CalledProcessError as e:
        sys.exit(f"send-email: pandoc failed: {e.stderr}")
    return result.stdout


def build_html(body_html: str, title: str) -> str:
    return f"""<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>{title}</title>
{HTML_HEAD}
</head><body>
{body_html}
<div class="footer">Generado automáticamente · ai-digest · {datetime.now().strftime("%Y-%m-%d %H:%M")}</div>
</body></html>
"""


def assemble(mode: str, stamp: str) -> tuple[str, str, str]:
    """Return (subject, plain_text, html) for the given mode."""
    if mode == "digest":
        digest_md = must_exist(DIR / "digests" / f"{stamp}.md").read_text()
        ideas_md = must_exist(DIR / "ideas" / f"{stamp}.md").read_text()
        subject = f"AI digest {stamp}"
        markdown = (
            f"{digest_md}\n\n"
            f"---\n\n"
            f"# Ideas técnicas para Shorts/Reels\n\n"
            f"{ideas_md}\n"
        )
    elif mode == "reels":
        reels_md = must_exist(DIR / "reels" / f"{stamp}.md").read_text()
        subject = f"Reels ideas {stamp}"
        markdown = f"# Reels — deck masivo ({stamp})\n\n{reels_md}\n"
    else:
        sys.exit(f"send-email: unknown mode '{mode}'. Use 'digest' or 'reels'.")
    html_body = md_to_html(markdown)
    html_full = build_html(html_body, subject)
    return subject, markdown, html_full


def send(subject: str, plain: str, html: str) -> None:
    msg = EmailMessage()
    msg["From"] = FROM
    msg["To"] = TO
    msg["Subject"] = subject
    msg.set_content(plain)               # text/plain fallback
    msg.add_alternative(html, subtype="html")  # text/html preferred

    raw = msg.as_bytes()

    try:
        subprocess.run(
            ["msmtp", "-a", "gmail", TO],
            input=raw,
            check=True,
        )
    except FileNotFoundError:
        sys.exit("send-email: msmtp not installed. Run: brew install msmtp")
    except subprocess.CalledProcessError as e:
        sys.exit(f"send-email: msmtp failed (exit {e.returncode})")


def main() -> int:
    if len(sys.argv) != 3:
        sys.exit("usage: send-email.py <digest|reels> <STAMP>")
    mode, stamp = sys.argv[1], sys.argv[2]
    log(f"mode={mode} stamp={stamp}")
    subject, plain, html = assemble(mode, stamp)
    log(f"subject='{subject}' plain={len(plain)}B html={len(html)}B")
    send(subject, plain, html)
    log(f"sent to {TO}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
