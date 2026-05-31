import Foundation

struct MockCardRepository: CardRepository {
    func fetchTodayDrop() async throws -> Drop {
        guard let url = Bundle.main.url(forResource: "PostaDrop", withExtension: "json") else {
            throw CardRepositoryError.missingResource("PostaDrop.json")
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Drop.self, from: data)
        } catch {
            throw CardRepositoryError.decodeFailed(underlying: error)
        }
    }
}
