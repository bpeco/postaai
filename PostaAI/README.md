# PostaAI — iOS

Native SwiftUI app implementing the [Claude Design](https://claude.ai/design) handoff bundle `postaai/`. Daily AI-news drops with Argentine voice, swipe-to-decide, double-tap to expand.

## Run

```bash
open PostaAI.xcodeproj
# Then ⌘R in Xcode against any iPhone simulator (16+ recommended)
```

Or from the command line:

```bash
xcodebuild -scheme PostaAI -destination 'platform=iOS Simulator,name=iPhone 16' build
DEVICE=$(xcrun simctl list devices available | awk '/iPhone 16 \(/{print $NF}' | tr -d '()' | head -1)
xcrun simctl boot "$DEVICE" 2>/dev/null; open -a Simulator
APP=$(find ~/Library/Developer/Xcode/DerivedData/PostaAI-*/Build/Products/Debug-iphonesimulator/PostaAI.app -maxdepth 0 | head -1)
xcrun simctl install "$DEVICE" "$APP"
xcrun simctl launch "$DEVICE" com.bauti.postaai
```

Deployment target: **iOS 17.0**.

## Architecture

```
PostaAI/
  PostaAIApp.swift          @main, registers fonts, mounts RootView
  Design/                   Theme tokens + runtime font registration fallback
  Models/                   Card, Drop, Decision
  Data/                     CardRepository protocol + MockCardRepository (loads PostaDrop.json)
  State/                    @Observable AppViewModel + UserDefaults persistence
  Views/
    RootView                Custom tab container + Detail sheet + Coach overlay
    Components/             TopBar, DropProgressBar, BottomNav, TagPill, DeepenHint, IconButton
    Hoy/                    HoyScreen, DeckView, CardView, SwipeableCard, SwipeStamps, EndScreen
    Detail/                 DetailView (slide-up sheet with editorial Take box)
    Archive/                ArchiveScreen (saved cards list, empty state)
    Settings/               SettingsScreen (drops + interest chips + account)
    Coach/                  CoachOverlay (first-run gesture explainer)
  Resources/
    Fonts/                  Bricolage Grotesque, Albert Sans, JetBrains Mono TTFs
    Fixtures/PostaDrop.json The 6-card drop fixture
```

## Swapping the data source

`MockCardRepository` is wired into `AppViewModel` by default. To plug in a real backend, implement `CardRepository`:

```swift
struct LiveCardRepository: CardRepository {
    func fetchTodayDrop() async throws -> Drop {
        // network call
    }
}
```

…and pass it to `AppViewModel(repository: LiveCardRepository())`.

## Persisted state

- `postaai.hasSeenCoach` (Bool) — gates first-run coach overlay
- `postaai.savedIds` (JSON array) — cards swiped right or saved from detail
- `postaai.interests` (JSON array) — toggled interest chips in Settings

Wipe via Simulator → Device → Erase All Content, or:

```bash
xcrun simctl spawn booted defaults delete com.bauti.postaai
```

## Out of scope (v1)

- Prototype's "Tweaks" panel (gesture mode + density variations) — only `lateral` + `comfy` are shipped.
- Real drop scheduling / push notifications.
- Dark mode (design is paper-light only).
- Haptics / sounds.
