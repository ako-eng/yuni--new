import SwiftUI

@main
struct myschoolApp: App {
    @State private var themeManager = ThemeManager.shared
    private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasTriggeredSimulation = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    APIConfiguration.clearLegacyUserDefaults()
                    notificationManager.requestNotificationPermission()
                    notificationManager.checkOnLaunch()
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("[App] scenePhase -> active")
                notificationManager.handleReturnToForeground()
                if !hasTriggeredSimulation {
                    hasTriggeredSimulation = true
                    notificationManager.startSimulatedPush()
                }
            case .background:
                print("[App] scenePhase -> background")
            case .inactive:
                print("[App] scenePhase -> inactive")
            @unknown default:
                break
            }
        }
    }
}
