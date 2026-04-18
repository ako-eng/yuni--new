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
    private static let studentIdKey = "myschool.user.studentId"
    private static let nameKey = "myschool.user.name"
    private static let departmentKey = "myschool.user.department"
    private static let majorKey = "myschool.user.major"
    private static let gradeKey = "myschool.user.grade"

    var phase: RootPhase = .splash

    var isLoggedIn: Bool {
        UserDefaults.standard.bool(forKey: Self.loggedInKey)
    }

    var studentId: String {
        get { UserDefaults.standard.string(forKey: Self.studentIdKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Self.studentIdKey) }
    }

    var name: String {
        get { UserDefaults.standard.string(forKey: Self.nameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Self.nameKey) }
    }

    var department: String {
        get { UserDefaults.standard.string(forKey: Self.departmentKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Self.departmentKey) }
    }

    var major: String {
        get { UserDefaults.standard.string(forKey: Self.majorKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Self.majorKey) }
    }

    var grade: String {
        get { UserDefaults.standard.string(forKey: Self.gradeKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Self.gradeKey) }
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

    func completeLogin(studentId: String, name: String, department: String, major: String, grade: String) {
        UserDefaults.standard.set(true, forKey: Self.loggedInKey)
        self.studentId = studentId
        self.name = name
        self.department = department
        self.major = major
        self.grade = grade
        if UserOnboardingProfile.hasCompleted {
            phase = .main
        } else {
            phase = .onboarding
        }
    }

    func updateUserInfo(department: String, major: String, grade: String) {
        self.department = department
        self.major = major
        self.grade = grade
    }

    func completeOnboarding() {
        phase = .main
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: Self.loggedInKey)
        UserDefaults.standard.removeObject(forKey: Self.studentIdKey)
        UserDefaults.standard.removeObject(forKey: Self.nameKey)
        UserDefaults.standard.removeObject(forKey: Self.departmentKey)
        UserDefaults.standard.removeObject(forKey: Self.majorKey)
        UserDefaults.standard.removeObject(forKey: Self.gradeKey)
        phase = .login
    }

    /// 从主界面再次进入 Onboarding（设置里「重新设置推荐偏好」）。
    func restartOnboardingFromMain() {
        UserOnboardingProfile.clear()
        phase = .onboarding
    }
}
