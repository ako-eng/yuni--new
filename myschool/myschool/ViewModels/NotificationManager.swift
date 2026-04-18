import SwiftUI
import ActivityKit
import UserNotifications
import Observation

/// 与 `NoticeStore` 配合：全局横幅/Live Activity 仅由本类驱动；首页 `UrgentNoticeCard` 在 `inAppUrgentNotice != nil` 时隐藏，避免重复强调同一条紧急通知。
@Observable
class NotificationManager {
    static let shared = NotificationManager()

    private var currentActivity: Activity<NoticeActivityAttributes>?
    private var hasCheckedOnLaunch = false

    var inAppUrgentNotice: Notice?

    private init() {
        reconnectExistingActivities()
    }

    // MARK: - Permissions

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("[NM] 通知权限: \(granted ? "已授权" : "未授权")")
        }
    }

    // MARK: - Reconnect

    private func reconnectExistingActivities() {
        let existing = Activity<NoticeActivityAttributes>.activities
        if let first = existing.first {
            currentActivity = first
            print("[NM] 重连已有 Live Activity: \(first.id)")
        }
    }

    // MARK: - Launch Detection

    func checkOnLaunch() {
        guard !hasCheckedOnLaunch else { return }
        hasCheckedOnLaunch = true
        reconnectExistingActivities()

        if currentActivity != nil {
            print("[NM] 已有活跃 Live Activity，跳过紧急通知检测")
            return
        }

        let store = NoticeStore.shared
        if let urgent = store.notices.first(where: { $0.isUrgent && !$0.isRead }) {
            print("[NM] 检测到未读紧急通知: \(urgent.title)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showUrgentNotice(urgent)
            }
        }
    }

    // MARK: - Foreground Resume

    func handleReturnToForeground() {
        reconnectExistingActivities()
    }

    // MARK: - Simulated Push

    func startSimulatedPush() {
        print("[NM] 模拟推送: 8s后紧急, 15s后普通")

        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            guard let self else { return }
            let newUrgent = NoticeStore.shared.simulateNewUrgentNotice()
            print("[NM] 触发紧急通知: \(newUrgent.title)")
            self.showUrgentNotice(newUrgent)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.sendLocalNotification(
                title: "教务处",
                body: "关于2026年暑期学期选课的通知，请同学们及时登录教务系统完成选课。"
            )
        }
    }

    // MARK: - Show Urgent Notice

    func showUrgentNotice(_ notice: Notice) {
        startLiveActivity(for: notice)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            inAppUrgentNotice = notice
        }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func dismissInAppNotice() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            inAppUrgentNotice = nil
        }
    }

    // MARK: - Live Activity (Real Dynamic Island)

    private func startLiveActivity(for notice: Notice) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[NM] Live Activities 不可用")
            return
        }

        endAllActivities()

        let attributes = NoticeActivityAttributes(
            noticeId: notice.id,
            title: notice.title,
            source: notice.source,
            categoryName: notice.category.displayName,
            categoryIcon: notice.category.icon
        )

        let state = NoticeActivityAttributes.ContentState(
            summary: notice.summary,
            timeString: "刚刚",
            isUrgent: notice.isUrgent
        )

        let content = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(4 * 60 * 60)
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("[NM] Live Activity 启动成功: \(currentActivity?.id ?? "")")
        } catch {
            print("[NM] Live Activity 启动失败: \(error)")
        }
    }

    func endLiveActivity() {
        guard let activity = currentActivity else { return }
        let finalState = NoticeActivityAttributes.ContentState(
            summary: "通知已查看",
            timeString: "",
            isUrgent: false
        )
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
        }
        currentActivity = nil
        print("[NM] Live Activity 已结束")
    }

    private func endAllActivities() {
        let existing = Activity<NoticeActivityAttributes>.activities
        guard !existing.isEmpty else { return }
        let finalState = NoticeActivityAttributes.ContentState(
            summary: "", timeString: "", isUrgent: false
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        for activity in existing {
            Task { await activity.end(content, dismissalPolicy: .immediate) }
        }
        currentActivity = nil
    }

    // MARK: - Local Notification

    func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[NM] 通知发送失败: \(error)") }
            else { print("[NM] 本地通知已发送") }
        }
    }
}
