# ai-digest — motor de contenido

Pipeline que junta noticias AI de 21 fuentes y genera 3 outputs editoriales 2x/día (09:00 y 18:00), entregados como 2 emails HTML. Corre vía **launchd** (`~/Library/LaunchAgents/com.bauti.ai-digest.plist`).

Es el **motor de contenido de PostaAI** (la app iOS). Ver `../CLAUDE.md` para el panorama; ver `../PostaAI/CLAUDE.md` para el contrato `Drop`/`Card` que este pipeline eventualmente tendrá que producir.

## Arquitectura (8 fases)

```
run-digest.sh (entry point)
  [1] fetch-sources.sh   → /tmp/digest-raw-STAMP.json    (curl paralelo, 21 fuentes, bodies base64)
  [2] extract-items.py   → /tmp/digest-items-STAMP.json  (parsea RSS/Atom/HN/Reddit → schema unificado)
  [3] rank-items.py      → /tmp/digest-top-STAMP.json     (dedup + score + top 15, cap 3 por fuente)
  [4] claude -p digest   → digests/STAMP.md   (resumen del día, 15 noticias, audiencia técnica)
  [5] claude -p ideas    → ideas/STAMP.md     (8 ideas de Shorts técnicas, para devs)
  [6] claude -p reels    → reels/STAMP.md     (10 ideas de Reels masivas, para no-devs)
  [7] send-email.py digest → Email A "AI digest STAMP"  (digest + ideas técnico)
  [8] send-email.py reels  → Email B "Reels ideas STAMP" (reels masivo)
```

`STAMP` = `YYYY-MM-DD-HH`.

**Por qué funciona en `claude -p`** (y por qué V1 no funcionaba): las 3 llamadas a Claude son **stdin + prompt string, cero tool calls** → cero permission prompts → no se cuelga. Claude solo procesa ~5KB de items ya curados, no los 8MB de XML crudo. La V1 fallaba porque intentaba auto-invocar una skill, y **las skills no se auto-invocan en modo `-p`**.

## Comandos

```bash
./scripts/run-digest.sh              # corrida completa (~5-6 min)
./scripts/run-digest.sh --dry-run    # solo fases 1-3 (sin claude, sin email) — ~5s
./scripts/run-digest.sh --no-email   # fases 1-6 (genera todo, no envía) — ~5min

# launchd
launchctl list | grep ai-digest
launchctl start com.bauti.ai-digest                                  # disparar ahora
launchctl unload/load ~/Library/LaunchAgents/com.bauti.ai-digest.plist

# logs
ls -t /tmp/ai-digest-*.log | head -1 | xargs cat    # último run
cat /tmp/ai-digest-launchd.{out,err}                # output de launchd
```

Testear una fase aislada: `cat /tmp/digest-top-STAMP.json | claude -p "$(cat prompts/digest.md)"` (idem `ideas.md` / `reels.md`).

## Archivos clave

- `scripts/run-digest.sh` — orchestrator. PATH explícito al tope (corre igual bajo launchd que interactivo).
- `scripts/fetch-sources.sh` — curl paralelo; bodies en base64; usa `jq --rawfile` (no `--arg`) para feeds grandes.
- `scripts/extract-items.py` — parser stdlib. `MAX_ITEMS_PER_SOURCE=30`. Limpia chars de control C0 que rompen el JSON.
- `scripts/rank-items.py` — dedup (URL normalizada + Jaccard 0.85), score = `source_weight × recency + engagement_boost`, `MAX_PER_SOURCE=3` en el top final (evita que arxiv inunde).
- `scripts/send-email.py` — `pandoc` (markdown→HTML5) + `email.message.EmailMessage` multipart/alternative + `msmtp -a gmail`. Modos `digest` / `reels`.
- `sources.json` — 21 fuentes. Tipos: `rss` | `hn_algolia` | `reddit_json` | `webfetch`. Si agregás una, sumá su peso a `SOURCE_WEIGHTS` en `rank-items.py`.
- `prompts/{digest,ideas,reels}.md` — los 3 prompts. Cambios surten efecto al próximo run, sin tocar código.

Pesos de fuente: 3.0 frontier labs · 2.5 newsletters · 2.0 domain-specific · 1.5 hn · 1.0 reddit.

## Dependencias

`jq`, `curl`, `python3`, `claude` (Max OAuth), `msmtp` (config en `~/.msmtprc` con App Password), `pandoc` (markdown→HTML). Antes de sumar una dependencia nueva, avisar.

## Roadmap / foco actual

**Extracción configurable / por-usuario.** Hoy hay un único pipeline igual para todos. La dirección es: definir mejor qué tipo de info se extrae y dar más opciones (perfiles/intereses), en vez de un solo extract uniforme. No sobre-diseñar todavía — se va a definir mejor sobre la marcha.

**El puente hacia la app** (objetivo, todavía no implementado): una fase que transforme los items rankeados al schema `Drop`/`Card` que consume PostaAI, reemplazando el fixture mock. El contrato exacto está en `../PostaAI/CLAUDE.md`.
