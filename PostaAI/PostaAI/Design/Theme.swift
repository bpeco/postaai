import SwiftUI

enum Theme {
    enum Color {
        static let paper      = SwiftUI.Color(hex: 0xF1ECDF)
        static let paperDeep  = SwiftUI.Color(hex: 0xE8E2D2)
        static let surface    = SwiftUI.Color(hex: 0xFFFEFA)
        static let ink        = SwiftUI.Color(hex: 0x15110A)
        static let inkSoft    = SwiftUI.Color(hex: 0x5B5346)
        static let inkMute    = SwiftUI.Color(hex: 0x8C8470)
        static let brand      = SwiftUI.Color(hex: 0x2D4FFF)
        static let yes        = SwiftUI.Color(hex: 0x2BB673)
        static let no         = SwiftUI.Color(hex: 0xEF4423)
        static let hl         = SwiftUI.Color(hex: 0xFFD23F)
        static let rule       = SwiftUI.Color(hex: 0x15110A, alpha: 0.10)
        static let pageBg     = SwiftUI.Color(hex: 0x1A1813)
    }

    enum Radius {
        static let card: CGFloat       = 24
        static let detailBox: CGFloat  = 18
        static let stat: CGFloat       = 16
        static let chip: CGFloat       = 999
        static let stamp: CGFloat      = 10
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    init?(hexString: String) {
        let trimmed = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard let value = UInt32(trimmed, radix: 16) else { return nil }
        self.init(hex: value)
    }
}

// Typography — PostScript-named custom fonts. Falls back to system if registration failed.
extension Font {
    static func bricolage(_ size: CGFloat, weight: BricolageWeight = .extraBold) -> Font {
        Font.custom(weight.postScriptName, size: size).weight(weight.swiftUI)
    }
    static func albert(_ size: CGFloat, weight: AlbertWeight = .regular) -> Font {
        Font.custom(weight.postScriptName, size: size).weight(weight.swiftUI)
    }
    static func mono(_ size: CGFloat, weight: MonoWeight = .regular) -> Font {
        Font.custom(weight.postScriptName, size: size).weight(weight.swiftUI)
    }

    enum BricolageWeight {
        case semiBold, bold, extraBold
        var postScriptName: String {
            switch self {
            case .semiBold:  return "BricolageGrotesque-SemiBold"
            case .bold:      return "BricolageGrotesque-Bold"
            case .extraBold: return "BricolageGrotesque-ExtraBold"
            }
        }
        var swiftUI: Font.Weight {
            switch self {
            case .semiBold:  return .semibold
            case .bold:      return .bold
            case .extraBold: return .heavy
            }
        }
    }

    enum AlbertWeight {
        case regular, medium, semiBold, bold
        var postScriptName: String {
            switch self {
            case .regular:  return "AlbertSans-Regular"
            case .medium:   return "AlbertSans-Medium"
            case .semiBold: return "AlbertSans-SemiBold"
            case .bold:     return "AlbertSans-Bold"
            }
        }
        var swiftUI: Font.Weight {
            switch self {
            case .regular:  return .regular
            case .medium:   return .medium
            case .semiBold: return .semibold
            case .bold:     return .bold
            }
        }
    }

    enum MonoWeight {
        case regular, medium, bold
        var postScriptName: String {
            switch self {
            case .regular: return "JetBrainsMono-Regular"
            case .medium:  return "JetBrainsMono-Medium"
            case .bold:    return "JetBrainsMono-Bold"
            }
        }
        var swiftUI: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium:  return .medium
            case .bold:    return .bold
            }
        }
    }
}
