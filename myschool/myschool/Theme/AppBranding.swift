import Foundation

/// 应用对外展示名称（与主屏幕 CFBundleDisplayName 一致）。
enum AppBranding {
    static let displayName = "芋泥uni"

    static var shareAttributionSuffix: String {
        "— 来自「\(displayName)」"
    }
}
