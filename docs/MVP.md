# MVP — scope y detalle construible

Doc vivo. Es el plan de construcción del primer build público. El **por qué** de las decisiones grandes vive en `docs/adr/`; el **lenguaje** vive en `CONTEXT-MAP.md`; acá vive el **qué** concreto.

A medida que cerramos cada hilo abierto cae en este doc. Cuando A→G están todos cerrados, este doc ES el plan de implementación.

## Arquitectura (resumen)

```
NUBE (cron 2x/día, OAuth token)
  fetch 21 fuentes → extract → rank (ensanchar a ~30-40)
    → claude -p "cards" → Pool JSON (cards etiquetadas: Tema[1+1] + Entidad)
      → guardrails en el prompt + kill-switch
      → auto-publica al CDN

CDN (JSON estático)
  latest-mañana.json / latest-tarde.json

APP iOS
  onboarding obligatorio → Intereses (Tema + Entidad)
  baja el Pool → arma el Drop on-device:
    matchea-intereses arriba + "también pasó hoy" abajo
```

## Decisiones cerradas

Ver tabla en `CONTEXT-MAP.md` y ADRs: 0001 (pool+filtro), 0002 (nube+OAuth), 0003 (Industria diferida).

---

## Hilos abiertos

### A. Taxonomía de Interés — **CERRADO**

**Tema** — enum fijo de 9, 1 primario + 1 secundario por Card. El campo `kind` de la Card pasa de string a array.

| slug | label visible | supply esperado |
|---|---|---|
| `modelos` | Modelos | fuerte |
| `codigo` | Código & devtools | fuerte |
| `agentes` | Agentes | medio |
| `research` | Research & papers | fuerte |
| `open-source` | Open source & local | fuerte |
| `negocio` | Negocio & plata | medio |
| `robots` | Hardware & robots | flaco |
| `regulacion` | Regulación & política | flaco |
| `producto` | Producto & apps | medio |

Los chips flacos no rompen nada: el modelo híbrido siempre llena el Drop con "también pasó hoy".

**Entidad** — display abierto, seguibles curados.

- El `tag` visible de la Card es **abierto**: el generador nombra a quien sea (una entidad primaria por Card). No se cambia el schema.
- Las **Entidades seguibles** (chips del onboarding) son una lista curada — propuesta inicial (editable):
  `OpenAI · Anthropic · Google DeepMind · Meta · Microsoft · Mistral · xAI · Hugging Face · DeepSeek · Nvidia · Apple · Amazon`
- Una Card matchea un Interés-de-Entidad solo si su `tag` ∈ esta lista. Las nicho (ej: Figure, Stainless) aparecen vía Tema o en "también pasó".

**Producto** — tercer eje seguible, jerárquico sobre Entidad (ver ADR-0004).

- Card suma `product: String?` (opcional). Lista curada inicial (editable):
  `Claude Code · Claude Desktop · ChatGPT · Codex · Cursor · Copilot · Gemini app · Perplexity · v0 · Windsurf`
- Display: la Card muestra "Org · Producto" como texto secundario cuando aplica; la pill coloreada sigue siendo la Org.
- Onboarding: sección secundaria/colapsable, no obligatoria (solo Tema es obligatorio).
- Filtro: match si cualquiera de (tema ∨ org ∨ producto) está en las selecciones del usuario.

**Diferido a v1.1**: Industria como vertical (ADR-0003) y Personas seguibles. Para futuros ejes aplicar la **regla de los dos filtros** (ADR-0004): supply real + valor único.

---

### B. `tagColor` — **CERRADO**

El **color lo resuelve la app**, no el generador. El Pool JSON ya no incluye `tagColor`.

- Mapa fijo Entidad→hex para los seguibles (brand colors), vive en `Design/BrandColors.swift` (o extiende `Theme.swift`).
- Para entidades nicho (no en la lista de seguibles): **gris neutro único**.
- Efecto colateral deseado: las Cards de tus marcas favoritas son las coloridas, el resto es gris — refuerza visualmente el "lo tuyo" del modelo híbrido sin UI extra.

Cambios al schema y al código capturados en la sección de cambios.

### C. Estados de datos en la app — **CERRADO**

**Freshness**: en cada apertura, la app fetchea el Pool más reciente publicado en el CDN. **No hay pantallas de espera** edition-aware — siempre se muestra lo último que hay.

