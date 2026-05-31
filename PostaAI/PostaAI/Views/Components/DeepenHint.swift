import SwiftUI

struct DeepenHint: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Theme.Color.brand.opacity(0.5), lineWidth: 1)
                    .frame(width: pulse ? 24 : 8, height: pulse ? 24 : 8)
                    .opacity(pulse ? 0 : 0.6)
                Circle()
                    .fill(Theme.Color.brand)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 24, height: 24)
            Text("doble tap → más")
                .font(.mono(10.5, weight: .regular))
                .kerning(0.6)
                .foregroundStyle(Theme.Color.inkMute)
                .textCase(.uppercase)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}
