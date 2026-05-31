import Foundation

protocol CardRepository {
    func fetchTodayDrop() async throws -> Drop
}

enum CardRepositoryError: Error {
    case missingResource(String)
    case decodeFailed(underlying: Error)
    case network(underlying: Error)         // sin red, timeout, DNS, HTTP error
    case invalidContent(underlying: Error?) // 404, JSON malformed — diferenciado de decode para UX

    // Categoría para que AppViewModel elija ErrorScreen vs BrokenContentScreen.
    var isNetworkBucket: Bool {
        if case .network = self { return true }
        return false
    }
}
