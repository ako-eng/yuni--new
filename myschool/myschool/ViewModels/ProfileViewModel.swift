import SwiftUI
import Observation

@Observable
class ProfileViewModel {
    var user = MockData.currentUser
    var isLoggedIn = true
    private let store = NoticeStore.shared

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
        isLoggedIn = false
        AppSession.shared.logout()
    }
}
