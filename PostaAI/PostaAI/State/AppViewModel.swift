import Foundation
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case hoy
    case archive
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hoy:      return "Hoy"
        case .archive:  return "Archivo"
        case .settings: return "Ajustes"
        }
    }
}

// Drive de la pantalla principal. La separación es importante para que
// HoyScreen pueda decidir entre Deck normal / PausedScreen / ErrorScreen /
// BrokenContentScreen / loading.
enum LoadState {
    case idle
    case loading
    case ok                      // fetch fresco, status published
    case paused                  // fetch fresco, status paused (no pisa caché)
    case offlineCached           // fetch falló pero hay caché — mostrar caché + badge
    case error                   // sin red sin caché
    case brokenContent           // contenido inválido (404, JSON malformed) sin caché
}

@Observable
@MainActor
final class AppViewModel {
    private let repository: CardRepository
    private let store = Persistence()

    var drop: Drop?
    var deck: [DeckItem] = []
    var state: LoadState = .idle
    var savedIds: Set<String>
    var discardedCount: Int = 0
    var deepenedIds: Set<String> = []
    var interests: Set<String>
    var hasCompletedOnboarding: Bool
    var selectedTab: AppTab = .hoy
    var detailCard: Card?
    var showCoach: Bool

    static let alsoTodayCap = 5
    static let refreshThresholdSeconds: TimeInterval = 900  // 15 min

    var totalCards: Int {
        deck.lazy.filter { if case .news = $0 { return true } else { return false } }.count + cardsConsumed
    }
    var cardsConsumed: Int { _initialNewsCount - currentNewsCount }
    private var _initialNewsCount: Int = 0
    private var currentNewsCount: Int {
        deck.lazy.filter { if case .news = $0 { return true } else { return false } }.count
    }
    var progress: Double {
        guard totalCards > 0 else { return 0 }
        return Double(cardsConsumed) / Double(totalCards)
    }
    var savedCards: [Card] {
        guard let drop else { return [] }
        return drop.cards.filter { savedIds.contains($0.id) }
    }
    var stats: DropStats {
        DropStats(
            saved: savedIds.count,
            discarded: discardedCount,
            deepened: deepenedIds.count,
            total: totalCards
        )
    }

    var isPaused: Bool { if case .paused = state { return true }; return false }
    var pauseMessage: String? { drop?.pauseMessage }
    var isOffline: Bool { if case .offlineCached = state { return true }; return false }

    var alsoTodayCount: Int {
        guard let idx = deck.firstIndex(where: { if case .continuation = $0 { return true } else { return false } }) else {
            return 0
        }
        return deck[(idx + 1)...].lazy.filter { if case .news = $0 { return true } else { return false } }.count
    }

    // ── facetas derivadas del Set<String> persistido ─────────────────────

    var selectedTemas: Set<String> {
        Set(interests.compactMap { stripPrefix($0, InterestPrefix.tema) })
    }
    var selectedEntidades: Set<String> {
        Set(interests.compactMap { stripPrefix($0, InterestPrefix.org) })
    }
    var selectedProductos: Set<String> {
        Set(interests.compactMap { stripPrefix($0, InterestPrefix.producto) })
    }

    init(repository: CardRepository? = nil) {
        if let repository {
            self.repository = repository
        } else {
            #if DEBUG
            self.repository = MockCardRepository()
            #else
            self.repository = LiveCardRepository()
            #endif
        }
        let store = self.store
        self.savedIds = store.loadSavedIds()
        self.interests = store.loadInterests() ?? []
        self.hasCompletedOnboarding = store.hasCompletedOnboarding
        self.showCoach = !store.hasSeenCoach
    }

    func load() async {
        state = .loading
        do {
            let fetched = try await repository.fetchTodayDrop()
            if fetched.status == "published" {
                store.saveCachedDrop(fetched)
                store.lastFetchedAt = Date()
                apply(drop: fetched, state: .ok)
            } else {
                // paused — NO pisa el caché bueno (decisión #7 del grill).
                apply(drop: fetched, state: .paused)
            }
        } catch let err as CardRepositoryError {
            await fallbackToCache(error: err)
        } catch {
            await fallbackToCache(error: .network(underlying: error))
        }
    }

    /// Re-fetch sin reset del UI mientras llega — para ScenePhase observer
    /// cuando la app vuelve a foreground. Idéntico a load() conceptualmente.
    func refresh() async {
        await load()
    }

