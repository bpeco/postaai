import Foundation

struct Card: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let tag: String                 // Entidad (org) — display abierto, color se resuelve en la app
    let headline: String
    let take: String                // short editorial hook shown on the card
    let context: String             // full background, shown in detail
    let editorial: String           // El take de Posta — featured in dark box
    let source: String
    let sourceLabel: String
    let publishedAt: Date           // ISO 8601 del item original; render relativo lo hace la app
    let kind: [String]              // 1-2 Temas (slugs del vocabulario: modelos, codigo, agentes, ...)
    let product: String?            // opcional: producto seguible (Claude Code, ChatGPT, ...)

    enum CodingKeys: String, CodingKey {
        case id, tag, headline, take, context, editorial, source, sourceLabel, kind, product
        case publishedAt = "published_at"
    }
}

extension Card {
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "es_AR")
        f.unitsStyle = .full
        return f
    }()

    // "hace 6 horas", "hace 2 días", "hoy", etc. Computado contra Date() actual.
    var relativeMeta: String {
        Self.relativeFormatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}
