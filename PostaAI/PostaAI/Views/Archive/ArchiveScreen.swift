import SwiftUI

struct ArchiveScreen: View {
    @Environment(AppViewModel.self) private var vm

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            if vm.savedCards.isEmpty {
                Spacer()
                emptyState
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.savedCards) { card in
                            Button {
                                vm.deepen(card)
                            } label: {
                                ArchiveItem(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var head: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ARCHIVO")
                .font(.mono(10.5, weight: .regular))
                .kerning(1.7)
                .foregroundStyle(Theme.Color.inkMute)
            Text("Lo que guardaste")
                .font(.bricolage(36, weight: .extraBold))
                .tracking(-1.08)
                .foregroundStyle(Theme.Color.ink)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("∅")
                .font(.bricolage(56, weight: .bold))
                .foregroundStyle(Theme.Color.ink)
            Text("Acá van las cards que tires para la derecha o guardes desde el detalle.")
                .font(.albert(14, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.inkMute)
                .frame(maxWidth: 220)
        }
    }
}

struct ArchiveItem: View {
    let card: Card
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TagPill(card: card, compact: true)
                Spacer()
                Text(card.relativeMeta)
                    .font(.mono(11, weight: .regular))
                    .foregroundStyle(Theme.Color.inkMute)
            }
            Text(card.headline)
                .font(.bricolage(17, weight: .semiBold))
                .tracking(-0.25)
                .lineSpacing(-1)
                .foregroundStyle(Theme.Color.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.stat))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.stat)
                .stroke(Theme.Color.rule, lineWidth: 1)
        )
    }
}
