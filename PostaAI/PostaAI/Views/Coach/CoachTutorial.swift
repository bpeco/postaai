import SwiftUI

// Tutorial interactivo. 3 mini-cards swipeable que enseñan los gestos
// haciéndolos, no leyéndolos. Reemplaza al viejo CoachOverlay (modal pasivo).
struct CoachTutorial: View {
    let onComplete: () -> Void

    @State private var stepIndex: Int = 0
    @State private var card3DetailShown: Bool = false

    private let steps: [CoachStep] = [.swipeRight, .swipeLeft, .doubleTap]

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { }  // intercepta taps al fondo (no dismissea)

            ZStack {
                ForEach((stepIndex..<3).reversed(), id: \.self) { i in
                    cardLayer(at: i)
                }
            }
            .frame(maxWidth: 360, maxHeight: 460)
            .padding(.horizontal, 22)
        }
        .transition(.opacity)
    }

    private func cardLayer(at i: Int) -> some View {
        let depth = i - stepIndex
        let yOffset: CGFloat = depth == 0 ? 0 : (depth == 1 ? 8 : 16)
        let scale: CGFloat   = depth == 0 ? 1.0 : (depth == 1 ? 0.96 : 0.92)
        let step = steps[i]
        let isTop = depth == 0

        return SwipeableLayer(
            onSwipe: { _ in advance() },
            onTap: {
                if step == .doubleTap && !card3DetailShown {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        card3DetailShown = true
                    }
                }
            },
            showStamps: false,
            allowedDirections: allowedFor(step),
            allowsTap: step == .doubleTap
        ) {
            tutorialCardContent(step: step, isTop: isTop)
        }
        .scaleEffect(scale)
        .offset(y: yOffset)
        .allowsHitTesting(isTop)
        .zIndex(10.0 - Double(depth))
        .animation(.spring(response: 0.42, dampingFraction: 0.85), value: depth)
    }

    private func allowedFor(_ step: CoachStep) -> Set<Decision>? {
        switch step {
        case .swipeRight: return [.save]
        case .swipeLeft:  return [.discard]
        case .doubleTap:  return card3DetailShown ? nil : []
        }
    }

    private func advance() {
        stepIndex += 1
        card3DetailShown = false
        if stepIndex >= steps.count {
            onComplete()
        }
    }

    @ViewBuilder
    private func tutorialCardContent(step: CoachStep, isTop: Bool) -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(step.chip)
                        .font(.mono(11, weight: .medium))
                        .kerning(0.6)
                        .foregroundStyle(Theme.Color.ink)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Theme.Color.hl, in: Capsule())
                    Spacer()
                    Text("\(steps.firstIndex(of: step)! + 1)/3")
                        .font(.mono(10, weight: .regular))
                        .kerning(1.2)
                        .foregroundStyle(Theme.Color.inkMute)
                }
                .padding(.bottom, 22)

                Text(step.headline)
                    .font(.bricolage(30, weight: .extraBold))
                    .tracking(-0.9)
                    .foregroundStyle(Theme.Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    step.symbolView
                    Spacer()
                }

                Spacer(minLength: 0)

                DashedDivider(color: Theme.Color.rule)
                Text("Probá ahora")
                    .font(.mono(10.5, weight: .medium))
                    .kerning(0.9)
                    .foregroundStyle(Theme.Color.inkMute)
                    .padding(.top, 10)
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Color.rule, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 40, x: 0, y: 16)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

            if step == .doubleTap && card3DetailShown && isTop {
                detailOverlay
            }
        }
    }

    private var detailOverlay: some View {
        VStack(spacing: 12) {
            Text("ESTO ES EL DETALLE")
                .font(.mono(11, weight: .medium))
                .kerning(1.6)
                .foregroundStyle(Theme.Color.brand)
            Text("Ahora sí,\nswipeá.")
                .font(.bricolage(30, weight: .extraBold))
                .tracking(-0.9)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.ink)
            Text("← o →    da igual")
                .font(.mono(11, weight: .regular))
                .kerning(0.8)
                .foregroundStyle(Theme.Color.inkSoft)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(Theme.Color.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.Color.ink, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}

enum CoachStep: Hashable {
    case swipeRight, swipeLeft, doubleTap

    var chip: String {
        switch self {
        case .swipeRight: return "ARRANCAMOS"
        case .swipeLeft:  return "SEGUIMOS"
        case .doubleTap:  return "ÚLTIMA"
        }
    }

    var headline: String {
        switch self {
        case .swipeRight: return "Tirá a la derecha\nsi te importa."
        case .swipeLeft:  return "Tirá a la izquierda\nsi la pasás."
        case .doubleTap:  return "Doble tap para\nprofundizar."
        }
    }

    @ViewBuilder
    var symbolView: some View {
        switch self {
        case .swipeRight:
            Text("→")
                .font(.bricolage(110, weight: .extraBold))
                .foregroundStyle(Theme.Color.yes)
        case .swipeLeft:
            Text("←")
                .font(.bricolage(110, weight: .extraBold))
                .foregroundStyle(Theme.Color.no)
        case .doubleTap:
            HStack(spacing: 14) {
                Circle()
                    .fill(Theme.Color.brand)
                    .frame(width: 44, height: 44)
                Circle()
                    .fill(Theme.Color.brand)
                    .frame(width: 44, height: 44)
            }
        }
    }
}
