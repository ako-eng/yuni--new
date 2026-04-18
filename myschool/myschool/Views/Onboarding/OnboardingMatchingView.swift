import SwiftUI

struct OnboardingMatchingView: View {
    let categories: [String]
    var onDone: () -> Void

    @State private var progress: CGFloat = 0
    @State private var messageIndex = 0
    @State private var cupWobble = false
    @State private var orbitRotation: Double = 0
    @State private var confettiWaveA: [ConfettiParticle] = []
    @State private var confettiWaveB: [ConfettiParticle] = []
    @State private var matchingTask: Task<Void, Never>?

    @State private var entranceReady = false
    @State private var barShimmerDeadline = Date.distantPast
    @State private var percentDisplayScale: CGFloat = 1
    @State private var lastPercentInt = -1
    @State private var cupPopScale: CGFloat = 1
    @State private var flowSeed = Int.random(in: 0..<10_000)

    private let messages = [
        "正在分析你的校园画像…",
        "匹配历史通知数据…",
        "翻遍了 326 条历史通知…",
        "计算你的兴趣图谱…",
        "你的校园信息图谱正在成型…",
        "生成你的专属推荐…",
    ]

    private var matchingPhase: MatchingPhase {
        MatchingPhase.from(progress: progress)
    }

    private var orbitIconsForUser: [String] {
        guard !categories.isEmpty else {
            return Array(NoticeCategory.allCases.map(\.icon).prefix(6))
        }
        var icons: [String] = []
        for c in categories {
            if let nc = NoticeCategory(rawValue: c) {
                icons.append(nc.icon)
            } else if let nc = NoticeCategory(apiCategory: c) {
                icons.append(nc.icon)
            }
        }
        if icons.count < 6 {
            for nc in NoticeCategory.allCases {
                if icons.count >= 8 { break }
                if !icons.contains(nc.icon) { icons.append(nc.icon) }
            }
        }
        var deduped: [String] = []
        var seen = Set<String>()
        for s in icons {
            if seen.insert(s).inserted { deduped.append(s) }
            if deduped.count >= 6 { break }
        }
        if deduped.count < 6 {
            for nc in NoticeCategory.allCases {
                if deduped.count >= 6 { break }
                if !seen.contains(nc.icon) {
                    seen.insert(nc.icon)
                    deduped.append(nc.icon)
                }
            }
        }
        return deduped.isEmpty ? Array(NoticeCategory.allCases.map(\.icon).prefix(6)) : deduped
    }

    /// 与用户第一个偏好类别对应的 SF Symbol，用于轨道高亮。
    private var firstCategoryIconForHighlight: String? {
        guard let raw = categories.first else { return nil }
        if let nc = NoticeCategory(rawValue: raw) { return nc.icon }
        if let nc = NoticeCategory(apiCategory: raw) { return nc.icon }
        return nil
    }

