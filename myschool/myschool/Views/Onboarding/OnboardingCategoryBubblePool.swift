import SwiftUI

/// Full-screen drifting category bubbles with optional burst for unselected items.
struct OnboardingCategoryBubblePool: View {
    @Binding var selectedCategories: [NoticeCategory]
    let categoryDescriptions: [NoticeCategory: String]
    let categoryPatternIcons: [NoticeCategory: String]
    let gridIn: Bool
    let isBursting: Bool
    let parallaxTiltX: CGFloat
    let parallaxTiltY: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let bubbleW: CGFloat = 108
    private let bubbleH: CGFloat = 104

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            poolContent(t: context.date.timeIntervalSinceReferenceDate)
        }
    }

    private func poolContent(t: TimeInterval) -> some View {
        GeometryReader { geo in
            let base = min(geo.size.width, geo.size.height)
            let px = parallaxTiltX * base * 0.042
            let py = parallaxTiltY * base * 0.042
            ZStack {
                ForEach(Array(NoticeCategory.allCases.enumerated()), id: \.element.id) { index, cat in
                    positionedBubble(
                        cat: cat,
                        index: index,
                        size: geo.size,
                        t: t,
                        px: px,
                        py: py
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func positionedBubble(
        cat: NoticeCategory,
        index: Int,
        size: CGSize,
        t: TimeInterval,
        px: CGFloat,
        py: CGFloat
    ) -> some View {
        let center = baseCenter(for: cat, in: size)
        let drift = driftOffset(for: cat, t: t, reduceMotion: reduceMotion)
        return PoolCategoryBubble(
            category: cat,
            description: categoryDescriptions[cat] ?? "",
            patternIcon: categoryPatternIcons[cat] ?? cat.icon,
            isSelected: selectedCategories.contains(cat),
            isBursting: isBursting,
            reduceMotion: reduceMotion,
            bubbleW: bubbleW,
            bubbleH: bubbleH,
            onTap: { toggle(cat) }
        )
        .opacity(gridIn ? 1 : 0)
        .offset(y: gridIn ? 0 : 18)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.82)
                .delay(min(Double(index) * 0.045, 0.38)),
            value: gridIn
        )
        .position(x: center.x + drift.width + px, y: center.y + drift.height + py)
    }

    private func baseCenter(for category: NoticeCategory, in size: CGSize) -> CGPoint {
        let all = NoticeCategory.allCases
        guard let idx = all.firstIndex(of: category) else { return .zero }
        let n = CGFloat(all.count)
        let theta = 2 * CGFloat.pi * CGFloat(idx) / n - CGFloat.pi / 2
        let cx = size.width * 0.5
        let cy = size.height * 0.48
        let rx = size.width * 0.36
        let ry = size.height * 0.29
        return CGPoint(x: cx + rx * cos(theta), y: cy + ry * sin(theta))
    }

    private func driftOffset(for category: NoticeCategory, t: TimeInterval, reduceMotion: Bool) -> CGSize {
        if reduceMotion { return .zero }
        let seed = Double(abs(category.id.hashValue % 10_000)) / 10_000.0
        let phaseX = seed * 2 * Double.pi
        let phaseY = phaseX + 1.37
        let dx = sin(t * 0.68 + phaseX) * 14 + cos(t * 0.33 + phaseY) * 7
        let dy = cos(t * 0.54 + phaseY) * 12 + sin(t * 0.27 + phaseX) * 6
        return CGSize(width: dx, height: dy)
    }

    private func toggle(_ cat: NoticeCategory) {
        guard !isBursting else { return }
        withAnimation(AppleSpring.snappy) {
            if let idx = selectedCategories.firstIndex(of: cat) {
                selectedCategories.remove(at: idx)
            } else {
                selectedCategories.append(cat)
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Single bubble

private struct PoolCategoryBubble: View {
    let category: NoticeCategory
    let description: String
    let patternIcon: String
    let isSelected: Bool
    let isBursting: Bool
    let reduceMotion: Bool
    let bubbleW: CGFloat
    let bubbleH: CGFloat
    let onTap: () -> Void

    @State private var pulsePhase = false
    @State private var shardSpread: CGFloat = 0

    private var burstTarget: Bool { isBursting && !isSelected }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                ZStack {
                    Image(systemName: patternIcon)
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundStyle(
                            isSelected ? category.color.opacity(0.12) : Color.white.opacity(0.05)
                        )
                        .offset(x: isSelected ? 28 : 32, y: isSelected ? 28 : 32)
                        .rotationEffect(.degrees(isSelected ? -10 : -14))
                        .animation(AppleSpring.smooth, value: isSelected)

                    VStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(isSelected ? category.color : .white.opacity(0.72))
                            .frame(height: 32)
                            .scaleEffect(isSelected ? 1.06 : 1.0)
                            .animation(AppleSpring.smooth, value: isSelected)

                        Text(category.displayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.88))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(description)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)

                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white)
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }
                }
                .opacity(burstTarget ? 0 : 1)
                .scaleEffect(
                    burstTarget ? (reduceMotion ? 0.94 : 0.2) : 1,
                    anchor: .center
                )
                .animation(
                    reduceMotion ? .easeOut(duration: 0.42) : .easeOut(duration: 0.78),
                    value: isBursting
                )
                .frame(width: bubbleW, height: bubbleH)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: bubbleW / 2, style: .continuous))
                .overlay(bubbleStroke)
                .shadow(color: Color.black.opacity(isSelected ? 0.22 : 0.12), radius: isSelected ? 14 : 8, y: 6)

                if isBursting, !isSelected, !reduceMotion {
                    burstShards
                }
            }
            .frame(width: bubbleW + 72, height: bubbleH + 72)
            .onboardingBubbleTilt(stableKey: category.id, isSelected: isSelected)
            .onboardingBubbleSelection(isSelected: isSelected, style: .floatingPool)
            .scaleEffect(isBursting && isSelected ? 1.03 : 1.0)
            .animation(AppleSpring.gentle, value: isBursting && isSelected)
        }
        .buttonStyle(OnboardingPoolBubblePressStyle())
        .accessibilityLabel("\(category.displayName)，\(description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onChange(of: isBursting) { _, bursting in
            if bursting, !isSelected {
                shardSpread = 0
                withAnimation(.easeOut(duration: 0.74)) {
                    shardSpread = 1
                }
            } else if !bursting {
                shardSpread = 0
            }
        }
        .onChange(of: isSelected) { _, selected in
            pulsePhase = selected
        }
    }

    private var burstShards: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                let angle = 2 * CGFloat.pi * CGFloat(i) / 10 + CGFloat(i % 3) * 0.08
                let r = 44 * shardSpread
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [category.color.opacity(0.95), .white.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 5, height: 9)
                    .rotationEffect(.degrees(Double(i) * 17))
                    .offset(x: cos(angle) * r, y: sin(angle) * r)
                    .opacity(Double(1 - shardSpread * 0.95))
            }
        }
        .allowsHitTesting(false)
    }

    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: bubbleW / 2, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [
                        isSelected ? category.color.opacity(0.42) : Color.white.opacity(0.1),
                        isSelected ? category.color.opacity(0.22) : Color.white.opacity(0.06),
                    ],
                    center: .topLeading,
                    startRadius: 4,
                    endRadius: bubbleW * 0.75
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: bubbleW / 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.22 : 0.08),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .blendMode(.screen)
            }
    }

    private var bubbleStroke: some View {
        RoundedRectangle(cornerRadius: bubbleW / 2, style: .continuous)
            .strokeBorder(
                isSelected
                    ? LinearGradient(
                        colors: [Color.white.opacity(0.55), category.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                lineWidth: isSelected ? 2 : 1
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: bubbleW / 2, style: .continuous)
                        .strokeBorder(category.color.opacity(pulsePhase ? 0.55 : 0.35), lineWidth: 1)
                        .animation(
                            .easeInOut(duration: 1.15).repeatForever(autoreverses: true),
                            value: pulsePhase
                        )
                }
            }
    }
}

private struct OnboardingPoolBubblePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(AppleSpring.interactive, value: configuration.isPressed)
    }
}
