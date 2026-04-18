import SwiftUI

struct LaunchView: View {
    var onFinished: () -> Void

    @State private var iconScale = 0.6
    @State private var iconOpacity = 0.0
    @State private var iconBlur = 15.0
    @State private var titleOffset: CGFloat = 16
    @State private var titleOpacity = 0.0
    @State private var subtitleOpacity = 0.0
    @State private var ringScale = 0.85
    @State private var ringOpacity = 0.0
    @State private var gradientRotation = 0.0
    @State private var blobOffset: CGFloat = 0

    // 芋泥倒入动画
    @State private var dropOffset1: CGFloat = -80
    @State private var dropOffset2: CGFloat = -100
    @State private var dropOffset3: CGFloat = -60
    @State private var dropOpacity: Double = 0.0

    // 涟漪效果
    @State private var ripple1Scale: CGFloat = 0.5
    @State private var ripple1Opacity: Double = 0.6
    @State private var ripple2Scale: CGFloat = 0.5
    @State private var ripple2Opacity: Double = 0.6

    // Slogan 打字机
    @State private var sloganText = ""
    private let fullSlogan = "通知 · 课表 · 服务，都在这一杯里"

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xE8D4F5).opacity(0.45), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                )
                .frame(width: 420, height: 420)
                .offset(x: blobOffset * 0.3, y: blobOffset * 0.2)
                .blur(radius: 8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xFFF5F0).opacity(0.25), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: -blobOffset * 0.2, y: 40)
                .blur(radius: 6)

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    // 涟漪
                    Circle()
                        .stroke(Color.white.opacity(ripple1Opacity * 0.3), lineWidth: 1.5)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ripple1Scale)

                    Circle()
                        .stroke(Color.white.opacity(ripple2Opacity * 0.2), lineWidth: 1)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ripple2Scale)

                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 158, height: 158)
                        .scaleEffect(ringScale * 0.96)
                        .opacity(ringOpacity * 0.55)

                    // 芋泥「倒入」液滴
                    Group {
                        Circle()
                            .fill(Color(hex: 0xC4B0DC).opacity(0.5))
                            .frame(width: 10, height: 10)
                            .offset(x: -6, y: dropOffset1)
                            .blur(radius: 2)

                        Circle()
                            .fill(Color(hex: 0xE8D4F5).opacity(0.4))
                            .frame(width: 14, height: 14)
                            .offset(x: 4, y: dropOffset2)
                            .blur(radius: 3)

                        Circle()
                            .fill(Color(hex: 0x9B86B8).opacity(0.35))
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: dropOffset3)
                            .blur(radius: 2)
                    }
                    .opacity(dropOpacity)

                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(Color(hex: 0xFFF8F5))
                        .shadow(color: Color(hex: 0x4A3A5C).opacity(0.28), radius: 8, y: 4)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        .blur(radius: iconBlur)
                }

                VStack(spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("芋泥")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("uni")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .italic()
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0xFFFDFB), Color(hex: 0xF0E6FA)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: 0x3D2F4D).opacity(0.35), radius: 2, y: 2)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                    Text("软糯校园 · 一口掌握")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .opacity(subtitleOpacity)
                }

                Spacer()

                Text(sloganText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.bottom, 52)
                    .frame(minHeight: 20)
            }
        }
        .onAppear { startAnimationSequence() }
    }

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x4A3F5C),
                    Color(hex: 0x6B5B7F),
                    Color(hex: 0x9B86B8),
                    Color(hex: 0xC4B0DC),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AngularGradient(
                colors: [
                    .clear,
                    Color(hex: 0xE8D4F5).opacity(0.12),
                    .clear,
                    Color.white.opacity(0.06),
                    .clear,
                ],
                center: .center,
                angle: .degrees(gradientRotation)
            )
        }
    }

    private func startAnimationSequence() {
        withAnimation(.easeOut(duration: 1.6).delay(0.08)) {
            gradientRotation = 110
            blobOffset = 12
        }

        // 液滴倒入
        withAnimation(.easeIn(duration: 0.3).delay(0.05)) {
            dropOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.1)) {
            dropOffset1 = 0
        }
        withAnimation(.easeIn(duration: 0.55).delay(0.15)) {
            dropOffset2 = 5
        }
        withAnimation(.easeIn(duration: 0.45).delay(0.2)) {
            dropOffset3 = -2
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
            dropOpacity = 0
        }

        withAnimation(AppleSpring.smooth.delay(0.12)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconBlur = 0
        }

        withAnimation(AppleSpring.gentle.delay(0.22)) {
            ringScale = 1.0
            ringOpacity = 1.0
        }

        // 涟漪循环
        startRipples()

        withAnimation(AppleSpring.smooth.delay(0.42)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.62)) {
            subtitleOpacity = 1.0
        }

        // 打字机效果
        startTypewriter(delay: 0.85)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(AppleSpring.gentle) {
                onFinished()
            }
        }
    }

    private func startRipples() {
        withAnimation(.easeOut(duration: 1.8).delay(0.5).repeatForever(autoreverses: false)) {
            ripple1Scale = 1.8
            ripple1Opacity = 0
        }
        withAnimation(.easeOut(duration: 1.8).delay(1.1).repeatForever(autoreverses: false)) {
            ripple2Scale = 1.6
            ripple2Opacity = 0
        }
    }

    private func startTypewriter(delay startDelay: Double) {
        let chars = Array(fullSlogan)
        for (i, _) in chars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(i) * 0.06) {
                sloganText = String(chars.prefix(i + 1))
            }
        }
    }
}
