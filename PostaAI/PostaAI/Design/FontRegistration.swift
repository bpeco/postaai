import CoreText
import Foundation

enum FontRegistration {
    private static let files = [
        "BricolageGrotesque-SemiBold",
        "BricolageGrotesque-Bold",
        "BricolageGrotesque-ExtraBold",
        "AlbertSans-Regular",
        "AlbertSans-Medium",
        "AlbertSans-SemiBold",
        "AlbertSans-Bold",
        "JetBrainsMono-Regular",
        "JetBrainsMono-Medium",
        "JetBrainsMono-Bold",
    ]

    // Runtime fallback registration. Info.plist UIAppFonts is the primary path;
    // this catches the rare case where a font file ships but isn't listed.
    static func registerOnce() {
        for name in files {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            var error: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }
}
