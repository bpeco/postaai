import Foundation

struct Drop: Codable, Equatable {
    let date: String
    let edition: String
    let number: Int
    let status: String              // "published" | "paused" — kill-switch del Pool (ver MVP hilo E)
    let pauseMessage: String?       // mensaje a mostrar cuando status == "paused"
    let cards: [Card]

    enum CodingKeys: String, CodingKey {
        case date, edition, number, status, cards
        case pauseMessage = "pause_message"
    }
}
