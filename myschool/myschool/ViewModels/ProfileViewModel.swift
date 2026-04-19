import SwiftUI
import Observation

@Observable
class ProfileViewModel {
    private let store = NoticeStore.shared

    var name: String {
        AppSession.shared.name
    }

    var studentId: String {
        AppSession.shared.studentId
    }

    var department: String {
        AppSession.shared.department
    }

    var major: String {
        AppSession.shared.major
    }

    var grade: String {
        AppSession.shared.grade
    }

    var avatarName: String {
        "person.crop.circle.fill"
    }

    var isLoggedIn: Bool {
        AppSession.shared.isLoggedIn
    }

    var unreadMessageCount: Int { store.unreadCount }
    var favoriteCount: Int { store.favoriteCount }
    var subscriptionCount: Int { store.subscriptionCount }

    var pushPreferences: [NoticeCategory: Bool] {
        get { store.pushPreferences }
        set { store.pushPreferences = newValue }
    }

    var allPushEnabled: Bool {
        get { store.allPushEnabled }
        set { store.allPushEnabled = newValue }
    }

    func togglePush(for category: NoticeCategory) {
        store.togglePush(for: category)
    }

    func logout() {
        AppSession.shared.logout()
    }
}
