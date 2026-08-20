import SwiftUI

struct PnLChartView: View {
    let trades: [TradeRecord]
    @State private var animationProgress: CGFloat = 0

    private var dataPoints: [Double] {
        var cumulative: Double = 0
        return trades
            .filter { $0.isClosed }
            .sorted { ($0.closedAt ?? $0.createdAt) < ($1.closedAt ?? $1.createdAt) }
            .compactMap { trade -> Double? in
                guard let pnl = trade.pnl else { return nil }
                cumulative += pnl
                return cumulative
            }
    }

    var body: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("盈亏曲线")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    if let last = dataPoints.last {
                        Text(String(format: "%+.2f USDT", last))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(last >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed)
                    }
                }

                if dataPoints.count >= 2 {
                    ChartCanvas(points: dataPoints, progress: animationProgress)
                        .frame(height: 140)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 140)
                        .overlay {
                            Text("完成更多交易后显示曲线")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.35))
                        }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animationProgress = 1
            }
        }
    }
}

private struct ChartCanvas: View {
    let points: [Double]
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            let minVal = (points.min() ?? 0) - abs(points.max() ?? 1) * 0.1
            let maxVal = (points.max() ?? 0) + abs(points.max() ?? 1) * 0.1
            let range = max(maxVal - minVal, 1)

            ZStack {
                // Zero line
                let zeroY = geo.size.height - CGFloat((0 - minVal) / range) * geo.size.height
                Path { path in
                    path.move(to: CGPoint(x: 0, y: zeroY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: zeroY))
                }
                .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))

                // Gradient fill
                Path { path in
                    guard points.count >= 2 else { return }
                    for (i, val) in points.enumerated() {
                        let x = geo.size.width * CGFloat(i) / CGFloat(points.count - 1)
                        let y = geo.size.height - CGFloat((val - minVal) / range) * geo.size.height
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            LiquidGlassTheme.accentCyan.opacity(0.25),
                            LiquidGlassTheme.accentPurple.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(Double(progress))

                // Line
                Path { path in
                    guard points.count >= 2 else { return }
                    for (i, val) in points.enumerated() {
                        let x = geo.size.width * CGFloat(i) / CGFloat(points.count - 1) * progress
                        let y = geo.size.height - CGFloat((val - minVal) / range) * geo.size.height
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [LiquidGlassTheme.accentCyan, LiquidGlassTheme.accentPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )

                // End dot
                if let last = points.last, progress >= 0.95 {
                    let x = geo.size.width
                    let y = geo.size.height - CGFloat((last - minVal) / range) * geo.size.height
                    Circle()
                        .fill(LiquidGlassTheme.accentCyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: LiquidGlassTheme.accentCyan.opacity(0.6), radius: 6)
                        .position(x: x, y: y)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
}

struct MiniSparkline: View {
    let pnls: [Double]
    @State private var drawProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let minVal = pnls.min() ?? 0
            let maxVal = pnls.max() ?? 1
            let range = max(maxVal - minVal, 0.01)
            let isPositive = (pnls.last ?? 0) >= (pnls.first ?? 0)

            Path { path in
                for (i, val) in pnls.enumerated() {
                    let x = geo.size.width * CGFloat(i) / CGFloat(max(pnls.count - 1, 1)) * drawProgress
                    let y = geo.size.height - CGFloat((val - minVal) / range) * geo.size.height
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(
                isPositive ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed,
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                drawProgress = 1
            }
        }
    }
}
