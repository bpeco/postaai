import SwiftUI

enum AppIcon {
    case bookmark, settings, close, external
}

struct IconButton: View {
    let icon: AppIcon
    var active: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(active ? Theme.Color.ink : Theme.Color.surface)
                    .overlay(
                        Circle().stroke(active ? Theme.Color.ink : Theme.Color.rule, lineWidth: 1)
                    )
                shape
                    .foregroundStyle(active ? Theme.Color.paper : Theme.Color.ink)
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(PressableButtonStyle())
    }

    @ViewBuilder
    private var shape: some View {
        switch icon {
        case .bookmark:
            BookmarkShape()
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 18, height: 18)
        case .settings:
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .medium))
        case .close:
            CloseShape()
                .stroke(style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .frame(width: 16, height: 16)
        case .external:
            ExternalShape()
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 12, height: 12)
        }
    }
}

struct BookmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.792, y: h * 0.875))
        p.addLine(to: CGPoint(x: w * 0.5,   y: h * 0.666))
        p.addLine(to: CGPoint(x: w * 0.208, y: h * 0.875))
        p.addLine(to: CGPoint(x: w * 0.208, y: h * 0.208))
        p.addQuadCurve(to: CGPoint(x: w * 0.292, y: h * 0.125), control: CGPoint(x: w * 0.208, y: h * 0.125))
        p.addLine(to: CGPoint(x: w * 0.708, y: h * 0.125))
        p.addQuadCurve(to: CGPoint(x: w * 0.792, y: h * 0.208), control: CGPoint(x: w * 0.792, y: h * 0.125))
        p.closeSubpath()
        return p
    }
}

struct CloseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

struct ExternalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // diagonal arrow
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY - rect.height * 0.25))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.minY + rect.height * 0.15))
        // top-right corner tick
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.15))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.minY + rect.height * 0.15))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.minY + rect.height * 0.65))
        return p
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
