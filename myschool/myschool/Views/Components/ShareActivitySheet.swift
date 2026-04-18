import SwiftUI
import UIKit

/// 系统分享面板（从列表父级统一弹出，避免行视图内嵌 sheet 与列表复用冲突）
struct ShareActivitySheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
