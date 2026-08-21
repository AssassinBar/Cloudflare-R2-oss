import SwiftUI

enum XiaoAiTheme {
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.12)
    static let glow = Color(red: 1.0, green: 0.78, blue: 0.38)
    static let core = Color(red: 1.0, green: 0.97, blue: 0.92)
    static let success = Color(red: 0.20, green: 0.84, blue: 0.29)
    static let reject = Color(red: 1.0, green: 0.27, blue: 0.23)
    static let night = Color(red: 0.05, green: 0.06, blue: 0.08)
}

struct XiaoAiOrbView: View {
    var phase: OrbPhase
    var audioLevel: Double
    var compact: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                draw(context: context, size: size, time: t)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("小爱光球")
        .accessibilityValue(phase.rawValue)
    }

    private func draw(context: GraphicsContext, size: CGSize, time: Double) {
        let time = CGFloat(time)
        let audio = CGFloat(max(0, min(audioLevel, 1)))
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.28
        let palette = colors(for: phase)
        let breathe: CGFloat = 1.0 + 0.045 * sin(time * CGFloat(speed))
        let level: CGFloat = 0.35 + 0.65 * audio
        let morph = phase == .speaking || phase == .listening || phase == .wake

        var glowCtx = context
        glowCtx.addFilter(.blur(radius: compact ? 10 : 18))
        glowCtx.fill(
            Path(ellipseIn: CGRect(
                x: center.x - radius * 1.55 * breathe,
                y: center.y - radius * 1.55 * breathe,
                width: radius * 3.1 * breathe,
                height: radius * 3.1 * breathe
            )),
            with: .radialGradient(
                Gradient(colors: [palette.glow.opacity(0.55), .clear]),
                center: center,
                startRadius: 0,
                endRadius: radius * 2.2
            )
        )

        let ringCount = phase == .idle ? 2 : 4
        for i in 0..<ringCount {
            let lag = CGFloat(i) * 0.42
            let pulse: CGFloat
            switch phase {
            case .listening:
                pulse = 0.55 + 0.45 * fract(time * 0.55 + lag)
            case .speaking:
                pulse = 0.4 + 0.6 * abs(sin(time * 2.6 + lag * 2))
            case .wake:
                pulse = fract(time * 1.4 + lag)
            default:
                pulse = 0.35 + 0.2 * sin(time * 0.9 + lag)
            }
            let ringR = radius * (1.35 + pulse * (phase == .listening ? 1.6 : 1.15) * (0.7 + 0.3 * level))
            var ring = Path()
            ring.addEllipse(in: CGRect(x: center.x - ringR, y: center.y - ringR, width: ringR * 2, height: ringR * 2))
            context.stroke(
                ring,
                with: .color(palette.ring.opacity(0.22 + 0.18 * (1 - pulse))),
                lineWidth: compact ? 1.2 : 2.0
            )
        }

        if morph {
            for i in 0..<6 {
                let a = time * (1.1 + CGFloat(i) * 0.17) + CGFloat(i)
                let dx = cos(a) * radius * 0.22 * level
                let dy = sin(a * 1.3) * radius * 0.18 * level
                let blobR = radius * (0.72 + 0.08 * sin(time * 3 + CGFloat(i)))
                var blobCtx = context
                blobCtx.addFilter(.blur(radius: compact ? 6 : 12))
                blobCtx.blendMode = .plusLighter
                blobCtx.fill(
                    Path(ellipseIn: CGRect(
                        x: center.x + dx - blobR,
                        y: center.y + dy - blobR,
                        width: blobR * 2,
                        height: blobR * 2
                    )),
                    with: .color(palette.blob.opacity(0.28))
                )
            }
        }

        let coreR = radius * breathe * (phase == .speaking ? 0.92 + 0.12 * level : 1)
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)),
            with: .radialGradient(
                Gradient(colors: [XiaoAiTheme.core, palette.core, palette.blob.opacity(0.95)]),
                center: CGPoint(x: center.x - coreR * 0.18, y: center.y - coreR * 0.22),
                startRadius: 0,
                endRadius: coreR
            )
        )

        var highlight = Path()
        highlight.addEllipse(in: CGRect(
            x: center.x - coreR * 0.45,
            y: center.y - coreR * 0.58,
            width: coreR * 0.55,
            height: coreR * 0.32
        ))
        context.fill(highlight, with: .color(.white.opacity(0.35)))

        if phase == .speaking {
            drawWave(context: context, center: center, radius: radius, time: time, color: palette.ring)
        }

        if phase == .success || phase == .reject {
            drawMark(context: context, center: center, radius: radius * 0.45, success: phase == .success)
        }
    }

    private var speed: Double {
        switch phase {
        case .idle: return 1.2
        case .wake: return 4.5
        case .speaking: return 3.2
        case .listening: return 2.4
        case .success, .reject: return 0.6
        }
    }

    private func colors(for phase: OrbPhase) -> (blob: Color, glow: Color, core: Color, ring: Color) {
        switch phase {
        case .success:
            return (XiaoAiTheme.success, XiaoAiTheme.success, XiaoAiTheme.core, XiaoAiTheme.success)
        case .reject:
            return (XiaoAiTheme.reject, XiaoAiTheme.reject, XiaoAiTheme.core, XiaoAiTheme.reject)
        default:
            return (XiaoAiTheme.orange, XiaoAiTheme.glow, XiaoAiTheme.orange, XiaoAiTheme.glow)
        }
    }

    private func drawWave(context: GraphicsContext, center: CGPoint, radius: CGFloat, time: CGFloat, color: Color) {
        let bars = 7
        let width = radius * 0.09
        for i in 0..<bars {
            let offset = CGFloat(i - bars / 2)
            let h = radius * (0.18 + 0.55 * abs(sin(time * 6 + CGFloat(i) * 0.7)))
                let x = center.x + offset * (width * 1.8) - width / 2
                let y = center.y - h / 2
                let path = Path(roundedRect: CGRect(x: x, y: y, width: width, height: h), cornerRadius: width / 2)
                context.fill(path, with: .color(.white.opacity(0.85)))
                context.stroke(path, with: .color(color.opacity(0.4)), lineWidth: 0.6)
            }
    }

    private func drawMark(context: GraphicsContext, center: CGPoint, radius: CGFloat, success: Bool) {
        var path = Path()
        if success {
            path.move(to: CGPoint(x: center.x - radius * 0.55, y: center.y + radius * 0.05))
            path.addLine(to: CGPoint(x: center.x - radius * 0.12, y: center.y + radius * 0.48))
            path.addLine(to: CGPoint(x: center.x + radius * 0.62, y: center.y - radius * 0.42))
        } else {
            path.move(to: CGPoint(x: center.x - radius * 0.42, y: center.y - radius * 0.42))
            path.addLine(to: CGPoint(x: center.x + radius * 0.42, y: center.y + radius * 0.42))
            path.move(to: CGPoint(x: center.x + radius * 0.42, y: center.y - radius * 0.42))
            path.addLine(to: CGPoint(x: center.x - radius * 0.42, y: center.y + radius * 0.42))
        }
        context.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
    }

    private func fract(_ x: CGFloat) -> CGFloat {
        x - floor(x)
    }
}

