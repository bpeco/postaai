import SwiftUI

// Minimal flow layout for chip rows. Used by ChipSection and SettingsScreen.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var currentWidth: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if currentWidth + s.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(s)
            currentWidth += s.width + spacing
        }
        let height = rows.reduce(0) { $0 + ($1.map(\.height).max() ?? 0) } + CGFloat(rows.count - 1) * spacing
        return CGSize(width: proposal.width ?? .zero, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxX = bounds.maxX
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: s.width, height: s.height))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
