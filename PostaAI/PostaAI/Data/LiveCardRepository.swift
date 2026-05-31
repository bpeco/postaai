import Foundation

// Fetch del Pool real desde el CDN. URL hardcodeada — TODO migrar a
// `cdn.postaai.app` cuando arranque el custom domain (Etapa 6).
struct LiveCardRepository: CardRepository {
    static let poolURL = URL(string: "https://postaai-content.vercel.app/latest.json")!

    func fetchTodayDrop() async throws -> Drop {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: Self.poolURL)
        } catch {
            print("LiveCardRepository: network error fetching latest.json — \(error)")
            throw CardRepositoryError.network(underlying: error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            print("LiveCardRepository: invalid content — HTTP \(http.statusCode)")
            throw CardRepositoryError.invalidContent(underlying: nil)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(Drop.self, from: data)
        } catch {
            print("LiveCardRepository: decode failed — \(error)")
            throw CardRepositoryError.invalidContent(underlying: error)
        }
    }
}
