import SwiftUI

struct ContentView: View {
    @State private var session = AppSession.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var presentedNotice: NoticeSheetItem?

    var body: some View {
        Group {
            switch session.phase {
            case .splash:
                LaunchView(onFinished: { session.finishSplash() })
            case .onboarding:
                OnboardingFlowView(onFinished: { session.completeOnboarding() })
            case .login:
                LoginView(onLoginSuccess: { session.completeLogin() })
            case .main:
                mainChrome
            }
        }
        .id(session.phase)
    }

    private var mainChrome: some View {
        GeometryReader { geo in
            ZStack {
                MainTabView()

                if let notice = notificationManager.inAppUrgentNotice {
                    VStack {
                        UrgentNoticeBanner(
                            notice: notice,
                            containerWidth: geo.size.width,
                            onTap: {
                                notificationManager.dismissInAppNotice()
                                presentedNotice = NoticeSheetItem(id: notice.id)
                            },
                            onDismiss: {
                                notificationManager.dismissInAppNotice()
                            }
                        )
                        .padding(.top, geo.safeAreaInsets.top + 2)

                        Spacer()
                    }
                    .ignoresSafeArea()
                    .zIndex(999)
                }
            }
        }
        .onOpenURL { handleDeepLink($0) }
        .sheet(item: $presentedNotice) { item in
            NavigationStack {
                NoticeDetailView(noticeId: item.id, presentation: .sheet)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let noticeId = extractNoticeId(from: url) else { return }

        print("[DeepLink] 收到通知跳转: \(noticeId)")

        notificationManager.dismissInAppNotice()
        notificationManager.endLiveActivity()

        let store = NoticeStore.shared
        guard store.notices.contains(where: { $0.id == noticeId }) else {
            print("[DeepLink] 未找到通知: \(noticeId)")
            return
        }

        store.markAsRead(noticeId)
        Task { @MainActor in
            presentedNotice = NoticeSheetItem(id: noticeId)
        }
    }

    /// 支持 `myschool://notice/<id>` 等常见形态
    private func extractNoticeId(from url: URL) -> String? {
        guard url.scheme == "myschool" else { return nil }
        guard url.host == "notice" else { return nil }

        let parts = url.pathComponents.filter { $0 != "/" }
        if let last = parts.last, !last.isEmpty {
            return last
        }
        return nil
    }
}

#Preview("主界面") {
    MainTabView()
}

#Preview("启动页") {
    LaunchView(onFinished: {})
}
