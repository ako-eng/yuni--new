import SwiftUI

struct FavoritesView: View {
    private let store = NoticeStore.shared
    @State private var shareNoticeId: String?

    var body: some View {
        Group {
            if store.favoriteNotices.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(store.favoriteNotices) { notice in
                            NavigationLink(value: notice) {
                                favoriteRow(notice)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle("我的收藏")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Notice.self) { notice in
            NoticeDetailView(noticeId: notice.id, presentation: .pushed)
        }
        .environment(\.shareNoticeId, $shareNoticeId)
        .sheet(isPresented: shareSheetBinding) {
            shareSheetContent
        }
        .task {
            await store.ensureLoaded()
        }
    }

    private var shareSheetBinding: Binding<Bool> {
        Binding(
            get: { shareNoticeId != nil },
            set: { if !$0 { shareNoticeId = nil } }
        )
    }

    @ViewBuilder
    private var shareSheetContent: some View {
        if let id = shareNoticeId,
           let notice = store.notices.first(where: { $0.id == id }) {
            ShareActivitySheet(activityItems: ["\(notice.title)\n\(notice.summary)\n\(AppBranding.shareAttributionSuffix)"])
        }
    }

    private func favoriteRow(_ notice: Notice) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(notice.category.color)
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(notice.source)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(notice.category.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(notice.category.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.toggleFavorite(notice.id)
                        }
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.warmOrange)
                    }
                    .buttonStyle(.borderless)
                }

                Text(notice.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(notice.summary)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text(notice.timeAgo)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 12)
            .padding(.trailing, 4)
        }
        .padding(.trailing, 12)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            Text("暂无收藏的通知")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textSecondary)
            Text("浏览通知时点击星标即可收藏")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
