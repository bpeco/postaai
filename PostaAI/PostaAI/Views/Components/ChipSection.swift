import SwiftUI

struct ChipItem: Identifiable, Hashable {
    let id: String         // value (slug o nombre canónico)
    let label: String      // display
}

// Sección reutilizable usada por OnboardingScreen y SettingsScreen.
// - title: encabezado de la sección
// - subtitle: tag chico al lado del título ("Obligatorio" / "Opcional")
// - items: chips a renderizar
// - selected: ids actualmente seleccionados
// - onToggle: callback con el id tocado
// - isCollapsible: si true, arranca colapsada (un chevron expande)
// - primaryAction: botón opcional al lado del título ("Sorprendeme")
struct ChipSection: View {
    let title: String
    var subtitle: String? = nil
    let items: [ChipItem]
    let selected: Set<String>
    let onToggle: (String) -> Void
    var isCollapsible: Bool = false
    // Si está presente, dibuja un botón "Todo" / "Ninguno" al lado del título.
    // El label lo computa este componente según el estado de `selected`.
    var toggleAllAction: (() -> Void)? = nil

    @State private var expanded: Bool = false

    private var showChips: Bool { !isCollapsible || expanded }
    private var allSelected: Bool {
        !items.isEmpty && selected.count == items.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if showChips {
                FlowLayout(spacing: 8) {
                    ForEach(items) { item in
                        chip(item)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title.uppercased())
                .font(.mono(11, weight: .medium))
                .kerning(1.4)
                .foregroundStyle(Theme.Color.ink)
            if let subtitle {
                Text(subtitle.uppercased())
                    .font(.mono(9, weight: .regular))
                    .kerning(1.2)
                    .foregroundStyle(Theme.Color.inkMute)
            }
            Spacer()
            if isCollapsible {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Color.inkSoft)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            if let toggleAllAction {
                Button(action: toggleAllAction) {
                    Text(allSelected ? "Ninguno" : "Todo")
                        .font(.mono(10, weight: .medium))
                        .kerning(0.6)
                        .foregroundStyle(Theme.Color.brand)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .overlay(
                            Capsule().stroke(Theme.Color.brand, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func chip(_ item: ChipItem) -> some View {
        let on = selected.contains(item.id)
        return Button {
            onToggle(item.id)
        } label: {
            Text(item.label)
                .font(.mono(11, weight: .regular))
                .kerning(0.4)
                .foregroundStyle(on ? Theme.Color.paper : Theme.Color.ink)
                .padding(.vertical, 7)
                .padding(.horizontal, 11)
                .background(
                    Capsule()
                        .fill(on ? Theme.Color.ink : Theme.Color.paper)
                )
                .overlay(
                    Capsule().stroke(on ? Theme.Color.ink : Theme.Color.rule, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
