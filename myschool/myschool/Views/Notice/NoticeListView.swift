import SwiftUI

struct NoticeListView: View {
    @State private var viewModel = NoticeViewModel()
    @State private var store = NoticeStore.shared
    @State private var showSearch = false
    @State private var shareNoticeId: String?
    var embedded = false

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                NavigationStack {
                    content
                }
            }
        }
        .environment(\.shareNoticeId, $shareNoticeId)
        .sheet(isPresented: shareSheetBinding) {
            shareSheetContent
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if let msg = store.loadError {
                errorBanner(message: msg)
            }

            searchHeader
            NoticeFilterBar(
                selectedCategory: $viewModel.selectedCategory,
                sortByTime: $viewModel.sortByTime
            )
            .padding(.vertical, 8)

            noticeList
        }
        .background(AppColors.background)
        .navigationTitle("校园通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.showUnreadOnly.toggle()
                    } label: {
                        Label(
                            viewModel.showUnreadOnly ? "显示全部" : "只看未读",
                            systemImage: viewModel.showUnreadOnly ? "eye" : "eye.slash"
                        )
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(AppColors.campusBlue)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .navigationDestination(for: Notice.self) { notice in
            NoticeDetailView(noticeId: notice.id, presentation: .pushed)
        }
        .task {
            // 首次无数据时拉首屏；有数据时由 MainTabView 切到本 Tab 时 refresh，避免与首页重复请求逻辑冲突。
            await store.ensureLoaded()
        }
        .refreshable {
            await store.refresh()
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: store.usingMockFallback ? "wifi.slash" : "exclamationmark.triangle.fill")
                .foregroundStyle(store.usingMockFallback ? AppColors.textSecondary : AppColors.softRed)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("知道了") {
                store.clearError()
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(AppColors.campusBlue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(store.usingMockFallback ? AppColors.cardWhite : AppColors.softRed.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
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
           let notice = NoticeStore.shared.notices.first(where: { $0.id == id }) {
            ShareActivitySheet(activityItems: ["\(notice.title)\n\(notice.summary)\n\(AppBranding.shareAttributionSuffix)"])
        }
    }

    private var searchHeader: some View {
        SearchBar(text: $viewModel.searchText, onTap: { showSearch = true })
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    private var noticeListIdentity: String {
        viewModel.filteredNotices.map(\.id).joined(separator: "|")
    }

    private var noticeList: some View {
        ScrollView(showsIndicators: false) {
            // `LazyVStack` 在刷新后整批替换、且行高随标题换行变化时，偶发中段大块空白。
            // 通知页首屏数据量不大，改用普通 `VStack` 并在数据顺序变化时重建布局更稳定。
            VStack(spacing: 10) {
                if store.isLoading && store.notices.isEmpty {
                    ProgressView()
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                }

                ForEach(viewModel.filteredNotices) { notice in
                    NavigationLink(value: notice) {
                        NoticeRowView(notice: notice)
                    }
                    .buttonStyle(PressableButtonStyle(scaleAmount: 0.98))
                    .onAppear {
                        if notice.id == viewModel.filteredNotices.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }

                if viewModel.filteredNotices.isEmpty && !store.isLoading {
                    emptyState
                }

                if viewModel.isLoadingMore && viewModel.hasMore && !viewModel.filteredNotices.isEmpty {
                    ProgressView()
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                }
            }
            .id(noticeListIdentity)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                .symbolRenderingMode(.hierarchical)
            Text("暂无相关通知")
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
