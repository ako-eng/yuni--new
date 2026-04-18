import Foundation
import Observation

@Observable
final class AppSession {
    static let shared = AppSession()

    enum RootPhase: Equatable {
        case splash
        case login
        case onboarding
        case main
    }

    private static let loggedInKey = "myschool.user.loggedIn"

    var phase: RootPhase = .splash

    var isLoggedIn: Bool {
        UserDefaults.standard.bool(forKey: Self.loggedInKey)
    }

    func finishSplash() {
        if isLoggedIn {
            if UserOnboardingProfile.hasCompleted {
                phase = .main
            } else {
                phase = .onboarding
            }
        } else {
            phase = .login
        }
    }

    func completeLogin() {
        UserDefaults.standard.set(true, forKey: Self.loggedInKey)
        if UserOnboardingProfile.hasCompleted {
            phase = .main
        } else {
            phase = .onboarding
        }
    }

    func completeOnboarding() {
        phase = .main
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: Self.loggedInKey)
        phase = .login
    }

    /// 从主界面再次进入 Onboarding（设置里「重新设置推荐偏好」）。
    func restartOnboardingFromMain() {
        UserOnboardingProfile.clear()
        phase = .onboarding
    }
}
