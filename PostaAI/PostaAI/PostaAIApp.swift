import SwiftUI

@main
struct PostaAIApp: App {
    init() {
        FontRegistration.registerOnce()
        // Arc A: pre-fetch del Pool en background al arrancar. Corre en
        // paralelo al onboarding/coach para que cuando el usuario llegue
        // al Deck el caché ya esté caliente.
        Task.detached(priority: .userInitiated) {
            await PreFetcher.kickoff()
        }
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
    }
}

// En Debug usamos el Mock (lee del fixture local), el pre-fetch no aplica.
// En Release pegamos contra el CDN y populamos el caché de UserDefaults antes
// que el RootView monte su load(). Si el pre-fetch falla (sin red, etc.), el
// load() del VM va a hacer su propio fetch + fallback a caché viejo si existe.
enum PreFetcher {
    static func kickoff() async {
        #if DEBUG
        return
        #else
        let repo = LiveCardRepository()
        do {
            let drop = try await repo.fetchTodayDrop()
            if drop.status == "published" {
                await MainActor.run {
                    let store = Persistence()
                    store.saveCachedDrop(drop)
                    store.lastFetchedAt = Date()
                    print("PreFetcher: cache primed (\(drop.cards.count) cards)")
                }
            } else {
                print("PreFetcher: drop status \(drop.status) — no priming")
            }
        } catch {
            print("PreFetcher: skipped (\(error))")
        }
        #endif
    }
}
