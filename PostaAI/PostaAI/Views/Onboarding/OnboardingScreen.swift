import SwiftUI

struct OnboardingScreen: View {
    @Environment(AppViewModel.self) private var vm
    var onComplete: (() -> Void)? = nil

    private var temaItems: [ChipItem] {
        Vocabulary.temas.map { ChipItem(id: $0.slug, label: $0.label) }
    }
    private var entidadItems: [ChipItem] {
        Vocabulary.entidades.map { ChipItem(id: $0, label: $0) }
    }
    private var productoItems: [ChipItem] {
        Vocabulary.productos.map { ChipItem(id: $0, label: $0) }
    }

    private var canContinue: Bool { !vm.selectedTemas.isEmpty }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Color.paper.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    head

                    ChipSection(
                        title: "Tema",
                        subtitle: "Obligatorio",
                        items: temaItems,
                        selected: vm.selectedTemas,
                        onToggle: { vm.toggleTema($0) },
                        toggleAllAction: { vm.toggleAllTemas() }
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
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 140)
            }

            footer
        }
    }

    private var head: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BIENVENIDO")
                .font(.mono(10.5, weight: .regular))
                .kerning(1.7)
                .foregroundStyle(Theme.Color.inkMute)
            Text("Armá tu posta")
                .font(.bricolage(40, weight: .extraBold))
                .tracking(-1.2)
                .foregroundStyle(Theme.Color.ink)
            Text("Elegí qué te copa. Después se filtra la posta del día con eso.")
                .font(.albert(15, weight: .regular))
                .foregroundStyle(Theme.Color.inkSoft)
                .padding(.top, 2)
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Theme.Color.paper.opacity(0), Theme.Color.paper],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 28)
            .allowsHitTesting(false)

            VStack(spacing: 8) {
                Button {
                    if let onComplete { onComplete() } else { vm.completeOnboarding() }
                } label: {
                    Text(canContinue ? "Listo" : "Elegí al menos un tema")
                        .font(.albert(16, weight: .semiBold))
                        .foregroundStyle(canContinue ? Theme.Color.paper : Theme.Color.inkMute)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(canContinue ? Theme.Color.ink : Theme.Color.paperDeep)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canContinue)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
            .padding(.top, 8)
            .background(Theme.Color.paper)
        }
    }
}
