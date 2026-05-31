import SwiftUI

// Contenido roto (404, JSON malformed) + sin caché. Pasivo — no hay retry
// porque el problema está del otro lado (Pool corrupto). El usuario espera.
struct BrokenContentScreen: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("PROBLEMA TÉCNICO")
                .font(.mono(11, weight: .medium))
                .kerning(2.0)
                .foregroundStyle(Theme.Color.no)
            Text("Tuvimos un\nproblema con el\ndrop de hoy.")
                .font(.bricolage(36, weight: .extraBold))
                .tracking(-1.08)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.ink)
            Text("Vení en un rato — lo estamos arreglando del lado nuestro.")
                .font(.albert(15, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.inkSoft)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
