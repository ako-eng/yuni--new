import SwiftUI

enum DynamicIslandPhase {
    case hidden
    case compact
    case expanded
}

struct UrgentNoticeBanner: View {
    let notice: Notice
    let containerWidth: CGFloat
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var phase: DynamicIslandPhase = .hidden
    @State private var dragOffset: CGFloat = 0

    private var islandWidth: CGFloat {
        switch phase {
        case .hidden: return 126
        case .compact: return 250
        case .expanded: return containerWidth - 24
        }
    }

    private var islandHeight: CGFloat {
        switch phase {
        case .hidden: return 37
        case .compact: return 40
        case .expanded: return 170
        }
    }

    private var cornerRadius: CGFloat {
        switch phase {
        case .hidden: return 20
        case .compact: return 22
        case .expanded: return 28
        }
    }

    var body: some View {
        islandContent
            .frame(width: islandWidth, height: islandHeight)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(phase == .expanded ? 0.35 : 0.2),
                radius: phase == .expanded ? 30 : 12,
                x: 0,
                y: phase == .expanded ? 10 : 4
            )
            .offset(y: dragOffset)
            .scaleEffect(phase == .hidden ? 0.8 : 1.0)
            .opacity(phase == .hidden ? 0 : 1)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height < 0 {
                            dragOffset = value.translation.height * 0.5
                        }
                    }
                    .onEnded { value in
                        if value.translation.height < -40 {
                            dismissIsland()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                if phase == .compact {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        phase = .expanded
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if phase == .expanded {
                    onTap()
                    dismissIsland()
                }
            }
            .onAppear { startSequence() }
            .animation(.spring(response: 0.5, dampingFraction: 0.72), value: phase)
    }

    @ViewBuilder
    private var islandContent: some View {
        switch phase {
        case .hidden:
            Color.clear
        case .compact:
            compactContent
        case .expanded:
            expandedContent
        }
    }

    // MARK: - Compact

    private var compactContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse, options: .repeating)

            Text(notice.source)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(notice.isUrgent ? "紧急" : "新通知")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 18)
    }

    // MARK: - Expanded

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)

                Image(systemName: notice.category.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)

                Text("\(notice.category.displayName) · \(notice.source)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)

                Spacer()

                Text("刚刚")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.top, 14)
            .padding(.horizontal, 18)

            Text(notice.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(.top, 10)
                .padding(.horizontal, 18)

            Text(notice.summary)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(2)
                .padding(.top, 4)
                .padding(.horizontal, 18)

            Spacer(minLength: 0)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text("紧急通知")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.orange, in: Capsule())

                Spacer()

                Text("点击查看详情 →")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Animation Sequence

    private func startSequence() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            phase = .compact
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                phase = .expanded
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            if phase == .expanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    phase = .compact
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 16) {
            dismissIsland()
        }
    }

    private func dismissIsland() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            phase = .hidden
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}
