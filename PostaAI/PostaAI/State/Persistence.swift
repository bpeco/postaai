import Foundation

struct Persistence {
    private let defaults: UserDefaults
    private let coachKey         = "postaai.hasSeenCoach"
    private let savedIdsKey      = "postaai.savedIds"
    private let interestsKey     = "postaai.interests"
    private let onboardingKey    = "postaai.hasCompletedOnboarding"
    private let cachedPoolKey    = "postaai.cachedPool"
    private let lastFetchedAtKey = "postaai.lastFetchedAt"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasSeenCoach: Bool {
        get { defaults.bool(forKey: coachKey) }
        nonmutating set { defaults.set(newValue, forKey: coachKey) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: onboardingKey) }
        nonmutating set { defaults.set(newValue, forKey: onboardingKey) }
    }

    func loadSavedIds() -> Set<String> {
        guard
            let raw = defaults.data(forKey: savedIdsKey),
            let arr = try? JSONDecoder().decode([String].self, from: raw)
        else { return [] }
        return Set(arr)
    }

    func saveSavedIds(_ ids: Set<String>) {
        let arr = Array(ids).sorted()
        if let data = try? JSONEncoder().encode(arr) {
            defaults.set(data, forKey: savedIdsKey)
        }
    }

    func loadInterests() -> Set<String>? {
        guard
            let raw = defaults.data(forKey: interestsKey),
            let arr = try? JSONDecoder().decode([String].self, from: raw)
        else { return nil }
        return Set(arr)
    }

    func saveInterests(_ values: Set<String>) {
        let arr = Array(values).sorted()
        if let data = try? JSONEncoder().encode(arr) {
            defaults.set(data, forKey: interestsKey)
        }
    }

    // ── Pool cache (Etapa 4) ─────────────────────────────────────────────
    //
    // Solo guardamos Drops con `status == "published"` — un `paused` no debe pisar
    // el caché bueno (regla del MVP, decisión #7 del grill). Esa lógica vive en
    // AppViewModel, acá Persistence solo es storage.

    func loadCachedDrop() -> Drop? {
        guard let raw = defaults.data(forKey: cachedPoolKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Drop.self, from: raw)
    }

    func saveCachedDrop(_ drop: Drop) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(drop) {
            defaults.set(data, forKey: cachedPoolKey)
        }
    }

    func clearCachedPool() {
        defaults.removeObject(forKey: cachedPoolKey)
    }

    var lastFetchedAt: Date? {
        get { defaults.object(forKey: lastFetchedAtKey) as? Date }
        nonmutating set { defaults.set(newValue, forKey: lastFetchedAtKey) }
    }
}
