import ActivityKit
import Foundation

struct NoticeActivityAttributes: ActivityAttributes {
    let noticeId: String
    let title: String
    let source: String
    let categoryName: String
    let categoryIcon: String

    struct ContentState: Codable, Hashable {
        let summary: String
        let timeString: String
        let isUrgent: Bool
    }
}
