import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Head: tag (+ producto opcional) + kind
            HStack(alignment: .center, spacing: 8) {
                TagPill(card: card)
                if let product = card.product {
                    Text(product)
                        .font(.mono(11, weight: .regular))
                        .kerning(0.4)
                        .foregroundStyle(Theme.Color.inkSoft)
                        .lineLimit(1)
                }
                Spacer()
                Text((card.kind.first ?? "").uppercased())
                    .font(.mono(10, weight: .regular))
                    .kerning(1.2)
                    .foregroundStyle(Theme.Color.inkMute)
            }
            .padding(.bottom, 18)

            // Headline
            Text(card.headline)
                .font(.bricolage(30, weight: .bold))
                .tracking(-0.75)
                .lineSpacing(-2)
                .foregroundStyle(Theme.Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 22)

            // Take block — top divider dashed
            VStack(alignment: .leading, spacing: 10) {
                Text("EL TAKE")
                    .font(.mono(10, weight: .regular))
                    .kerning(1.6)
                    .foregroundStyle(Theme.Color.no)
                Text(card.take)
                    .font(.albert(17, weight: .medium))
                    .lineSpacing(3)
                    .foregroundStyle(Theme.Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .overlay(alignment: .top) {
                DashedDivider(color: Theme.Color.rule)
            }

            Spacer(minLength: 8)

            // Foot
            HStack {
                Text(card.relativeMeta)
                    .font(.mono(11, weight: .regular))
                    .kerning(0.4)
                    .foregroundStyle(Theme.Color.inkMute)
                Spacer()
                DeepenHint()
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.Color.rule).frame(height: 1)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Color.rule, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 0, x: 0, y: 1)
        .shadow(color: .black.opacity(0.10), radius: 40, x: 0, y: 16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct DashedDivider: View {
    var color: Color = Theme.Color.rule
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 1)
            .overlay(
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(color)
                    .frame(height: 1)
            )
    }
}
