import SwiftUI

struct RecommendSection: View {
    let notices: [Notice]
    var onRefresh: (() -> Void)?
    @State private var rotationAngle: Double = 0
    @State private var cardTransitionId = UUID()

    private var sortedNotices: [Notice] {
        guard let profile = UserOnboardingProfile.load() else { return [] }
        return notices
            .filter {
                profile.matchScore(
                    category: $0.category.rawValue,
                    tags: $0.tags,
                    noticeID: $0.id
                ) >= 50
            }
            .sorted { a, b in
                let sa = profile.matchScore(
                    category: a.category.rawValue,
                    tags: a.tags,
                    noticeID: a.id
                )
                let sb = profile.matchScore(
                    category: b.category.rawValue,
                    tags: b.tags,
                    noticeID: b.id
                )
                return sa > sb
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: 0x9B86B8))
                    Text("芋泥觉得你会关心")
                        .font(AppFonts.sectionTitle())
                        .foregroundStyle(AppColors.textPrimary)
                }
                Spacer()
                Button {
                    withAnimation(AppleSpring.smooth) {
                        rotationAngle += 360
                        cardTransitionId = UUID()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onRefresh?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .medium))
                            .rotationEffect(.degrees(rotationAngle))
                        Text("换一杯")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(Color(hex: 0x9B86B8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0x9B86B8).opacity(0.08))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)

            if sortedNotices.isEmpty {
                emptyState
                    .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(sortedNotices.enumerated()), id: \.element.id) { _, notice in
                            NavigationLink(value: notice) {
                                recommendCard(notice: notice)
                            }
                            .buttonStyle(CardPressStyle())
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.horizontal, 16)
                    .id(cardTransitionId)
                }
            }
        }
    }

    private func cardMatchScore(for notice: Notice) -> Int? {
        guard let profile = UserOnboardingProfile.load() else { return nil }
        let score = profile.matchScore(
            category: notice.category.rawValue,
            tags: notice.tags,
            noticeID: notice.id
        )
        return score >= 50 ? score : nil
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: 0x9B86B8))

            Text("芋泥还在等你多选几个偏好，再来给你更准的推荐")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func recommendCard(notice: Notice) -> some View {
        let score = cardMatchScore(for: notice)

        return VStack(alignment: .leading, spacing: 0) {
            // 匹配度独占一行，避免与来源/图标 ZStack 叠在一起
            if let s = score {
                HStack {
                    matchBadge(score: s)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 8)
            }

            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(notice.category.color.opacity(0.12))
                    Image(systemName: notice.category.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(notice.category.color)
                        .frame(width: 12, height: 12)
                }
                .frame(width: 22, height: 22)

                Text(notice.source)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(notice.timeAgo)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.6))
                    .layoutPriority(1)
            }
            .padding(.bottom, 10)

            Text(notice.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 36, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)

            Text(notice.summary)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.top, 6)
        }
        .padding(14)
        .frame(minWidth: 280, maxWidth: 280, minHeight: 160, alignment: .topLeading)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private func matchBadge(score: Int) -> some View {
        let isHigh = score >= 80
        let badgeColor = isHigh ? Color(hex: 0x34C759) : Color(hex: 0x9B86B8)

        HStack(spacing: 3) {
            if isHigh {
                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .bold))
                    .symbolEffect(.pulse, options: .repeating)
            }
            Text("\(score)%匹配")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(
                LinearGradient(
                    colors: [badgeColor.opacity(0.15), badgeColor.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        )
    }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppleSpring.interactive, value: configuration.isPressed)
    }
}
