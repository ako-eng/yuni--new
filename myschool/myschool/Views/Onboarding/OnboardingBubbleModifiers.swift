import SwiftUI

/// 偏好引导四屏共用的「芋泥气泡」选中态：选中略放大、未选略缩略淡；减弱动态效果时只做透明度。
enum OnboardingBubbleStyle {
    /// 学院级联行
    case compactRow
    /// 年级小格
    case grade
    /// 类别大卡
    case categoryCard
    /// 标签胶囊
    case tagChip
    /// 偏好页全屏飘动气泡池
    case floatingPool
}

struct OnboardingBubbleSelectionModifier: ViewModifier {
    let isSelected: Bool
    let style: OnboardingBubbleStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var scaleSelected: CGFloat {
        switch style {
        case .compactRow, .grade: return 1.0
        case .categoryCard: return 1.0
        case .tagChip: return 1.1
        case .floatingPool: return 1.0
        }
    }

    private var scaleUnselected: CGFloat {
        switch style {
        case .compactRow: return 0.94
        case .grade: return 0.90
        case .categoryCard: return 0.93
        case .tagChip: return 0.88
        case .floatingPool: return 0.92
        }
    }

    private var opacitySelected: Double { 1.0 }
    private var opacityUnselected: Double {
        switch style {
        case .compactRow: return 0.88
        case .grade: return 0.82
        case .categoryCard: return 0.85
        case .tagChip: return 0.80
        case .floatingPool: return 0.84
        }
    }

    func body(content: Content) -> some View {
        let scale = reduceMotion ? 1.0 : (isSelected ? scaleSelected : scaleUnselected)
        let opacity = isSelected ? opacitySelected : (reduceMotion ? opacityUnselected : opacityUnselected)
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: isSelected)
    }
}

/// 未选卡片稳定微倾（Reduce Motion 关闭）
struct OnboardingBubbleTiltModifier: ViewModifier {
    let stableKey: String
    let isSelected: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tiltDegrees: Double {
        guard !isSelected, !reduceMotion else { return 0 }
        let h = abs(stableKey.hashValue % 21)
        return Double(h) / 10.0 - 1.0
    }

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(tiltDegrees))
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isSelected)
    }
}

extension View {
    func onboardingBubbleSelection(isSelected: Bool, style: OnboardingBubbleStyle) -> some View {
        modifier(OnboardingBubbleSelectionModifier(isSelected: isSelected, style: style))
    }

    func onboardingBubbleTilt(stableKey: String, isSelected: Bool) -> some View {
        modifier(OnboardingBubbleTiltModifier(stableKey: stableKey, isSelected: isSelected))
    }
}
