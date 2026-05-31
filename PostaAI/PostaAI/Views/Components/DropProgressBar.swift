import SwiftUI

struct DropProgressBar: View {
    let number: Int
    let consumed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(min(consumed, total)) / Double(total)
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("Drop #\(number)")
                .font(.mono(10, weight: .regular))
                .kerning(1.0)
                .foregroundStyle(Theme.Color.inkSoft)
                .textCase(.uppercase)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Color.paperDeep)
                    Capsule()
                        .fill(Theme.Color.ink)
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: progress)
                }
            }
            .frame(height: 4)

            Text("\(max(0, consumed))/\(total)")
                .font(.mono(10, weight: .regular))
                .kerning(1.0)
                .foregroundStyle(Theme.Color.inkSoft)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 20)
    }
}
