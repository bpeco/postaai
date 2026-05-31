import Foundation

// Vocabularios canónicos del MVP. Espejados con ai-digest/prompts/cards.md.
// Si esto cambia, también cambia el prompt — son contrato compartido.
enum Vocabulary {
    // Los 9 Temas (slug, label). Slug matchea con Card.kind del Pool.
    static let temas: [(slug: String, label: String)] = [
        ("modelos",     "Modelos"),
        ("codigo",      "Código / devtools"),
        ("agentes",     "Agentes"),
        ("research",    "Research / papers"),
        ("open-source", "Open source / local"),
        ("negocio",     "Negocio / plata"),
        ("robots",      "Hardware / robots"),
        ("regulacion",  "Regulación / política"),
        ("producto",    "Producto / apps"),
    ]

    // Las 12 Entidades seguibles. Strings literales que matchean Card.tag.
    static let entidades: [String] = [
        "OpenAI", "Anthropic", "Google DeepMind", "Meta",
        "Microsoft", "Mistral", "xAI", "Hugging Face",
        "DeepSeek", "Nvidia", "Apple", "Amazon",
    ]

    // Los 10 Productos seguibles. Strings literales que matchean Card.product.
    static let productos: [String] = [
        "Claude Code", "Claude Desktop", "ChatGPT", "Codex",
        "Cursor", "Copilot", "Gemini app", "Perplexity",
        "v0", "Windsurf",
    ]

    static func label(forTemaSlug slug: String) -> String {
        temas.first { $0.slug == slug }?.label ?? slug
    }
}

// Prefijos usados en el Set<String> persistido en UserDefaults (postaai.interests).
// Conviven en un solo set para minimizar churn en Persistence y AppViewModel.
enum InterestPrefix {
    static let tema     = "tema:"
    static let org      = "org:"
    static let producto = "producto:"

    static func tema(_ slug: String) -> String     { tema + slug }
    static func org(_ name: String) -> String      { org + name }
    static func producto(_ name: String) -> String { producto + name }
}
