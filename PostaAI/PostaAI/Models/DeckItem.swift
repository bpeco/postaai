import Foundation

// Cosa que se muestra en el deck. Hoy son noticias y una card de continuación
// que separa "lo tuyo" de "también pasó hoy".
enum DeckItem: Identifiable, Equatable {
    case news(Card)
    case continuation

    var id: String {
        switch self {
        case .news(let c):    return c.id
        case .continuation:   return "__continuation__"
        }
    }
}
