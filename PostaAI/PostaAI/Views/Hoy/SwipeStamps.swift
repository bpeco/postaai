import SwiftUI

struct SwipeStamps: View {
    let dragX: CGFloat

    private var pasoOpacity: Double {
        let raw = (-dragX - 30) / 90
        return min(1, max(0, Double(raw)))
    }
    private var guardoOpacity: Double {
        let raw = (dragX - 30) / 90
        return min(1, max(0, Double(raw)))
    }

    var body: some View {
        ZStack {
            HStack {
                stamp(text: "Paso", color: Theme.Color.no, rotation: -14)
                    .opacity(pasoOpacity)
                    .padding(.leading, 22)
                Spacer()
                stamp(text: "Guardo", color: Theme.Color.yes, rotation: 12)
                    .opacity(guardoOpacity)
                    .padding(.trailing, 22)
            }
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    private func stamp(text: String, color: Color, rotation: Double) -> some View {
        Text(text.uppercased())
            .font(.bricolage(38, weight: .extraBold))
            .tracking(-0.76)
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.stamp)
                    .stroke(color, lineWidth: 3)
            )
            .rotationEffect(.degrees(rotation))
    }
}
