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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("盈亏曲线")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.textPrimary)
                Spacer()
                if let last = dataPoints.last {
                    Text(String(format: "%+.2f", last))
                        .font(.system(size: 13, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(last >= 0 ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed)
                }
            }

            if dataPoints.count >= 2 {
                ChartCanvas(points: dataPoints, progress: animationProgress)
                    .frame(height: 148)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 148)
                    .overlay {
                        Text("完成更多交易后显示曲线")
                            .font(.system(size: 12))
                            .foregroundStyle(LiquidGlassTheme.textTertiary)
                    }
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: LiquidGlassTheme.cardCornerRadius)
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
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
            let lineColor = (points.last ?? 0) >= 0
                ? LiquidGlassTheme.profitGreen
                : LiquidGlassTheme.lossRed

            ZStack {
                let zeroY = geo.size.height - CGFloat((0 - minVal) / range) * geo.size.height
                Path { path in
                    path.move(to: CGPoint(x: 0, y: zeroY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: zeroY))
                }
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))

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
                .fill(lineColor.opacity(0.08))
                .opacity(Double(progress))

                Path { path in
                    guard points.count >= 2 else { return }
                    for (i, val) in points.enumerated() {
                        let x = geo.size.width * CGFloat(i) / CGFloat(points.count - 1) * progress
                        let y = geo.size.height - CGFloat((val - minVal) / range) * geo.size.height
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(lineColor.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                if let last = points.last, progress >= 0.95 {
                    let y = geo.size.height - CGFloat((last - minVal) / range) * geo.size.height
                    Circle()
                        .fill(lineColor)
                        .frame(width: 5, height: 5)
                        .position(x: geo.size.width, y: y)
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
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                drawProgress = 1
            }
        }
    }
}
