import SwiftUI

struct MessageCenterView: View {
    private let store = NoticeStore.shared
    @State private var selectedTab = 0
    @State private var shareNoticeId: String?

    var body: some View {
        VStack(spacing: 0) {
            picker
            tabContent
        }
        .background(AppColors.background)
        .navigationTitle("消息中心")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Notice.self) { notice in
            NoticeDetailView(noticeId: notice.id, presentation: .pushed)
        }
        .environment(\.shareNoticeId, $shareNoticeId)
        .sheet(isPresented: shareSheetBinding) {
            shareSheetContent
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.unreadCount > 0 {
                    Button("全部已读") {
                        withAnimation { store.markAllAsRead() }
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.campusBlue)
                }
            }
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

    private var picker: some View {
        HStack(spacing: 0) {
            tabButton(title: "未读", count: store.unreadCount, index: 0)
            tabButton(title: "已读", count: store.readNotices.count, index: 1)
        }
        .padding(4)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func tabButton(title: String, count: Int, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: selectedTab == index ? .semibold : .regular))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(selectedTab == index ? AppColors.campusBlue : AppColors.textSecondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            (selectedTab == index ? AppColors.campusBlue : AppColors.textSecondary)
                                .opacity(0.12)
                        )
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(selectedTab == index ? AppColors.campusBlue : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedTab == index ? AppColors.cardWhite : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        let items = selectedTab == 0 ? store.unreadNotices : store.readNotices
        if items.isEmpty {
            emptyState
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(items) { notice in
                        NavigationLink(value: notice) {
                            NoticeRowView(notice: notice)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: selectedTab == 0 ? "checkmark.circle" : "tray")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            Text(selectedTab == 0 ? "没有未读消息" : "没有已读消息")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