**Primera apertura (caso feliz, Arc A)** — la coreografía que define la primera impresión:
1. App abre → arranca el pre-fetch del Pool en background **inmediatamente** (Task en `PostaAIApp` o `AppViewModel`).
2. Onboarding (chips) en pantalla; el usuario elige mientras la red trabaja en paralelo.
3. Termina onboarding → micro-transición teatral 1-2s "armando tu primer drop / eligiendo lo tuyo del drop de hoy" — puede referenciar por nombre un Interés que eligió.
4. Deck aparece con el **Coach overlay** sobre la **primera card REAL** del top de "lo tuyo".

**Aperturas siguientes (cache hit)**:
- Pool ya visto entero → EndScreen "el próximo sale a las XX:XX".
- Hay drop nuevo → Deck directo en la primera card no vista.

**Red rota con cache**: usa cache + badge offline chico (no bloquea).

**Red rota sin cache (edge case, ej: primer launch + red rota)**: retry x1 silencioso → si falla, mensaje gentle con botón "reintentar". No se bundlea starter pool (el reviewer tiene wifi).

**Cache**: persistir el último Pool a disco después de cada fetch exitoso. UserDefaults o un JSON en Documents.

### D. CDN + layout — **CERRADO**

**Host**: Vercel. Aprovecha el runner ya planeado.

**Flujo de publicación** (git-based, recomendado):
- Repo separado: `postaai-content`. Contiene `latest.json` + `archive/YYYY-MM-DD-HH.json`.
- El runner (GH Actions o VPS, ver ADR-0002) corre el pipeline, genera el Pool, hace `git commit` + `git push` al repo de contenido.
- Vercel watchea el repo y auto-deploya. URL pública: `cdn.postaai.app/latest.json` (custom domain) o `postaai-content.vercel.app/latest.json`.
- **Beneficio gratis**: cada drop es un commit con timestamp en el mensaje → archivo histórico via `git log` sin infra extra. Roll-back = `git revert`.

**Layout**:
- `latest.json` — un solo archivo, siempre apunta al Pool más reciente (alineado con freshness "show latest available", hilo C). El cron lo sobrescribe.
- `archive/YYYY-MM-DD-HH.json` — copia inmutable por edición (para el kill-switch del hilo E y para debugging).

**Headers**: `Cache-Control: public, max-age=60` para `latest.json` (correcciones propagan rápido); `max-age=31536000, immutable` para el archive.

**App**: `URLSession` contra la URL fija; sin lógica de selección de edición (no la necesita).

**Alternativa descartada**: Vercel Blob (storage API). Más simple sin git, pero perdés el archive-via-commits y agregás SDK. Si en algún momento las publicaciones son muy frecuentes y los builds de Vercel molestan, se reconsidera.

### E. Kill-switch — **CERRADO**

Dos modalidades, ambas sobre la infra que ya hay (Vercel + git), cero API extra:

**1. Pausar (no requiere tener la corrección lista).**
- Schema: el Pool top-level suma `status: "published" | "paused"` y `pause_message: String?` opcional.
- Mecanismo: push a `postaai-content` con un stub `{"status":"paused", "pause_message":"estamos actualizando el drop, vení en un rato"}` reemplaza `latest.json`.
- App: si `status == "paused"`, renderiza una `PausedScreen` con el mensaje (o uno default). El Deck no se muestra.
- Cache TTL 60s = los usuarios ven la pausa en ~1 minuto.

**2. Revertir o reemplazar.**
- `git revert HEAD` en `postaai-content` vuelve al Pool anterior bueno.
- O `git push` con un Pool corregido (regenerado a mano o editado).
- El archive en `archive/YYYY-MM-DD-HH.json` queda inmutable como referencia.

**Implementación**: scripts en el repo `postaai-content` — `make pause MSG="..."`, `make unpause`, `make revert` — para no tipear git crudo en pánico desde el cel.

### F. Logística de Apple — **CERRADO**

**Secuencia**: TestFlight privado primero (1-2 semanas, 10-20 testers del círculo) → promover el binario probado a App Store submission. Mismo binario, no se rehace.

**Checklist no-grill (work-to-do)**:
- **App display name**: por decidir (sugerencias: "Posta" + subtítulo "Noticias AI con onda" / "PostaAI" / "Posta IA"). Reversible, decide cuando armes el App Store Connect.
- **Privacy label**: **Data Not Collected** (sin auth, sin analytics, intereses on-device). Apple lo simplifica enormemente — diferencial de marketing también.
- **Age rating**: 17+ (categoría News estándar).
- **Localización**: solo español (rioplatense argentino, alineado al producto). Inglés en v1.1+ si aplica.
- **Account deletion**: N/A (no hay cuentas). Documentar en review notes.
- **Icon**: verificar que `AppIcon.appiconset` tenga todos los tamaños (ya está el slot en Assets.xcassets).
- **Screenshots**: 6.7" iPhone obligatorio (5-10 imágenes). Mostrar: onboarding (chips), Deck con "lo tuyo", DetailView con "El take de Posta", ArchiveScreen.
- **App Store description**: 1 párrafo + bullet points, en rioplatense. Subtítulo (30 chars) clave para ASO.
- **Review notes**: explicar el modelo (no hay login, contenido auto-generado, kill-switch interno).

