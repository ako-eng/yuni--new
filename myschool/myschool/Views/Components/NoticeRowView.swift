import SwiftUI

struct NoticeRowView: View {
    let notice: Notice
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.shareNoticeId) private var shareNoticeId

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            categoryIcon

            VStack(alignment: .leading, spacing: 6) {
                topRow
                titleText
                summaryText
                bottomRow
            }

            if let score = matchScore {
                matchRing(score: score)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: colorScheme == .dark ? .clear : .black.opacity(0.03),
            radius: 1, x: 0, y: 1
        )
        .shadow(
            color: colorScheme == .dark ? .clear : .black.opacity(0.05),
            radius: 8, x: 0, y: 3
        )
        .contextMenu {
            Button {
                withAnimation(AppleSpring.snappy) {
                    NoticeStore.shared.toggleFavorite(notice.id)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label(
                    NoticeStore.shared.isFavorited(notice.id) ? "取消收藏" : "收藏",
                    systemImage: NoticeStore.shared.isFavorited(notice.id) ? "star.slash" : "star"
                )
            }

            Button {
                shareNoticeId.wrappedValue = notice.id
            } label: {
                Label("分享", systemImage: "square.and.arrow.up")
            }

            if !notice.isRead {
                Button {
                    NoticeStore.shared.markAsRead(notice.id)
                } label: {
                    Label("标为已读", systemImage: "envelope.open")
                }
            }

            Divider()

            Button(role: .destructive) {
            } label: {
                Label("不感兴趣", systemImage: "hand.thumbsdown")
            }
        } preview: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: notice.category.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(notice.category.color)
                        .frame(width: 18, height: 18)
                    Text(notice.source)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(notice.category.color)
                    Spacer()
                    Text(notice.timeAgo)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Text(notice.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(3)

                Text(notice.summary)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(20)
            .frame(width: 320)
        }
    }

    // MARK: - Category Icon

    private var categoryIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [notice.category.color.opacity(0.15), notice.category.color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: notice.category.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(notice.category.color)
                .frame(width: 20, height: 20)
        }
        .frame(width: 38, height: 38)
        .padding(.top, 2)
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack(spacing: 6) {
            Text(notice.source)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            if notice.isUrgent {
                Text("紧急")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(AppColors.warmOrange.gradient)
                    .clipShape(Capsule())
            }

            if notice.isImportant && !notice.isUrgent {
                Text("重要")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(AppColors.softRed.gradient)
                    .clipShape(Capsule())
            }

            Spacer()

            if !notice.isRead {
                Circle()
                    .fill(Color(hex: 0x9B86B8))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Title

    private var titleText: some View {
        Text(notice.title)
            .font(.system(size: 15, weight: notice.isRead ? .regular : .semibold, design: .rounded))
            .foregroundStyle(notice.isRead ? AppColors.textSecondary : AppColors.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    // MARK: - Summary

    private var summaryText: some View {
        Text(notice.summary)
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textSecondary.opacity(0.8))
            .lineLimit(1)
    }

    // MARK: - Match Score

    private var matchScore: Int? {
        guard let profile = UserOnboardingProfile.load() else { return nil }
        let score = profile.matchScore(
            category: notice.category.rawValue,
            tags: notice.tags,
            noticeID: notice.id
        )
        return score >= 50 ? score : nil
    }

    // MARK: - Match Ring

    private func matchRing(score: Int) -> some View {
        let progress = Double(score) / 100.0
        let ringColor = score >= 80 ? Color(hex: 0x34C759) : Color(hex: 0x9B86B8)

        return ZStack {
            Circle()
                .stroke(ringColor.opacity(0.15), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(ringColor)
        }
        .frame(width: 32, height: 32)
    }

    // MARK: - Bottom Row

    private var bottomRow: some View {
        HStack(spacing: 12) {
            if notice.hasAttachment {
                HStack(spacing: 3) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 10))
                    Text("附件")
                        .font(.system(size: 11))
                }
                .foregroundStyle(AppColors.textSecondary.opacity(0.6))
            }

            Spacer()

            Text(notice.timeAgo)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(AppColors.textSecondary.opacity(0.6))
        }
    }
}
