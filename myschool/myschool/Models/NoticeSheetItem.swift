import Foundation

/// 用于 `sheet(item:)` 的单一通知展示（避免双份 `Notice` 状态）
struct NoticeSheetItem: Identifiable, Hashable {
    let id: String
}
