import SwiftUI

struct PausedScreen: View {
    let message: String?

    private var copy: String {
        message ?? "Hoy no hay drop nuevo. Volvemos en la próxima edición — quedate piola."
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("EN PAUSA")
                .font(.mono(11, weight: .medium))
                .kerning(2.0)
                .foregroundStyle(Theme.Color.no)
            Text(copy)
                .font(.albert(17, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.ink)
                .padding(.horizontal, 36)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
