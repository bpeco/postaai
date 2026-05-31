import SwiftUI

struct BottomNav: View {
    let tab: AppTab
    let onChange: (AppTab) -> Void

    var body: some View {
        HStack {
            ForEach(AppTab.allCases) { item in
                Button {
                    onChange(item)
                } label: {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(item == tab ? Theme.Color.no : .clear)
                            .frame(width: 6, height: 6)
                        Text(item.label.uppercased())
                            .font(.mono(10, weight: .regular))
                            .kerning(0.8)
                            .foregroundStyle(item == tab ? Theme.Color.ink : Theme.Color.inkMute)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Theme.Color.paper.opacity(0), Theme.Color.paper],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}
