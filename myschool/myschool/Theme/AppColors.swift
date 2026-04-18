import SwiftUI

enum AppColors {

    // MARK: - Accent Colors

    static let campusBlue = Color(hex: 0x007AFF)
    static let mintGreen = Color(hex: 0x34C759)
    static let warmOrange = Color(hex: 0xFF9500)
    static let softRed = Color(hex: 0xFF3B30)

    // MARK: - Gradients

    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0x007AFF), Color(hex: 0x5AC8FA)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [Color(hex: 0xFF9500), Color(hex: 0xFFCC00)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Adaptive Colors

    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)   // #F2F2F7
    })

    static let cardWhite = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)   // #1C1C1E
            : UIColor.white
    })

    static let textPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
            : UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
    })

    static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1)   // #8E8E93
            : UIColor(red: 0.24, green: 0.24, blue: 0.26, alpha: 1)   // #3C3C43 60%
    })

    static let separatorLight = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.33, green: 0.33, blue: 0.35, alpha: 0.6)
            : UIColor(red: 0.24, green: 0.24, blue: 0.26, alpha: 0.12)
    })

    static let lightBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.18, blue: 0.27, alpha: 1)
            : UIColor(red: 0.92, green: 0.95, blue: 0.99, alpha: 1)
    })

    // MARK: - iMessage-style chat (芋泥助手)

    /// 对话列表背景，对齐系统「信息」分组灰底。
    static let iMessageChatBackground = Color(uiColor: .systemGroupedBackground)

    /// 出站气泡：与系统 iMessage 蓝一致（同 campusBlue）。
    static let iMessageOutgoingBubble = campusBlue

    /// 入站气泡（助手 / 思考）：secondarySystemFill
    static let iMessageIncomingBubble = Color(uiColor: .secondarySystemFill)

    /// 输入框胶囊背景
    static let iMessageInputFieldFill = Color(uiColor: .systemBackground)

    /// 发送按钮禁用灰底
    static let iMessageSendDisabledFill = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.35, alpha: 1)
            : UIColor(white: 0.88, alpha: 1)
    })

    // MARK: - Course Colors

    static let courseColors: [Color] = [
        Color(hex: 0x5AC8FA),
        Color(hex: 0x34C759),
        Color(hex: 0xFF9500),
        Color(hex: 0xAF52DE),
        Color(hex: 0xFF2D55),
        Color(hex: 0x30D158),
        Color(hex: 0xFFCC00),
        Color(hex: 0x64D2FF),
    ]
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
