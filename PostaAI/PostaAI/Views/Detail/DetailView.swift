import SwiftUI

struct DetailView: View {
    let card: Card
    let isSaved: Bool
    let onClose: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            Theme.Color.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                head
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\((card.kind.first ?? "").uppercased()) · \(card.relativeMeta.uppercased())")
                            .font(.mono(10, weight: .regular))
                            .kerning(1.2)
                            .foregroundStyle(Theme.Color.inkMute)
                            .padding(.bottom, 6)

                        Text(card.headline)
                            .font(.bricolage(34, weight: .bold))
                            .tracking(-0.85)
                            .lineSpacing(-2)
                            .foregroundStyle(Theme.Color.ink)
                            .padding(.bottom, 24)

                        section(title: "Contexto") {
                            Text(card.context)
                                .font(.albert(17, weight: .regular))
                                .lineSpacing(4)
                                .foregroundStyle(Theme.Color.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        takeBox
                            .padding(.bottom, 24)

                        section(title: "Fuente") {
                            sourceLink
                        }

                        HStack(spacing: 10) {
                            Button(action: onSave) {
                                Text(isSaved ? "Guardada ✓" : "Guardar")
                                    .font(.bricolage(15, weight: .semiBold))
                                    .tracking(-0.15)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Theme.Color.yes, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)

                            Button(action: onClose) {
                                Text("Volver al mazo")
                                    .font(.bricolage(15, weight: .semiBold))
                                    .tracking(-0.15)
                                    .foregroundStyle(Theme.Color.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.Color.ink, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
                    .padding(.bottom, 60)
                }
            }
        }
    }

    private var head: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Color.paper)
                    .frame(width: 40, height: 40)
                    .background(Theme.Color.ink, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            TagPill(card: card)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var takeBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("EL TAKE DE POSTA")
                .font(.mono(10.5, weight: .regular))
                .kerning(1.7)
                .foregroundStyle(Theme.Color.hl)
                .padding(.bottom, 6)
            Text(card.editorial)
                .font(.bricolage(21, weight: .semiBold))
                .tracking(-0.31)
                .lineSpacing(0)
                .foregroundStyle(Theme.Color.paper)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.Color.ink, in: RoundedRectangle(cornerRadius: Theme.Radius.detailBox))
    }

    @ViewBuilder
    private var sourceLink: some View {
        if let url = URL(string: card.source) {
            Link(destination: url) { sourceLinkContent }
                .buttonStyle(.plain)
        } else {
            sourceLinkContent
        }
    }

    private var sourceLinkContent: some View {
        HStack(spacing: 8) {
            Text(card.sourceLabel)
                .font(.mono(13, weight: .regular))
                .foregroundStyle(Theme.Color.ink)
            ZStack {
                Circle().fill(Theme.Color.no)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 18, height: 18)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.Color.paperDeep, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func section<C: View>(title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.mono(10.5, weight: .regular))
                .kerning(1.7)
                .foregroundStyle(Theme.Color.inkMute)
            content()
        }
        .padding(.bottom, 24)
    }
}
