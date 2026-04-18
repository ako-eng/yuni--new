import SwiftUI

private struct ShareNoticeIdKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

extension EnvironmentValues {
    /// 由列表页注入；行内「分享」写入 id，由父级统一 `sheet` 弹出系统分享。
    var shareNoticeId: Binding<String?> {
        get { self[ShareNoticeIdKey.self] }
        set { self[ShareNoticeIdKey.self] = newValue }
    }
}
