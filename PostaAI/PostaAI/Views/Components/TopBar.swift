import SwiftUI

struct TopBar: View {
    let edition: String
    let activeTab: AppTab
    var isOffline: Bool = false
    let onArchive: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(edition.uppercased())
                        .font(.mono(10, weight: .regular))
                        .kerning(1.2)
                        .foregroundStyle(Theme.Color.inkSoft)
                    if isOffline {
                        Text("SIN RED")
                            .font(.mono(9, weight: .medium))
                            .kerning(1.0)
                            .foregroundStyle(Theme.Color.no)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .overlay(
                                Capsule().stroke(Theme.Color.no, lineWidth: 1)
                            )
                    }
                }
                BrandWordmark(size: 26)
            }
            Spacer()
            HStack(spacing: 8) {
                IconButton(icon: .bookmark, active: activeTab == .archive, action: onArchive)
                IconButton(icon: .settings, active: activeTab == .settings, action: onSettings)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }
}

struct BrandWordmark: View {
    var size: CGFloat = 26
    var body: some View {
        HStack(spacing: 0) {
            Text("posta")
                .font(.bricolage(size, weight: .extraBold))
                .tracking(-size * 0.03)
                .foregroundStyle(Theme.Color.ink)
            Text(".")
                .font(.bricolage(size, weight: .extraBold))
                .foregroundStyle(Theme.Color.no)
        }
        .lineLimit(1)
    }
}
