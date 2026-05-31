import SwiftUI

// Capa genérica que aplica los gestos de swipe (left = paso / right = guardo)
// + double-tap-to-deepen sobre cualquier contenido. Usada por el deck real y
// por el tutorial (CoachTutorial), que restringe los gestos vía
// `allowedDirections` y `allowsTap`.
struct SwipeableLayer<Content: View>: View {
    let onSwipe: (Decision) -> Void
    let onTap: () -> Void
    let showStamps: Bool
    let allowedDirections: Set<Decision>?  // nil = sin restricción
    let allowsTap: Bool
    @ViewBuilder let content: () -> Content

    @State private var dragOffset: CGSize = .zero
    @State private var exitOffset: CGSize? = nil
    @State private var isExiting = false
    @State private var lastTap: Date = .distantPast

    private let swipeThreshold: CGFloat = 80
    private let predictedThreshold: CGFloat = 200

    init(
        onSwipe: @escaping (Decision) -> Void,
        onTap: @escaping () -> Void = {},
        showStamps: Bool = true,
        allowedDirections: Set<Decision>? = nil,
        allowsTap: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onSwipe = onSwipe
        self.onTap = onTap
        self.showStamps = showStamps
        self.allowedDirections = allowedDirections
        self.allowsTap = allowsTap
        self.content = content
    }

    private var rotation: Double {
        let base = (exitOffset?.width ?? dragOffset.width) * 0.04
        return Double(max(-30, min(30, base)))
    }
    private var currentOffset: CGSize {
        exitOffset ?? dragOffset
    }

    private func isAllowed(_ decision: Decision) -> Bool {
        guard let allowed = allowedDirections else { return true }
        return allowed.contains(decision)
    }

    var body: some View {
        ZStack {
            content()
            if showStamps {
                SwipeStamps(dragX: currentOffset.width)
            }
        }
        .opacity(isExiting ? 0 : 1)
        .offset(currentOffset)
        .rotationEffect(.degrees(rotation), anchor: .center)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard exitOffset == nil else { return }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard exitOffset == nil else { return }
                    let dx = value.translation.width
                    let predicted = value.predictedEndTranslation.width
                    let moved = hypot(value.translation.width, value.translation.height) > 6

                    if !moved {
                        let now = Date()
                        if now.timeIntervalSince(lastTap) < 0.32 {
                            lastTap = .distantPast
                            if allowsTap { onTap() }
                        } else {
                            lastTap = now
                        }
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            dragOffset = .zero
                        }
                        return
                    }

                    let intendedDirection: Decision = dx > 0 ? .save : .discard
                    let crossedThreshold = abs(dx) > swipeThreshold || abs(predicted) > predictedThreshold

                    if crossedThreshold && isAllowed(intendedDirection) {
                        flyOut(direction: intendedDirection, anchorY: value.translation.height)
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }

    private func flyOut(direction: Decision, anchorY: CGFloat) {
        let screenWidth = UIScreen.main.bounds.width
        let target = CGSize(
            width: direction == .save ? screenWidth * 1.5 : -screenWidth * 1.5,
            height: anchorY
        )
        withAnimation(.easeIn(duration: 0.42)) {
            exitOffset = target
            isExiting = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            onSwipe(direction)
        }
    }
}
