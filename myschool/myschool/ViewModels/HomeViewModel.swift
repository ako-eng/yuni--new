import SwiftUI
import Observation

@Observable
class HomeViewModel {
    private let store = NoticeStore.shared
    var searchText = ""
    var recommendedNotices: [Notice] = []
    private var recommendPool: [Notice] = []
    private var recommendIndex = 0
    private let recommendBatchSize = 3

    var allNotices: [Notice] { store.notices }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "早上好"
        case 12..<14: return "中午好"
        case 14..<18: return "下午好"
        case 18..<23: return "晚上好"
        default: return "夜深了"
        }
    }

    var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }

    var unreadCountByCategory: [NoticeCategory: Int] {
        Dictionary(grouping: allNotices.filter { !$0.isRead }, by: \.category)
            .mapValues(\.count)
    }

    var urgentNotice: Notice? {
        allNotices.first { $0.isUrgent && !$0.isRead }
    }

    var latestNotices: [Notice] {
        Array(allNotices.sorted { $0.publishDate > $1.publishDate }.prefix(5))
    }

    init() {
        rebuildPool()
        Task { @MainActor in
            await NoticeStore.shared.ensureLoaded()
            rebuildPool()
        }
    }

    func refreshRecommendations() {
        if recommendPool.isEmpty {
            rebuildPool()
            return
        }

        let start = recommendIndex
        let end = min(start + recommendBatchSize, recommendPool.count)

        if start >= recommendPool.count {
            rebuildPool()
            return
        }

        recommendedNotices = Array(recommendPool[start..<end])
        recommendIndex = end

        if recommendIndex >= recommendPool.count {
            recommendIndex = 0
            recommendPool.shuffle()
        }
    }

    private func rebuildPool() {
        if let profile = UserOnboardingProfile.load() {
            recommendPool = allNotices
                .filter {
                    profile.matchScore(
                        category: $0.category.rawValue,
                        tags: $0.tags,
                        noticeID: $0.id
                    ) >= 50
                }
                .shuffled()
        } else {
            recommendPool = []
        }

        recommendIndex = 0
        let end = min(recommendBatchSize, recommendPool.count)
        recommendedNotices = Array(recommendPool[0..<end])
        recommendIndex = end
    }

    func markAsRead(_ notice: Notice) {
        store.markAsRead(notice.id)
    }
}
