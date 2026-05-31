import SwiftUI

// Card divisora entre "lo tuyo" y "también pasó hoy". Tiene la misma
// silueta que CardView (padding, radius, border, shadow) para que se
// sienta parte del deck — el contenido es la pregunta de continuar.
struct ContinuationCard: View {
    let remaining: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Head: chip "MÁS POSTA" + label de la derecha
            HStack(alignment: .center) {
                Text("MÁS POSTA")
                    .font(.mono(11, weight: .medium))
                    .kerning(0.6)
                    .foregroundStyle(Theme.Color.ink)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Theme.Color.hl, in: Capsule())
                Spacer()
                Text("TAMBIÉN")
                    .font(.mono(10, weight: .regular))
                    .kerning(1.2)
                    .foregroundStyle(Theme.Color.inkMute)
            }
            .padding(.bottom, 22)

            // Headline
            Text("¿Seguís?")
                .font(.bricolage(48, weight: .extraBold))
                .tracking(-1.4)
                .foregroundStyle(Theme.Color.ink)
                .padding(.bottom, 18)

            // Body
            Text(bodyText)
                .font(.albert(17, weight: .medium))
                .lineSpacing(3)
                .foregroundStyle(Theme.Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            // Footer hint del gesto
            VStack(spacing: 8) {
                DashedDivider(color: Theme.Color.rule)
                HStack {
                    Text("IZQUIERDA = CORTAR")
                        .font(.mono(10.5, weight: .medium))
                        .kerning(0.9)
                        .foregroundStyle(Theme.Color.no)
                    Spacer()
                    Text("DERECHA = SEGUIR")
                        .font(.mono(10.5, weight: .medium))
                        .kerning(0.9)
                        .foregroundStyle(Theme.Color.yes)
                }
            }
            .padding(.top, 12)
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

    private var bodyText: String {
        let plural = remaining == 1 ? "noticia más" : "noticias más"
        return "Eso fue tu posta. Hay \(remaining) \(plural) que pasaron hoy y no matchean tu interés directo."
    }
}
