import SwiftUI

struct EndScreen: View {
    let stats: DropStats
    let onReshuffle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TERMINASTE EL DROP")
                .font(.mono(11, weight: .regular))
                .kerning(1.6)
                .foregroundStyle(Theme.Color.no)
                .padding(.bottom, 14)

            Text("Listo.\nNo hay más por hoy.")
                .font(.bricolage(52, weight: .extraBold))
                .tracking(-1.8)
                .lineSpacing(-8)
                .foregroundStyle(Theme.Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 18)

            Text("Esto fue lo que importó en AI esta tarde. Si te quedaste con hambre, mala. Mañana hay más.")
                .font(.albert(16, weight: .regular))
                .lineSpacing(2)
                .foregroundStyle(Theme.Color.inkSoft)
                .frame(maxWidth: 320, alignment: .leading)
                .padding(.bottom, 28)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                statCell(value: "\(stats.saved)",     label: "guardadas",     valueColor: Theme.Color.yes)
                statCell(value: "\(stats.discarded)", label: "descartadas",   valueColor: Theme.Color.no)
                statCell(value: "\(stats.deepened)",  label: "profundizaste", valueColor: Theme.Color.ink)
                statCell(value: "\(stats.signalPercent)%", label: "señal de hoy", valueColor: Theme.Color.ink, suffixSmall: true)
            }
            .padding(.bottom, 28)

            Spacer(minLength: 0)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRÓXIMO DROP")
                        .font(.mono(10, weight: .regular))
                        .kerning(1.6)
                        .foregroundStyle(Theme.Color.hl)
                    Text("Mañana, 9:00")
                        .font(.bricolage(22, weight: .bold))
                        .tracking(-0.44)
                        .foregroundStyle(Theme.Color.paper)
                }
                Spacer()
                Button(action: onReshuffle) {
                    Text("REPETIR")
                        .font(.mono(11, weight: .regular))
                        .kerning(0.88)
                        .foregroundStyle(Theme.Color.paper)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().stroke(Theme.Color.paper.opacity(0.35), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Theme.Color.ink, in: RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func statCell(value: String, label: String, valueColor: Color, suffixSmall: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if suffixSmall, let pct = value.firstIndex(of: "%") {
                let num = String(value[..<pct])
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(num)
                        .font(.bricolage(38, weight: .extraBold))
                        .tracking(-1.14)
                    Text("%")
                        .font(.bricolage(18, weight: .extraBold))
                }
                .foregroundStyle(valueColor)
            } else {
                Text(value)
                    .font(.bricolage(38, weight: .extraBold))
                    .tracking(-1.14)
                    .foregroundStyle(valueColor)
            }
            Text(label.uppercased())
                .font(.mono(10, weight: .regular))
                .kerning(1.0)
                .foregroundStyle(Theme.Color.inkMute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.stat))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.stat)
                .stroke(Theme.Color.rule, lineWidth: 1)
        )
    }
}
