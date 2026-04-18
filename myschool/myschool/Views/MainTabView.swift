import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    private let store = NoticeStore.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            ScheduleView()
                .tabItem {
                    Label("课表", systemImage: selectedTab == 1 ? "calendar.circle.fill" : "calendar")
                }
                .tag(1)

            MockAIChatView()
                .tabItem {
                    Label("芋泥助手", systemImage: selectedTab == 2 ? "ellipsis.bubble.fill" : "ellipsis.bubble")
                }
                .tag(2)

            NoticeListView()
                .tabItem {
                    Label("通知", systemImage: selectedTab == 3 ? "bell.fill" : "bell")
                }
                .tag(3)
                .badge(store.unreadCount > 0 ? store.unreadCount : 0)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .tint(AppColors.campusBlue)
        .onChange(of: selectedTab) { oldValue, newValue in
            previousTab = oldValue
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.5)
            // 首页会先 ensureLoaded，通知页若仍用 ensureLoaded 会因列表非空而跳过请求；每次点进「通知」拉最新列表。
            if newValue == 3 {
                Task { await store.refresh() }
            }
        }
    }
}
