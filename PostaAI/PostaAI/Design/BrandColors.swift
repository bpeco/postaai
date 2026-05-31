import SwiftUI

// Mapa Entidad → brand color para las orgs seguibles del MVP (hilo A).
// Para entidades fuera del mapa (nicho como Figure, Stainless, etc.) usamos el gris neutro.
// Ver docs/MVP.md hilo B: el color lo resuelve la app, no el generador.
enum BrandColors {
    static let neutralGray = SwiftUI.Color(hex: 0x8C8470)

    static let map: [String: SwiftUI.Color] = [
        "OpenAI":          SwiftUI.Color(hex: 0x10A37F),
        "Anthropic":       SwiftUI.Color(hex: 0xD77757),
        "Google DeepMind": SwiftUI.Color(hex: 0x4285F4),
        "Google":          SwiftUI.Color(hex: 0x4285F4),
        "Meta":            SwiftUI.Color(hex: 0x0866FF),
        "Microsoft":       SwiftUI.Color(hex: 0x00A4EF),
        "Mistral":         SwiftUI.Color(hex: 0xFF7000),
        "xAI":             SwiftUI.Color(hex: 0x1A1A1A),
        "Hugging Face":    SwiftUI.Color(hex: 0xFFD21E),
        "DeepSeek":        SwiftUI.Color(hex: 0x4D6BFE),
        "Nvidia":          SwiftUI.Color(hex: 0x76B900),
        "Apple":           SwiftUI.Color(hex: 0x1D1D1F),
        "Amazon":          SwiftUI.Color(hex: 0xFF9900)
    ]
}

extension Theme {
    static func color(for tag: String) -> SwiftUI.Color {
        BrandColors.map[tag] ?? BrandColors.neutralGray
    }
}
