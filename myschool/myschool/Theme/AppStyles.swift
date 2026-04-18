import SwiftUI

// MARK: - Apple-Grade Spring Presets

enum AppleSpring {
    static let smooth: Animation = .spring(response: 0.55, dampingFraction: 0.825)
    static let snappy: Animation = .spring(response: 0.35, dampingFraction: 0.85)
    static let gentle: Animation = .spring(response: 0.7, dampingFraction: 0.9)
    static let bouncy: Animation = .spring(response: 0.5, dampingFraction: 0.65)
    static let interactive: Animation = .spring(response: 0.28, dampingFraction: 0.82)
}

// MARK: - Card

struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppColors.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.04),
                radius: 1, x: 0, y: 1
            )
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.06),
                radius: 10, x: 0, y: 4
            )
    }
}

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: colorScheme == .dark ? .white.opacity(0.02) : .black.opacity(0.06),
                radius: 12, x: 0, y: 4
            )
    }
}

// MARK: - Chip / Button

struct ChipModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.campusBlue : AppColors.background)
            .foregroundStyle(isSelected ? .white : AppColors.textPrimary)
            .clipShape(Capsule())
            .animation(AppleSpring.snappy, value: isSelected)
    }
}

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColors.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Press Animation

struct PressableButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(AppleSpring.interactive, value: configuration.isPressed)
    }
}

struct ScalePressModifier: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(AppleSpring.interactive, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Staggered Appear (Refined)

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.95)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                let delay = Double(index) * 0.05
                withAnimation(AppleSpring.smooth.delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Shimmer

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 300)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Bounce Appear

struct BounceAppearModifier: ViewModifier {
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1.0 : 0)
            .onAppear {
                withAnimation(AppleSpring.bouncy) {
                    appeared = true
                }
            }
    }
}

// MARK: - Breathing Glow

struct BreathingGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var glowing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowing ? 0.4 : 0.1), radius: glowing ? radius : radius * 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}

// MARK: - Scroll Fade

struct ScrollFadeModifier: ViewModifier {
    func body(content: Content) -> some View {
        // 仅用轻微透明度；勿对 LazyVStack 内行使用 scale/offset，易在刷新后出现大块空白错位（iOS 17+ scrollTransition）。
        content
            .scrollTransition(.animated(AppleSpring.smooth)) { view, phase in
                view.opacity(phase.isIdentity ? 1 : 0.92)
            }
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }

    func chipStyle(isSelected: Bool) -> some View {
        modifier(ChipModifier(isSelected: isSelected))
    }

    func primaryButtonStyle() -> some View {
        modifier(PrimaryButtonModifier())
    }

    func pressable(scale: CGFloat = 0.97) -> some View {
        modifier(ScalePressModifier(scale: scale))
    }

    func staggerAppear(index: Int, total: Int = 10) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func bounceAppear() -> some View {
        modifier(BounceAppearModifier())
    }

    func breathingGlow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        modifier(BreathingGlowModifier(color: color, radius: radius))
    }

    func scrollFade() -> some View {
        modifier(ScrollFadeModifier())
    }
}