**Landing page (nueva pieza de scope, va en Vercel)**:
- Single page en `postaai.app` (o subdominio).
- **Support URL**: form de contacto o `mailto:soporte@postaai.app`.
- **Privacy policy URL**: una página estática diciendo "no recolectamos datos" + boilerplate de Apple. Puede ser una sola página con anchors `/support` y `/privacy`.
- Bonus: la misma landing puede tener un "bajá la app" cuando esté en la store. Vive en el mismo proyecto Vercel que el CDN del Pool (subdir o app aparte).

### G. Monetización — **CERRADO**

**Gratis en el MVP.** Sin IAP, sin ads, sin sponsor.

Razón: tu costo marginal por usuario es ≈ cero (CDN estático, contenido global, sin backend), así que no hay urgencia económica. Validás adopción + retención primero, después elegís modelo con datos reales (premium tier con archivo histórico, sponsorship editorial, etc).

A futuro (post-MVP, no comprometido): suscripción opt-in con archivo navegable + "profundizar con AI" parece el match más natural con la propuesta. Sponsorship editorial es una buena segunda línea cuando haya audiencia.

---

## Cambios al código que ya quedaron definidos

Capturados acá para no perderlos cuando arranque la implementación.

**`ai-digest`**
- Nueva fase entre rank y email: `claude -p "cards"` con prompt nuevo (`prompts/cards.md`), input = top rankeados, output = Pool JSON con schema Card extendido (ver abajo). [HECHO en Etapa 2]
- `rank-items.py`: ensanchar el top de 15 a ~30-40 para alimentar el Pool. [HECHO en Etapa 2]
- `prompts/cards.md`: emitir `published_at` ISO 8601 por Card (campo ya existe en el input desde `extract-items.py`), eliminar generación de `meta` como string display. [Etapa 4]
- Sumar paso de upload del Pool al CDN: `publish-pool.sh` que escribe `latest.json` + `archive/YYYY-MM-DD-{morning,evening}.json` en repo `postaai-content` y hace `git push`. [Etapa 4]
- Migrar de Mac/launchd a runner GH Actions con `CLAUDE_CODE_OAUTH_TOKEN`. [Etapa 5]

**`PostaAI`**
- Card: `kind: String` → `kind: [String]` (1-2 temas). Sumar `product: String?` opcional. Quitar `tagColor` (lo resuelve la app, ver B). [HECHO en Etapa 1]
- Card: `meta: String` → `publishedAt: Date` (CodingKey `published_at`, decoder con `.iso8601`). `CardView` renderiza "hace X horas" en runtime con `RelativeDateTimeFormatter`. [Etapa 4]
- Sumar `Design/BrandColors.swift` con mapa Entidad→hex (~12 seguibles) + constante de gris neutro. [HECHO en Etapa 1]
- Implementar `LiveCardRepository` (fetch del CDN). Cableo: build flag `#if DEBUG → Mock, #else → Live`. Mock se queda. URL hardcodeada a `postaai-content.vercel.app/latest.json` con TODO de swap a `cdn.postaai.app` en Etapa 6. [Etapa 4]
- Caché en `UserDefaults` key `postaai.cachedPool` (Data del Drop). Una sola key, sobreescribe. Solo guardar si `drop.status == "published"`. [Etapa 4]
- Refresh: cold start + `ScenePhase` observer que re-fetchea al `.active` si `lastFetchedAt` > 15min. Persistir `lastFetchedAt` en UserDefaults. [Etapa 4]
- Pantalla de onboarding obligatorio con 3 secciones de chips: Tema (obligatoria), Entidad (opcional), Producto (opcional, colapsable). "Todos / sorprendeme" cuenta como completar-en-1-tap. [HECHO en Etapa 3]
- Card view: mostrar "Org · Producto" como texto secundario cuando `product != nil`. [HECHO en Etapa 3]
- Deck: implementar la separación "lo tuyo" / "también pasó hoy" en `DeckView`. Match = `tema` ∨ `org` ∨ `producto` ∈ selecciones. [HECHO en Etapa 3]
- Estados loading/error/offline (hilo C): `ErrorScreen` (sin red sin caché) y `BrokenContentScreen` (404/JSON roto/decode fail sin caché). Si hay caché válido, siempre se prioriza mostrarlo + badge offline en TopBar. [Etapa 4]
- `PausedScreen` para cuando el Pool tiene `status == "paused"`. [HECHO en Etapa 3]
- Arc A: `Task` arrancada en `PostaAIApp.init` para pre-fetch en background mientras corre onboarding. Micro-transición teatral 1-2s al cerrar onboarding ("armando tu primer drop"). [Etapa 4]

