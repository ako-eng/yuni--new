import SwiftUI
import Observation

@MainActor
@Observable
class NoticeStore {
    static let shared = NoticeStore()

    private enum Keys {
        static let readIds = "notice.readIds"
        static let favoriteIds = "notice.favoriteIds"
        static let subscribedCategories = "notice.subscribedCategories"
    }

    var notices: [Notice] = []
    var favoriteIds: Set<String> = []
    var subscribedCategories: Set<NoticeCategory>

    /// Pagination / API state
    var currentPage: Int = 0
    var totalPages: Int = 0
    var totalCount: Int = 0
    var isLoading: Bool = false
    /// 仅分页加载更多时为 true；与首屏/下拉刷新区分，避免刷新时误显示列表底部分页指示器导致布局异常。
    var isLoadingMore: Bool = false
    var hasMore: Bool = false
    var loadError: String?
    /// True when API failed and mock data is shown.
    var usingMockFallback: Bool = false
    /// 最近一次请求失败的系统错误简述（便于设置页排查，非完整 fallback 文案）。
    var lastConnectFailureSummary: String?

    /// Cached category stats from `GET /api/categories` (optional).
    var categoriesFromAPI: CategoriesResponse?

    private let perPage = 10

    private var readIds: Set<String> = []

    private init() {
        readIds = Set(UserDefaults.standard.stringArray(forKey: Keys.readIds) ?? [])
        if let saved = UserDefaults.standard.stringArray(forKey: Keys.favoriteIds) {
            favoriteIds = Set(saved)
        } else {
            favoriteIds = ["n001", "n002", "n004", "n006", "n009"]
        }
        if let raw = UserDefaults.standard.stringArray(forKey: Keys.subscribedCategories) {
            subscribedCategories = Set(raw.compactMap { NoticeCategory(rawValue: $0) })
        } else {
            subscribedCategories = Set(NoticeCategory.allCases)
        }
    }

    // MARK: - Read

    func markAsRead(_ id: String) {
        if let index = notices.firstIndex(where: { $0.id == id }) {
            notices[index].isRead = true
        }
        readIds.insert(id)
        persistReadIds()
    }

    func markAllAsRead() {
        for i in notices.indices {
            notices[i].isRead = true
            readIds.insert(notices[i].id)
        }
        persistReadIds()
    }

    var unreadCount: Int {
        notices.filter { !$0.isRead }.count
    }

    var unreadNotices: [Notice] {
        notices.filter { !$0.isRead }.sorted { $0.publishDate > $1.publishDate }
    }

    var readNotices: [Notice] {
        notices.filter { $0.isRead }.sorted { $0.publishDate > $1.publishDate }
    }

    func unreadCount(for category: NoticeCategory) -> Int {
        notices.filter { !$0.isRead && $0.category == category }.count
    }

    // MARK: - Favorites

    func isFavorited(_ id: String) -> Bool {
        favoriteIds.contains(id)
    }

