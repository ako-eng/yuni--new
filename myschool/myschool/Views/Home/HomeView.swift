import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var notificationManager = NotificationManager.shared
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var headerAppeared = false
    @State private var shareNoticeId: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppColors.background.ignoresSafeArea()

                headerBackground
                    .ignoresSafeArea(edges: .top)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        quickServiceSection
                        urgentNoticeSection
                        recommendSection
                        latestNoticeSection
                        officialFooter
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Notice.self) { notice in
                NoticeDetailView(noticeId: notice.id, presentation: .pushed)
            }
            .navigationDestination(for: NoticeCategory.self) { category in
                CategoryNoticeView(category: category)
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
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

    // MARK: - Header

    private var headerBackground: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: AppColors.campusBlue.opacity(0.08), location: 0),
                    .init(color: AppColors.campusBlue.opacity(0.05), location: 0.4),
                    .init(color: .clear, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                RadialGradient(
                    colors: [AppColors.campusBlue.opacity(0.06), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 300
                )
            )
            .overlay(
                RadialGradient(
                    colors: [AppColors.mintGreen.opacity(0.03), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 200
                )
            )
            .frame(height: 220)

            Spacer()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.greeting)，同学")
                        .font(AppFonts.title())
                        .foregroundStyle(AppColors.textPrimary)
                        .opacity(headerAppeared ? 1 : 0)
                        .offset(x: headerAppeared ? 0 : -20)

                    Text(viewModel.todayString)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                        .opacity(headerAppeared ? 1 : 0)
                        .offset(x: headerAppeared ? 0 : -10)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(AppColors.campusBlue.opacity(0.1))
                        .frame(width: 46, height: 46)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(AppColors.campusBlue.opacity(0.7))
                        .symbolRenderingMode(.hierarchical)
                }
                .scaleEffect(headerAppeared ? 1 : 0.5)
                .opacity(headerAppeared ? 1 : 0)
            }

            SearchBar(text: $searchText, onTap: { showSearch = true })
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 10)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .onAppear {
            withAnimation(AppleSpring.smooth) {
                headerAppeared = true
            }
        }
    }

    // MARK: - Quick Services

    private var quickServiceSection: some View {
        QuickServiceGrid(unreadCounts: viewModel.unreadCountByCategory)
            .scrollFade()
    }

    // MARK: - Urgent Notice

    @ViewBuilder
    private var urgentNoticeSection: some View {
        if let urgent = viewModel.urgentNotice, notificationManager.inAppUrgentNotice == nil {
            UrgentNoticeCard(notice: urgent)
                .padding(.horizontal, 16)
                .scrollFade()
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }

    // MARK: - Recommend

    private var recommendSection: some View {
        RecommendSection(notices: viewModel.recommendedNotices) {
            viewModel.refreshRecommendations()
        }
        .scrollFade()
    }

    // MARK: - Latest

    private var latestNoticeSection: some View {
        LatestNoticeList(notices: viewModel.latestNotices)
    }

    // MARK: - Footer

    private var officialFooter: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.mintGreen)
            Text("所有信息来源于学校官方平台")
                .font(AppFonts.smallCaption())
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
}

struct CategoryNoticeView: View {
    let category: NoticeCategory
    @State private var viewModel = NoticeViewModel()

    var body: some View {
        List {
            ForEach(viewModel.filteredNotices) { notice in
                NavigationLink(value: notice) {
                    NoticeRowView(notice: notice)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .background(AppColors.background)
        .navigationTitle(category.displayName + "通知")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.selectedCategory = category
        }
        .task {
            await NoticeStore.shared.ensureLoaded()
        }
    }
}
