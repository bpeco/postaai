import SwiftUI

struct TagPill: View {
    let card: Card
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.color(for: card.tag))
                .frame(width: 8, height: 8)
            Text(card.tag)
                .font(.mono(compact ? 10 : 11, weight: .medium))
                .kerning(0.6)
                .foregroundStyle(Theme.Color.ink)
        }
        .padding(.vertical, 6)
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .background(Theme.Color.paperDeep, in: Capsule())
    }
}
