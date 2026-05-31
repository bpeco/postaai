import SwiftUI

// Sin red + sin caché. Mostrá copy + botón Reintentar.
struct ErrorScreen: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("SIN RED")
                .font(.mono(11, weight: .medium))
                .kerning(2.0)
                .foregroundStyle(Theme.Color.no)
            Text("No pudimos\ntraer el drop.")
                .font(.bricolage(40, weight: .extraBold))
                .tracking(-1.2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.ink)
            Text("Fijate la conexión y dale reintentar.")
                .font(.albert(15, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.inkSoft)
                .padding(.horizontal, 32)
            Button(action: onRetry) {
                Text("Reintentar")
                    .font(.albert(16, weight: .semiBold))
                    .foregroundStyle(Theme.Color.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Theme.Color.ink)
                    )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 220)
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