---

## Orden de construcción

Secuencia pensada para que cada etapa desbloquee la siguiente y nada quede esperando dependencias. Cada etapa termina con algo verificable.

**Etapa 1 — Contratos (schema + prompt).** Antes de tocar código que dependa, fijar la forma de los datos y la voz.
- Actualizar Swift models: `Card.kind` → `[String]`, sumar `Card.product: String?`, quitar `Card.tagColor`. Pool top-level con `status` + opcional `pause_message`. Actualizar el fixture `PostaDrop.json` al nuevo schema.
- Escribir `ai-digest/prompts/cards.md`: vocabulario controlado (9 Temas, ~12 Entidades seguibles, ~10 Productos), guardrails (no especular como hecho, atribuir a fuente, tono rioplatense), formato JSON exacto del Pool.
- **Verifica**: la app builda contra el nuevo schema con el fixture nuevo.

**Etapa 2 — El puente (pipeline → Pool JSON).** Generar contenido real, todavía en tu Mac.
- Ensanchar `rank-items.py` de top-15 a 30-40 (`MAX_ITEMS` y/o relajar `MAX_PER_SOURCE`).
- Nueva fase entre rank y email: `claude -p "$(cat prompts/cards.md)" < rankeados.json > pool.json`. Validar JSON antes de guardar.
- Iterar el prompt contra corridas reales hasta que la voz y el tagging sean buenos (hallucination test: contrastar 3 cards contra la fuente).
- **Verifica**: `cat pool.json | jq` muestra un Pool sintácticamente válido con ~30 cards bien etiquetadas.

**Etapa 3 — La app contra Pool local.** Construir todas las pantallas nuevas leyendo el Pool generado en Etapa 2, sin red todavía.
- `Design/BrandColors.swift`: mapa Entidad→hex + gris neutro.
- Onboarding obligatorio: 3 secciones de chips (Tema obligatoria, Entidad opcional, Producto opcional/colapsable), "todos / sorprendeme" como completar-en-1-tap.
- `DeckView` con la separación "lo tuyo" / "también pasó hoy" + matching `tema` ∨ `org` ∨ `producto`.
- Card view: mostrar "Org · Producto" cuando aplica.
- `PausedScreen`.
- **Verifica**: cargás el Pool real en la app, hacés onboarding, el Deck respeta el hybrid sort, "también pasó" aparece cuando corresponde.

**Etapa 4 — Wiring del fetch real (publicación corriendo desde tu Mac).** Estructura híbrida (decidida con `/grill-with-docs`): el script de push se escribe una sola vez y vive en tu Mac durante Etapa 4. En Etapa 5 se mueve al cron de GH Actions sin re-escribirlo. Bloques:

