import SwiftUI

// MARK: - Phase

enum MatchingPhase: Int, Comparable {
    case warmingUp
    case analyzing
    case deepMatching
    case finishing

    static func < (lhs: MatchingPhase, rhs: MatchingPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func from(progress: CGFloat) -> MatchingPhase {
        if progress >= 1.0 { return .finishing }
        if progress >= 0.75 { return .deepMatching }
        if progress >= 0.40 { return .analyzing }
        return .warmingUp
    }
}

// MARK: - Ambient glow

struct MatchingAmbientGlow: View {
    var phase: MatchingPhase
    @State private var breathe = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: 0x9B86B8).opacity(0.22 * intensity),
                        Color(hex: 0x4A3A5C).opacity(0.05),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 200
                )
            )
            .frame(width: 340, height: 340)
            .blur(radius: 28)
            .opacity(breathe ? 1 : 0.72)
            .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: breathe)
            .onAppear { breathe = true }
    }

    private var intensity: Double {
        switch phase {
        case .warmingUp: return 0.7
        case .analyzing: return 1.0
        case .deepMatching: return 1.15
        case .finishing: return 1.25
        }
    }
}

// MARK: - Data flow lines (trim)

struct MatchingDataFlowLines: View {
    var phase: MatchingPhase
    var isActive: Bool

    private var lineOpacity: Double {
        guard isActive else { return 0 }
        switch phase {
        case .warmingUp: return 0.12
        case .analyzing: return 0.2
        case .deepMatching: return 0.32
        case .finishing: return 0.28
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let cycle = 2.8
            let trim = CGFloat((t.truncatingRemainder(dividingBy: cycle)) / cycle)

            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2 + 8)
                let targets: [CGPoint] = [
                    CGPoint(x: center.x + 95, y: center.y - 52),
                    CGPoint(x: center.x - 88, y: center.y + 58),
                    CGPoint(x: center.x + 72, y: center.y + 68),
                ]
                for p in targets {
                    let path = Path { pa in
                        pa.move(to: center)
                        pa.addQuadCurve(to: p, control: CGPoint(
                            x: (center.x + p.x) / 2 + 20,
                            y: (center.y + p.y) / 2 - 30
                        ))
                    }
                    let a = trim * 0.65
                    let b = min(1, a + 0.38)
                    let trimmed = path.trimmedPath(from: a, to: b)
                    ctx.stroke(
                        trimmed,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.02),
                                Color(hex: 0xC4B0DC).opacity(0.55),
                                Color.white.opacity(0.08),
                            ]),
                            startPoint: center,
                            endPoint: p
                        ),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 6])
                    )
                }
            }
            .opacity(lineOpacity)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Floating particles

struct MatchingFloatingParticles: View {
    var phase: MatchingPhase
    var seed: Int

    private var count: Int {
        switch phase {
        case .warmingUp: return 5
        case .analyzing: return 7
        case .deepMatching: return 11
        case .finishing: return 9
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let base = Double((seed &+ i &* 17) % 1000) / 1000.0
                    let xOff = CGFloat(sin(t * 0.7 + base * 6) * 38 + cos(base * 4) * 22)
                    let yPhase = CGFloat((t * 0.35 + base).truncatingRemainder(dividingBy: 1.0))
                    let y = CGFloat(40) - yPhase * CGFloat(100)
                    let op = 0.12 + 0.18 * (1 - yPhase)
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: CGFloat(3 + (i % 3)), height: CGFloat(3 + (i % 3)))
                        .offset(x: xOff, y: y)
                        .opacity(op)
                }
            }
            .frame(width: 120, height: 120)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Message shimmer

struct MatchingMessageShimmer: View {
    let text: String

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let shift = CGFloat(sin(t * 0.9) * 0.5 + 0.5)

            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .overlay {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.12),
                                .clear,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.45)
                        .offset(x: -geo.size.width * 0.3 + shift * geo.size.width * 1.1)
                        .blendMode(.overlay)
                    }
                    .mask(
                        Text(text)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    )
                }
        }
    }
}

// MARK: - Progress bar shine

struct MatchingProgressBarShine: View {
    var progress: CGFloat
    var shimmerActive: Bool
    var barHeight: CGFloat = 8
    /// 偏好页底部条使用较亮的双色拉满
    var usePreferenceGradient: Bool = false

    private var minFillWidth: CGFloat { barHeight < 7 ? 6 : 10 }

    var body: some View {
        GeometryReader { geo in
            let fillW = max(minFillWidth, geo.size.width * progress)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        usePreferenceGradient
                            ? LinearGradient(
                                colors: [Color(hex: 0xC4B0DC), Color.white.opacity(0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(hex: 0xFFF8F5).opacity(0.9),
                                    Color(hex: 0xC4B0DC),
                                    Color(hex: 0x9B86B8),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: fillW, height: barHeight)

                if shimmerActive && fillW > minFillWidth + 12 {
                    TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let x = CGFloat((t * 38).truncatingRemainder(dividingBy: Double(fillW + 40))) - 20
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        Color.white.opacity(0.45),
                                        .clear,
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 32, height: barHeight)
                            .offset(x: x)
                            .frame(width: fillW, height: barHeight, alignment: .leading)
                            .clipped()
                    }
                }
            }
        }
    }
}