    private var cupBreathScale: CGFloat {
        switch matchingPhase {
        case .warmingUp: return 1.0
        case .analyzing: return 1.012
        case .deepMatching: return 1.028
        case .finishing: return 1.018
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                MatchingAmbientGlow(phase: matchingPhase)

                MatchingDataFlowLines(phase: matchingPhase, isActive: progress > 0 && progress < 1)

                MatchingOrbitLayer(
                    icons: orbitIconsForUser,
                    highlightedIconName: firstCategoryIconForHighlight,
                    orbitAngle: orbitRotation,
                    phase: matchingPhase,
                    entranceVisible: entranceReady
                )

                VStack(spacing: 20) {
                    ZStack {
                        MatchingFloatingParticles(phase: matchingPhase, seed: flowSeed)

                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: CGFloat([6, 8, 10][i]))
                                .offset(
                                    x: CGFloat([20, 30, 36][i]),
                                    y: CGFloat([-30, -42, -56][i])
                                )
                                .opacity(cupWobble ? 1 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.2),
                                    value: cupWobble
                                )
                        }

                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(Color(hex: 0xFFF8F5))
                            .shadow(color: Color(hex: 0x4A3A5C).opacity(0.3), radius: 10, y: 5)
                            .rotationEffect(.degrees(cupWobble ? 3 : -3))
                            .scaleEffect(cupPopScale * cupBreathScale)
                            .animation(
                                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                                value: cupWobble
                            )
                            .animation(.spring(response: 0.38, dampingFraction: 0.62), value: cupPopScale)
                            .animation(.easeInOut(duration: 1.2), value: matchingPhase)
                    }

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.7 + 0.3 * progress),
                                    Color(hex: 0xC4B0DC).opacity(0.5 + 0.5 * progress),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())
                        .monospacedDigit()
                        .scaleEffect(percentDisplayScale)

                    progressBar

                    MatchingMessageShimmer(text: messages[messageIndex])
                        .contentTransition(.opacity)
                        .animation(.easeInOut, value: messageIndex)
                }

                ForEach(confettiWaveA) { particle in
                    confettiShape(particle)
                }
                ForEach(confettiWaveB) { particle in
                    confettiShape(particle)
                }
            }
            .scaleEffect(entranceReady ? 1 : 0.92)
            .blur(radius: entranceReady ? 0 : 5)
            .animation(.spring(response: 0.48, dampingFraction: 0.82), value: entranceReady)

            Spacer()
            Spacer()
        }
        .onAppear {
            flowSeed = Int.random(in: 0..<10_000)
            startMatching()
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                    entranceReady = true
                }
            }
        }
        .onDisappear { matchingTask?.cancel() }
        .onChange(of: progress) { _, newValue in
            barShimmerDeadline = Date().addingTimeInterval(2.6)
            let p = min(100, Int(floor(newValue * 100 + 0.001)))
            for m in [25, 50, 75, 100] where p >= m && lastPercentInt < m {
                milestoneFeedback(for: m)
            }
            lastPercentInt = p
        }
    }

    @ViewBuilder
    private func confettiShape(_ particle: ConfettiParticle) -> some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            case .rect:
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(particle.color)
                    .frame(width: particle.size * 1.1, height: particle.size * 0.65)
                    .rotationEffect(.degrees(particle.rotation))
            case .capsule:
                Capsule()
                    .fill(particle.color)
                    .frame(width: particle.size * 0.5, height: particle.size * 1.1)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .offset(x: particle.x, y: particle.y)
        .opacity(particle.opacity)
    }

    private func milestoneFeedback(for milestone: Int) {
        let impact = UIImpactFeedbackGenerator(style: milestone >= 75 ? .medium : .light)
        impact.prepare()
        impact.impactOccurred()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            percentDisplayScale = 1.08
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                percentDisplayScale = 1
            }
        }
    }

    private var progressBar: some View {
        TimelineView(.animation(minimumInterval: 0.35)) { context in
            let shimmerOn = context.date < barShimmerDeadline
            GeometryReader { geo in
                Capsule()
                    .fill(Color.black.opacity(0.28))
                    .frame(height: 9)
                    .overlay(alignment: .leading) {
                        MatchingProgressBarShine(progress: progress, shimmerActive: shimmerOn, barHeight: 9)
                            .animation(AppleSpring.smooth, value: progress)
                    }
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.42), lineWidth: 1.25)
                    }
            }
        }
        .frame(width: 200, height: 9)
    }

    private func startMatching() {
        cupWobble = true

        withAnimation(.linear(duration: 48).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }

        matchingTask?.cancel()
        matchingTask = Task { @MainActor in
            let timeline: [(target: CGFloat, wait: Double, message: Int)] = [
                (0.04, 0.07, 0),
                (0.08, 0.06, 0),
                (0.12, 0.08, 0),
                (0.17, 0.09, 0),
                (0.22, 0.08, 1),
                (0.28, 0.10, 1),
                (0.33, 0.09, 1),
                (0.38, 0.11, 1),
                (0.43, 0.10, 2),
                (0.48, 0.12, 2),
                (0.52, 0.14, 2),
                (0.56, 0.13, 2),
                (0.60, 0.15, 3),
                (0.64, 0.16, 3),
                (0.68, 0.14, 3),
                (0.72, 0.18, 4),
                (0.76, 0.17, 4),
                (0.79, 0.20, 4),
                (0.82, 0.28, 4),
                (0.85, 0.32, 5),
                (0.88, 0.30, 5),
                (0.91, 0.36, 5),
                (0.93, 0.38, 5),
                (0.95, 0.42, 5),
                (0.97, 0.48, 5),
            ]
            let sumBaseWaits = timeline.reduce(0.0) { $0 + $1.wait }
            let targetStepSeconds: Double = 120
            let scale = targetStepSeconds / sumBaseWaits

            for step in timeline {
                guard !Task.isCancelled else { return }
                let wait = step.wait * scale
                let progressAnim = min(max(wait * 0.5, 0.15), 4.0)
                withAnimation(.easeOut(duration: progressAnim)) {
                    messageIndex = step.message
                    progress = step.target
                }
                try? await Task.sleep(for: .seconds(wait))
            }

            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 2.2)) {
                progress = 1.0
            }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.58)) {
                cupPopScale = 1.12
            }
            try? await Task.sleep(for: .seconds(0.12))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                cupPopScale = 1.0
            }

            triggerConfettiWaveA()
            try? await Task.sleep(for: .seconds(0.38))
            guard !Task.isCancelled else { return }
            triggerConfettiWaveB()

            try? await Task.sleep(for: .seconds(2.0))
            guard !Task.isCancelled else { return }
            onDone()
        }
    }

    private func triggerConfettiWaveA() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let colors: [Color] = [
            Color(hex: 0xC4B0DC), Color(hex: 0x9B86B8), Color(hex: 0xFFF8F5),
            Color(hex: 0xE8D4F5), .white, Color(hex: 0x6B5B7F),
        ]
        confettiWaveA = (0..<16).map { _ in
            ConfettiParticle(
                x: 0, y: 0,
                targetX: CGFloat.random(in: -120...120),
                targetY: CGFloat.random(in: -160...80),
                size: CGFloat.random(in: 4...7),
                color: colors.randomElement()!,
                opacity: 1.0,
                shape: ConfettiShape.allCases.randomElement()!,
                rotation: CGFloat.random(in: 0...360)
            )
        }

        withAnimation(.easeOut(duration: 0.75)) {
            for i in confettiWaveA.indices {
                confettiWaveA[i].x = confettiWaveA[i].targetX
                confettiWaveA[i].y = confettiWaveA[i].targetY
            }
        }
        withAnimation(.easeIn(duration: 0.45).delay(0.55)) {
            for i in confettiWaveA.indices {
                confettiWaveA[i].opacity = 0
            }
        }
    }

    private func triggerConfettiWaveB() {
        let colors: [Color] = [
            Color(hex: 0xC4B0DC), Color(hex: 0x9B86B8), Color(hex: 0xFFF8F5),
            Color(hex: 0xE8D4F5), .white,
        ]
        confettiWaveB = (0..<26).map { _ in
            ConfettiParticle(
                x: 0, y: 0,
                targetX: CGFloat.random(in: -175...175),
                targetY: CGFloat.random(in: -220...110),
                size: CGFloat.random(in: 5...10),
                color: colors.randomElement()!,
                opacity: 1.0,
                shape: ConfettiShape.allCases.randomElement()!,
                rotation: CGFloat.random(in: 0...360)
            )
        }
        withAnimation(.easeOut(duration: 0.85)) {
            for i in confettiWaveB.indices {
                confettiWaveB[i].x = confettiWaveB[i].targetX
                confettiWaveB[i].y = confettiWaveB[i].targetY
            }
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.65)) {
            for i in confettiWaveB.indices {
                confettiWaveB[i].opacity = 0
            }
        }
    }
}

private enum ConfettiShape: CaseIterable {
    case circle, rect, capsule
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let size: CGFloat
    let color: Color
    var opacity: Double
    var shape: ConfettiShape
    var rotation: CGFloat
}