*Lado infra (CDN + publicación)*
- Crear repo `postaai-content` en GitHub. Layout: `latest.json` + `archive/YYYY-MM-DD-{morning,evening}.json` (slot = hora ARG del cron, no timestamp real — decisión #3).
- Setup Vercel: importar `postaai-content`, dominio `postaai-content.vercel.app` (custom domain `cdn.postaai.app` se difiere a Etapa 6 junto con la landing — decisión #4). Cache headers: `latest.json` → `Cache-Control: public, max-age=60`; `archive/*` → `max-age=31536000, immutable`.
- Nueva fase en `ai-digest/scripts/run-digest.sh` (10ª, después de la Pool): `publish-pool.sh` que `cp` del Pool generado a clone local del repo de contenido, lo escribe en `latest.json` Y en `archive/YYYY-MM-DD-{slot}.json`, `git commit` con timestamp UTC en el message, `git push`. Slot inferido del horario de disparo del run (mañana < 14:00 UTC, tarde después).

*Lado prompt + schema (`published_at` fix)*
- Modificar `ai-digest/prompts/cards.md` para emitir `published_at` ISO 8601 por Card (campo ya viene en el input desde `extract-items.py` — no se toca el ingest). Eliminar la instrucción de generar `meta` como string display.
- Swift `Card`: reemplazar `meta: String` por `publishedAt: Date` (CodingKey `published_at`, JSONDecoder con `.iso8601` strategy).
- `CardView` usa `RelativeDateTimeFormatter` (nativo iOS) para renderizar "hace X horas" en runtime, con el `Date` del dispositivo.
- Regenerar fixture `PostaDrop.json` con el schema nuevo (correr pipeline una vez con prompt actualizado, o `jq` quirúrgico que mapee del Pool actual).

*Lado app (`LiveCardRepository` + caché + Arc A)*
- `LiveCardRepository: CardRepository` que fetchea `postaai-content.vercel.app/latest.json` con `URLSession`. URL hardcodeada en una constante con TODO de migración a custom domain.
- Selección Mock vs Live: build flag `#if DEBUG → MockCardRepository(), #else → LiveCardRepository()`. Mock se queda; fixture sigue siendo Pool real (decisión #9).
- Caché en `UserDefaults` bajo key `postaai.cachedPool` (Data serializada del Drop). Una sola key — sobreescribe (decisión #6).
- **Regla de cache**: solo guardar si `drop.status == "published"`. Si llega Pool con `status: paused`, mostrar `PausedScreen` pero NO pisar el caché bueno (decisión #7).
- **Refresh strategy**: cold start siempre + observer en `ScenePhase` que re-fetchea al pasar a `.active` si `Date().timeIntervalSince(lastFetchedAt) > 900` (15 min). Sin pull-to-refresh manual (decisión #8). Persistir `lastFetchedAt` en UserDefaults.
- **Error handling** (decisión #10): expandir `CardRepositoryError` con `.network(underlying:)`. Dos buckets de UX:
  - Sin red / timeout → si hay caché válido (último `published`), mostrar Pool cacheado + badge offline pequeño en TopBar. Si NO hay caché → `ErrorScreen` nueva, copy "no pudimos cargar el drop, dale reintentar".
  - Contenido inválido (404, JSON malformed, decode failure) → si hay caché, igual mostrarlo (caché viejo > pantalla rota). Si NO → `BrokenContentScreen` (semánticamente parecida a PausedScreen) con copy "tuvimos un problema con el drop de hoy, vení en un rato".
  - `print()` con el case específico en Debug+Release. Sin Sentry en MVP.
- **Arc A**: kick off del pre-fetch en `PostaAIApp.init` (Task arrancada en background), corre en paralelo al onboarding. Al terminar onboarding, micro-transición teatral 1-2s "armando tu primer drop" (puede referenciar por nombre un Interés elegido). Si el fetch ya terminó cuando termina onboarding, mostrar la transición igual por consistencia visual.
- **Verifica**: (1) app fetchea real del CDN, (2) cachea bajo `postaai.cachedPool`, (3) modo avión + relanzar → sigue mostrando lo último; (4) push de un Pool nuevo desde tu Mac → próxima apertura lo trae; (5) push de un stub `{"status":"paused",...}` → PausedScreen renderea, modo avión + relanzar → vuelve al Pool bueno cacheado; (6) Arc A funciona en first-launch con red.

**Etapa 5 — Auto-publicación cron en la nube.** El script de Etapa 4 ya existe; esta etapa solo lo mueve al runner.
- `claude setup-token` → guardar `CLAUDE_CODE_OAUTH_TOKEN` como secret de GitHub Actions.
- Migrar `ai-digest/scripts/run-digest.sh` (con la fase `publish-pool.sh` ya integrada en Etapa 4) a workflow de GH Actions. Cron `0 12,21 * * *` (UTC para 09:00/18:00 ARG, con DST a chequear cuando aplique).
- Secrets adicionales: credenciales SMTP para emails (si se mantiene la fase 8), deploy key SSH para el repo `postaai-content`.
- Scripts `make pause / unpause / revert` en el repo de contenido (para kill-switch desde el cel sin tipear git crudo).
- **Verifica**: dos drops reales, dos días consecutivos, sin que toques tu Mac. La app móvil ve el drop nuevo a las 09:01 ARG.

**Etapa 6 — Pre-launch.**
- Landing page Vercel con `/support` y `/privacy`.
- App Store Connect: bundle id, descripción, screenshots, ícono completo, privacy label "Data Not Collected", age rating 17+, review notes.
- TestFlight build firmado.

**Etapa 7 — Beta + launch.**
- TestFlight privado 1-2 semanas con 10-20 testers del círculo.
- Iterar bugs, voz, kill-switch (probarlo en serio: pausar, revertir).
- Promover el binario estable a App Store submission.
