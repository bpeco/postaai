import SwiftUI

struct SettingsScreen: View {
    @Environment(AppViewModel.self) private var vm

    private var temaItems: [ChipItem] {
        Vocabulary.temas.map { ChipItem(id: $0.slug, label: $0.label) }
    }
    private var entidadItems: [ChipItem] {
        Vocabulary.entidades.map { ChipItem(id: $0, label: $0) }
    }
    private var productoItems: [ChipItem] {
        Vocabulary.productos.map { ChipItem(id: $0, label: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    groupLabel("Drops")
                    group {
                        row(label: "Mañana", value: "9:00 hs", isLast: false)
                        row(label: "Tarde",  value: "18:00 hs", isLast: false)
                        row(label: "Notificaciones", value: "activas", isLast: true)
                    }

                    groupLabel("Intereses")
                    group {
                        VStack(alignment: .leading, spacing: 22) {
                            ChipSection(
                                title: "Tema",
                                subtitle: "Obligatorio",
                                items: temaItems,
                                selected: vm.selectedTemas,
                                onToggle: { vm.toggleTema($0) }
                            )
                            ChipSection(
                                title: "Entidad",
                                subtitle: "Opcional",
                                items: entidadItems,
                                selected: vm.selectedEntidades,
                                onToggle: { vm.toggleEntidad($0) }
                            )
                            ChipSection(
                                title: "Producto",
                                subtitle: "Opcional",
                                items: productoItems,
                                selected: vm.selectedProductos,
                                onToggle: { vm.toggleProducto($0) },
                                isCollapsible: true
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }

                    groupLabel("Cuenta")
                    group {
                        row(label: "Plan",    value: "Posta Pro", isLast: false)
                        row(label: "Idioma",  value: "Español (AR)", isLast: false)
                        row(label: "Versión", value: "1.4.0", isLast: true)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var head: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AJUSTES")
                .font(.mono(10.5, weight: .regular))
                .kerning(1.7)
                .foregroundStyle(Theme.Color.inkMute)
            Text("Tu posta diaria")
                .font(.bricolage(36, weight: .extraBold))
                .tracking(-1.08)
                .foregroundStyle(Theme.Color.ink)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func groupLabel(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.mono(10, weight: .regular))
            .kerning(1.6)
            .foregroundStyle(Theme.Color.inkMute)
            .padding(.top, 18)
            .padding(.bottom, 8)
            .padding(.leading, 4)
    }

    @ViewBuilder
    private func group<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0) { content() }
            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.stat))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.stat)
                    .stroke(Theme.Color.rule, lineWidth: 1)
            )
    }

    private func row(label: String, value: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.albert(15, weight: .medium))
                    .foregroundStyle(Theme.Color.ink)
                Spacer()
                Text(value)
                    .font(.mono(13, weight: .regular))
                    .foregroundStyle(Theme.Color.inkMute)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            if !isLast {
                Rectangle().fill(Theme.Color.rule).frame(height: 1)
            }
        }
    }
}
