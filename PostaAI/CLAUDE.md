# PostaAI — app iOS

App nativa SwiftUI. Muestra "drops" diarios de noticias AI con voz argentina: swipe para decidir (descartar / guardar), doble-tap para profundizar. Diseño **paper-light editorial** (NO dark mode en v1).

- Bundle: `com.bauti.postaai`
- Deployment target: **iOS 17.0**
- Es el consumidor del contenido que genera `../ai-digest/` (ver `../CLAUDE.md`).

## Cómo correr

```bash
open PostaAI.xcodeproj      # luego ⌘R contra un simulador iPhone (16+)
```

Desde CLI:

```bash
xcodebuild -scheme PostaAI -destination 'platform=iOS Simulator,name=iPhone 16' build
DEVICE=$(xcrun simctl list devices available | awk '/iPhone 16 \(/{print $NF}' | tr -d '()' | head -1)
xcrun simctl boot "$DEVICE" 2>/dev/null; open -a Simulator
APP=$(find ~/Library/Developer/Xcode/DerivedData/PostaAI-*/Build/Products/Debug-iphonesimulator/PostaAI.app -maxdepth 0 | head -1)
xcrun simctl install "$DEVICE" "$APP" && xcrun simctl launch "$DEVICE" com.bauti.postaai
```

## Arquitectura

`PostaAIApp.swift` (@main, registra fuentes) → `RootView` (tab container custom + Detail sheet + Coach overlay).

```
Models/      Card, Drop, Decision, Vocabulary (9 Temas + 12 Entidades + 10 Productos), DeckItem
Data/        CardRepository (protocolo + CardRepositoryError) + MockCardRepository + LiveCardRepository (URLSession contra CDN)
State/       AppViewModel (@Observable, LoadState machine) + Persistence (UserDefaults)
Views/
  Hoy/       HoyScreen, DeckView, CardView, SwipeableLayer, SwipeStamps, EndScreen, PausedScreen, ContinuationCard
  Detail/    DetailView (sheet slide-up con el box editorial "El take de Posta")
  Archive/   ArchiveScreen (guardadas + empty state)
  Settings/  SettingsScreen (drops + chips de interés 3 facetas + cuenta)
  Onboarding/ OnboardingScreen (gate de first-launch, 3 secciones de chips)
  Coach/     CoachTutorial (3 cards interactivas swipeable)
  Error/     ErrorScreen, BrokenContentScreen
  Components/ TopBar (con badge "SIN RED"), DropProgressBar, BottomNav, TagPill, DeepenHint, IconButton, ChipSection, FlowLayout
Design/      Theme (tokens) + BrandColors (Entidad → color) + FontRegistration (fallback runtime)
Resources/   Fonts/ (TTFs) + Fixtures/PostaDrop.json (= Pool real del pipeline, ver ../ai-digest/)
                                Fixtures/PostaDrop.{pre-publishedat,artesanal}.json (backups previos)
```

## Modelo de datos — EL CONTRATO con el pipeline

Esto es lo que `ai-digest` produce (el **Pool**) y la app consume. Definido en `Models/Card.swift` y `Models/Drop.swift`:

```swift
struct Drop {
    let date: String          // ej "2026-05-28" (ISO) o "Mar 12 May"
    let edition: String       // ej "Edición de la tarde · 18:00"
    let number: Int           // nº de edición correlativo
    let status: String        // "published" | "paused" — kill-switch (MVP hilo E)
    let pauseMessage: String? // CodingKey "pause_message", mostrado en PausedScreen
    let cards: [Card]
}

struct Card {
    let id: String
    let tag: String           // Entidad — display abierto, color resuelto en BrandColors
    let headline: String
    let take: String          // hook editorial corto (se ve en la card)
    let context: String       // background completo (se ve en detalle)
    let editorial: String     // "El take de Posta" — destacado en box oscuro
    let source: String
    let sourceLabel: String
    let publishedAt: Date     // CodingKey "published_at" — ISO 8601 UTC. App rendea "hace X horas" con RelativeDateTimeFormatter
    let kind: [String]        // 1-2 Temas slug del vocabulario (modelos, codigo, agentes, ...)
    let product: String?      // opcional: producto seguible (Claude Code, ChatGPT, ...)
}
```