    private func fallbackToCache(error: CardRepositoryError) async {
        if let cached = store.loadCachedDrop() {
            apply(drop: cached, state: .offlineCached)
        } else {
            self.drop = nil
            self.deck = []
            self._initialNewsCount = 0
            self.state = error.isNetworkBucket ? .error : .brokenContent
        }
    }

    private func apply(drop: Drop, state: LoadState) {
        self.drop = drop
        self.state = state
        rebuildDeck(from: drop)
    }

    func decide(_ item: DeckItem, _ decision: Decision) {
        switch item {
        case .news(let card):
            deck.removeAll { if case .news(let c) = $0 { return c.id == card.id } else { return false } }
            switch decision {
            case .save:
                savedIds.insert(card.id)
                store.saveSavedIds(savedIds)
            case .discard:
                discardedCount += 1
            }
        case .continuation:
            if decision == .save {
                deck.removeAll { if case .continuation = $0 { return true } else { return false } }
            } else {
                deck.removeAll()
            }
        }
    }

    func deepen(_ card: Card) {
        detailCard = card
        deepenedIds.insert(card.id)
    }

    func saveFromDetail(_ id: String) {
        savedIds.insert(id)
        store.saveSavedIds(savedIds)
    }

    func closeDetail() {
        detailCard = nil
    }

    func reshuffle() {
        guard let drop else { return }
        rebuildDeck(from: drop)
        savedIds = []
        discardedCount = 0
        deepenedIds = []
        store.saveSavedIds(savedIds)
    }

    func dismissCoach() {
        showCoach = false
        store.hasSeenCoach = true
    }

    func reopenCoach() {
        showCoach = true
    }

    // ── intereses por faceta ─────────────────────────────────────────────

    func toggleTema(_ slug: String) {
        toggle(InterestPrefix.tema(slug))
    }
    func toggleEntidad(_ name: String) {
        toggle(InterestPrefix.org(name))
    }
    func toggleProducto(_ name: String) {
        toggle(InterestPrefix.producto(name))
    }

    func toggleAllTemas() {
        let allSlugs = Set(Vocabulary.temas.map { $0.slug })
        if selectedTemas == allSlugs {
            for slug in allSlugs {
                interests.remove(InterestPrefix.tema(slug))
            }
        } else {
            for slug in allSlugs {
                interests.insert(InterestPrefix.tema(slug))
            }
        }
        store.saveInterests(interests)
        rebuildDeckIfLoaded()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        store.hasCompletedOnboarding = true
    }

    /// True si el caché está caliente, false si está stale o nunca se fetcheó.
    /// Usado por el ScenePhase observer para decidir si vale la pena refrescar.
    var cacheIsStale: Bool {
        guard let last = store.lastFetchedAt else { return true }
        return Date().timeIntervalSince(last) > Self.refreshThresholdSeconds
    }

    private func toggle(_ key: String) {
        if interests.contains(key) {
            interests.remove(key)
        } else {
            interests.insert(key)
        }
        store.saveInterests(interests)
        rebuildDeckIfLoaded()
    }

    private func rebuildDeckIfLoaded() {
        guard let drop else { return }
        rebuildDeck(from: drop)
    }

    func matchesYours(_ card: Card) -> Bool {
        let temas = selectedTemas
        if !temas.isEmpty, !Set(card.kind).isDisjoint(with: temas) { return true }
        let entidades = selectedEntidades
        if !entidades.isEmpty, entidades.contains(card.tag) { return true }
        let productos = selectedProductos
        if let p = card.product, !productos.isEmpty, productos.contains(p) { return true }
        return false
    }

    private func rebuildDeck(from drop: Drop) {
        let cards = drop.cards
        let yours = cards.filter { matchesYours($0) }
        let alsoTodayPool = cards.filter { !matchesYours($0) }
        let alsoToday = Array(alsoTodayPool.prefix(Self.alsoTodayCap))

        if yours.isEmpty {
            self.deck = cards.map { .news($0) }
        } else if alsoToday.isEmpty {
            self.deck = yours.map { .news($0) }
        } else {
            self.deck = yours.map { .news($0) } + [.continuation] + alsoToday.map { .news($0) }
        }
        self._initialNewsCount = self.deck.lazy.filter { if case .news = $0 { return true } else { return false } }.count
    }

    private func stripPrefix(_ s: String, _ prefix: String) -> String? {
        s.hasPrefix(prefix) ? String(s.dropFirst(prefix.count)) : nil
    }
}

struct DropStats {
    let saved: Int
    let discarded: Int
    let deepened: Int
    let total: Int

    var signalPercent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(saved) / Double(total)) * 100.0)
    }
}
