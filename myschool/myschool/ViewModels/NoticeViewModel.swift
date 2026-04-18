import SwiftUI
import Observation

@Observable
class NoticeViewModel {
    private let store = NoticeStore.shared

    var searchText = ""
    var selectedCategory: NoticeCategory?
    var sortByTime = true
    var showUnreadOnly = false

    var allNotices: [Notice] { store.notices }

    var isLoading: Bool { store.isLoading }
    var isLoadingMore: Bool { store.isLoadingMore }
    var loadError: String? { store.loadError }
    var hasMore: Bool { store.hasMore }
    var usingMockFallback: Bool { store.usingMockFallback }

    func loadMore() async {
        await store.loadMore()
    }

    var filteredNotices: [Notice] {
        var result = allNotices

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText) ||
                $0.source.localizedCaseInsensitiveContains(searchText)
            }
        }

        if showUnreadOnly {
            result = result.filter { !$0.isRead }
        }

        if sortByTime {
            result.sort { $0.publishDate > $1.publishDate }
        } else {
            result.sort { lhs, rhs in
                let lhsPriority = (lhs.isUrgent ? 2 : 0) + (lhs.isImportant ? 1 : 0)
                let rhsPriority = (rhs.isUrgent ? 2 : 0) + (rhs.isImportant ? 1 : 0)
                if lhsPriority != rhsPriority { return lhsPriority > rhsPriority }
                return lhs.publishDate > rhs.publishDate
            }
        }

        return result
    }

    var unreadCount: Int { store.unreadCount }

    func markAsRead(_ notice: Notice) {
        store.markAsRead(notice.id)
    }
}