`Resources/Fixtures/PostaDrop.json` ES un Pool real producido por `ai-digest` (ver `../ai-digest/`). Si cambiás estos structs, actualizá también el prompt `../ai-digest/prompts/cards.md` o el decode del próximo Pool falla.

Vocabularios canónicos (espejados con `prompts/cards.md`) en `Models/Vocabulary.swift`.

## Swap del data source — build flag

`AppViewModel.init()` selecciona el repository según el build:

```swift
#if DEBUG
self.repository = MockCardRepository()   // lee Resources/Fixtures/PostaDrop.json
#else
self.repository = LiveCardRepository()   // fetcha postaai-content.vercel.app/latest.json
#endif
```

Override explícito (`AppViewModel(repository: ...)`) sigue funcionando para tests. Para probar el LiveCardRepository en device, hace falta build Release (`xcodebuild -configuration Release`) o configurar un scheme custom sin `DEBUG`.

## CDN + cache offline

- **URL**: `https://postaai-content.vercel.app/latest.json` (TODO: `cdn.postaai.app` en Etapa 6). Repo de contenido: `bpeco/postaai-content`, fase 10 del pipeline (`ai-digest/scripts/publish-pool.sh`) lo publica 2x/día.
- **Caché**: solo se guarda si `drop.status == "published"`. Un `paused` NO pisa el caché bueno — la app muestra `PausedScreen` pero al volver online sin paused, recupera el último Pool válido.
- **Refresh**: cold start siempre (`.task` en RootView). Adicionalmente, observer en `\.scenePhase`: al pasar a `.active`, si `lastFetchedAt > 15min`, refetch.
- **Arc A**: `PostaAIApp.init` arranca un `Task.detached` que dispara `PreFetcher.kickoff()` — fetchea + guarda en caché en paralelo al onboarding/coach. Al terminar onboarding, RootView muestra `FirstDropTransition` 1.5s antes del Deck.
- **Error UX**: `LoadState` machine (`idle/loading/ok/paused/offlineCached/error/brokenContent`) drive HoyScreen. Sin red + sin caché → `ErrorScreen` con reintentar. Contenido roto + sin caché → `BrokenContentScreen` pasiva. Si hay caché → siempre se prioriza mostrarlo + badge "SIN RED" en TopBar.

## Estado persistido (UserDefaults)

- `postaai.hasSeenCoach` (Bool) — gatea el CoachTutorial de primera vez
- `postaai.hasCompletedOnboarding` (Bool) — gatea OnboardingScreen al first-launch
- `postaai.savedIds` (JSON array) — cards swipeadas a la derecha / guardadas
- `postaai.interests` (JSON array de strings con prefijos) — `tema:slug`, `org:Nombre`, `producto:Nombre`. Tres facetas en un solo set. Strings sin prefijo conocido se ignoran al cargar.
- `postaai.cachedPool` (Data) — último Drop publicado, JSON encoded con `.iso8601` strategy. Solo se guarda si `status == "published"`.
- `postaai.lastFetchedAt` (Date) — timestamp del último fetch exitoso. Drive el threshold de refresh de 15min.

## Design tokens

`Design/Theme.swift`: paper `#F1ECDF`, ink `#15110A`, brand `#2D4FFF`, yes `#2BB673`, no `#EF4423`, highlight `#FFD23F`.
Fuentes: **Bricolage Grotesque** (headlines), **Albert Sans** (cuerpo), **JetBrains Mono** (meta/mono). Registradas en runtime con fallback a system.

Limpiar UserDefaults completos (testing fresh): `xcrun simctl spawn booted defaults delete com.bauti.postaai` (simulator) o `devicectl device uninstall app` (device).

## Fuera de scope (v1)

Panel de "Tweaks" del prototipo (solo `lateral` + `comfy` shipeados) · scheduling/push real · dark mode · haptics/sonidos.
