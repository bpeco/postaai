import SwiftUI

struct DeckView: View {
    let items: [DeckItem]
    let alsoTodayRemaining: Int
    let onSwipe: (DeckItem, Decision) -> Void
    let onDeepen: (Card) -> Void

    var body: some View {
        let visible = Array(items.prefix(3))
        ZStack {
            ForEach(visible.reversed()) { item in
                let depth = visible.firstIndex(of: item) ?? 0
                cardLayer(item: item, depth: depth)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cardLayer(item: DeckItem, depth: Int) -> some View {
        let yOffset: CGFloat = depth == 0 ? 0 : (depth == 1 ? 8 : 16)
        let scale: CGFloat = depth == 0 ? 1.0 : (depth == 1 ? 0.96 : 0.92)
        return SwipeableLayer(
            onSwipe: { onSwipe(item, $0) },
            onTap: {
                if case .news(let card) = item { onDeepen(card) }
            },
            showStamps: depth == 0
        ) {
            contentFor(item)
        }
        .scaleEffect(scale)
        .offset(y: yOffset)
        .allowsHitTesting(depth == 0)
        .zIndex(10.0 - Double(depth))
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: depth)
    }

    @ViewBuilder
    private func contentFor(_ item: DeckItem) -> some View {
        switch item {
        case .news(let card):
            CardView(card: card)
        case .continuation:
            ContinuationCard(remaining: alsoTodayRemaining)
        }
    }
}
