import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Notice] = []
    @State private var showClearHistoryAlert = false
    @State private var shareNoticeId: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if searchText.isEmpty {
                    defaultContent
                } else {
                    resultsList
                }
            }
            .background(AppColors.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Notice.self) { notice in
                NoticeDetailView(noticeId: notice.id, presentation: .pushed)
            }
            .task {
                await NoticeStore.shared.ensureLoaded()
            }
        }
        .environment(\.shareNoticeId, $shareNoticeId)
        .sheet(isPresented: shareSheetBinding) {
            shareSheetContent
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
           let notice = NoticeStore.shared.notices.first(where: { $0.id == id }) {
            ShareActivitySheet(activityItems: ["\(notice.title)\n\(notice.summary)\n\(AppBranding.shareAttributionSuffix)"])
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.textSecondary)
                TextField("搜索通知、课程、服务...", text: $searchText)
                    .font(AppFonts.body())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { performSearch() }
                    .onChange(of: searchText) { performSearch() }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding(10)
            .background(AppColors.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )

            Button("取消") {
                dismiss()
            }
            .font(.system(size: 15))
            .foregroundStyle(AppColors.campusBlue)
        }
    }

    private var defaultContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if !MockData.searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("搜索历史")
                                .font(AppFonts.sectionTitle())
                            Spacer()
                            Button("清除") {
                                    showClearHistoryAlert = true
                                }
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.textSecondary)
                                .alert("确定清除搜索历史？", isPresented: $showClearHistoryAlert) {
                                    Button("取消", role: .cancel) {}
                                    Button("清除", role: .destructive) {}
                                }
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(MockData.searchHistory, id: \.self) { keyword in
                                Button {
                                    searchText = keyword
                                    performSearch()
                                } label: {
                                    Text(keyword)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(AppColors.cardWhite)
                                        .foregroundStyle(AppColors.textPrimary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.gray.opacity(0.15), lineWidth: 1))
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("热门搜索")
                        .font(AppFonts.sectionTitle())

                    FlowLayout(spacing: 8) {
                        ForEach(MockData.hotSearches, id: \.self) { keyword in
                            Button {
                                searchText = keyword
                                performSearch()
                            } label: {
                                Text(keyword)
                                    .font(.system(size: 13))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.lightBlue)
                                    .foregroundStyle(AppColors.campusBlue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            if searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                    Text("未找到相关结果")
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(searchResults) { notice in
                        NavigationLink(value: notice) {
                            NoticeRowView(notice: notice)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        let pool = NoticeStore.shared.notices
        searchResults = pool.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.summary.localizedCaseInsensitiveContains(searchText) ||
            $0.source.localizedCaseInsensitiveContains(searchText) ||
            $0.category.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flowLayout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func flowLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