    func toggleFavorite(_ id: String) {
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
        } else {
            favoriteIds.insert(id)
        }
        UserDefaults.standard.set(Array(favoriteIds), forKey: Keys.favoriteIds)
    }

    var favoriteNotices: [Notice] {
        notices.filter { favoriteIds.contains($0.id) }
            .sorted { $0.publishDate > $1.publishDate }
    }

    var favoriteCount: Int {
        favoriteIds.count
    }

    // MARK: - Subscriptions

    func isSubscribed(_ category: NoticeCategory) -> Bool {
        subscribedCategories.contains(category)
    }

    func toggleSubscription(_ category: NoticeCategory) {
        if subscribedCategories.contains(category) {
            subscribedCategories.remove(category)
        } else {
            subscribedCategories.insert(category)
        }
        UserDefaults.standard.set(subscribedCategories.map(\.rawValue), forKey: Keys.subscribedCategories)
    }

    var subscriptionCount: Int {
        subscribedCategories.count
    }

    // MARK: - Push Preferences

    var pushPreferences: [NoticeCategory: Bool] = {
        var prefs: [NoticeCategory: Bool] = [:]
        for category in NoticeCategory.allCases {
            prefs[category] = true
        }
        return prefs
    }()

    var allPushEnabled: Bool {
        get { pushPreferences.values.allSatisfy { $0 } }
        set { NoticeCategory.allCases.forEach { pushPreferences[$0] = newValue } }
    }

    func togglePush(for category: NoticeCategory) {
        pushPreferences[category]?.toggle()
    }

    // MARK: - API loading

    /// Loads first page if the list is empty and nothing is in flight.
    func ensureLoaded() async {
        guard notices.isEmpty, !isLoading, !isLoadingMore else { return }
        await loadInitial()
    }

    func loadInitial() async {
        guard !isLoading, !isLoadingMore else { return }
        isLoading = true
        loadError = nil
        usingMockFallback = false
        lastConnectFailureSummary = nil
        defer { isLoading = false }

        do {
            let (page, cats) = try await fetchFirstPageWithFallback()
            categoriesFromAPI = cats

            let mapped = page.items.map { NoticeMapping.notice(from: $0) }
            notices = mapped.map { mergeReadState($0) }
            currentPage = page.page
            totalPages = page.pages
            totalCount = page.total
            hasMore = page.page < page.pages
        } catch {
            lastConnectFailureSummary = (error as NSError).localizedDescription
            notices = MockData.notices.map { mergeReadState($0) }
            usingMockFallback = true
            loadError = Self.fallbackMessage(for: error, prefix: "无法连接通知服务")
            currentPage = 1
            totalPages = 1
            totalCount = notices.count
            hasMore = false
        }
    }

    func refresh() async {
        guard !isLoading, !isLoadingMore else { return }
        isLoading = true
        loadError = nil
        usingMockFallback = false
        lastConnectFailureSummary = nil
        defer { isLoading = false }

        do {
            let (page, cats) = try await fetchFirstPageWithFallback()
            categoriesFromAPI = cats

            let mapped = page.items.map { NoticeMapping.notice(from: $0) }
            notices = mapped.map { mergeReadState($0) }
            currentPage = page.page
            totalPages = page.pages
            totalCount = page.total
            hasMore = page.page < page.pages
        } catch {
            lastConnectFailureSummary = (error as NSError).localizedDescription
            notices = MockData.notices.map { mergeReadState($0) }
            usingMockFallback = true
            loadError = Self.fallbackMessage(for: error, prefix: "刷新失败")
            currentPage = 1
            totalPages = 1
            totalCount = notices.count
            hasMore = false
        }
    }

    /// 固定公网后端 `APIConfiguration.baseURL`，模拟器与真机一致。
    private func fetchFirstPageWithFallback() async throws -> (NoticesPageResponse, CategoriesResponse?) {
        let root = APIConfiguration.baseURL
        async let pageTask = APIService.shared.fetchNotices(page: 1, perPage: perPage, baseURL: root)
        async let catTask: CategoriesResponse? = {
            try? await APIService.shared.fetchCategories(baseURL: root)
        }()
        let page = try await pageTask
        let cats = await catTask
        return (page, cats)
    }

    func loadMore() async {
        guard hasMore, !isLoading, !isLoadingMore, !usingMockFallback else { return }
        let next = currentPage + 1
        isLoadingMore = true
        loadError = nil
        defer { isLoadingMore = false }

        do {
            let page = try await APIService.shared.fetchNotices(page: next, perPage: perPage)
            let mapped = page.items.map { NoticeMapping.notice(from: $0) }
            var seen = Set(notices.map(\.id))
            for n in mapped.map({ mergeReadState($0) }) where !seen.contains(n.id) {
                notices.append(n)
                seen.insert(n.id)
            }
            currentPage = page.page
            totalPages = page.pages
            totalCount = page.total
            hasMore = page.page < page.pages
        } catch {
            loadError = "加载更多失败：\(error.localizedDescription)（\(APIConfiguration.baseURLString)）"
        }
    }

    func fetchCategoriesIfNeeded() async {
        do {
            categoriesFromAPI = try await APIService.shared.fetchCategories()
        } catch {
            // optional; ignore
        }
    }

    func clearError() {
        loadError = nil
    }

    private static func fallbackMessage(for error: Error, prefix: String) -> String {
        let url = APIConfiguration.baseURLString
        let detail = error.localizedDescription
        let hint: String
        if detail.contains("Invalid control character") || detail.contains("JSON 解析失败") {
            hint = "接口已能连通，但返回的 JSON 不合法（多为后端 gdut_notices.json 里某条正文被错误换行）。请更新或修复该文件后重启 Flask，或重新运行爬虫。"
        } else {
            #if targetEnvironment(simulator)
            hint = "请确认 \(url) 上 Flask 已启动且可被本机访问。"
            #else
            if detail.contains("App Transport Security") || detail.lowercased().contains("secure connection") {
                hint = "这是系统拦截明文 HTTP（ATS）。请删除 App 后从 Xcode 重新安装最新构建。Safari 不受 ATS 限制。"
            } else {
                hint = "请确认 \(url) 服务已启动，且本机网络可访问该公网地址。"
            }
            #endif
        }
        return "\(prefix)\n\(url)\n\(detail)\n\(hint)\n已使用本地演示数据。"
    }

    private func mergeReadState(_ notice: Notice) -> Notice {
        var n = notice
        n.isRead = readIds.contains(n.id)
        return n
    }

    private func persistReadIds() {
        UserDefaults.standard.set(Array(readIds), forKey: Keys.readIds)
    }

    // MARK: - Simulate Push

    private var simulationCounter = 0

    private let simulatedUrgentNotices = [
        (title: "暴雨红色预警：校园临时停课通知", summary: "气象台发布暴雨红色预警，今日下午起全校停课，请同学们注意安全，避免外出。", source: "保卫处", category: NoticeCategory.security),
        (title: "校园网络安全事件紧急通报", summary: "近期发现针对校园网的钓鱼攻击，请立即修改教务系统密码，勿点击不明链接。", source: "信息中心", category: NoticeCategory.logistics),
        (title: "紧急：明日四六级考试考场变更通知", summary: "因教学楼消防检修，部分四六级考场临时调整，请相关考生立即查看新考场安排。", source: "教务处", category: NoticeCategory.exam),
    ]

    @discardableResult
    func simulateNewUrgentNotice() -> Notice {
        let template = simulatedUrgentNotices[simulationCounter % simulatedUrgentNotices.count]
        simulationCounter += 1

        let notice = Notice(
            id: "sim_\(UUID().uuidString.prefix(8))",
            title: template.title,
            summary: template.summary,
            content: template.summary,
            category: template.category,
            source: template.source,
            publishDate: Date(),
            isRead: false,
            isImportant: true,
            isUrgent: true,
            attachments: []
        )

        notices.insert(notice, at: 0)
        return notice
    }
}
