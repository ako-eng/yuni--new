import SwiftUI

struct OnboardingGreetView: View {
    var onNext: () -> Void

    @State private var cupScale = 0.3
    @State private var cupOpacity = 0.0
    @State private var bubbleOpacity = 0.0
    @State private var bubbleOffset: CGFloat = 20
    @State private var buttonOpacity = 0.0
    @State private var steamPhase = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(steamPhase ? 0 : 0.25))
                            .frame(width: 8, height: 8)
                            .offset(
                                x: CGFloat([-8, 4, 10][i]),
                                y: steamPhase ? -40 : -8
                            )
                            .animation(
                                .easeOut(duration: 2.0)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.4),
                                value: steamPhase
                            )
                    }
                    .offset(y: -50)

                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: 0xFFF8F5), Color(hex: 0xEDE4F7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: 0x4A3A5C).opacity(0.35), radius: 12, y: 6)

                    // IP 微笑弧线
                    SmilePath()
                        .stroke(Color(hex: 0x9B86B8), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 24, height: 10)
                        .offset(y: -4)
                }
                .scaleEffect(cupScale)
                .opacity(cupOpacity)
            }

            VStack(spacing: 16) {
                Text("Hi~ 我是芋泥！")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("大学通知太多太杂？\n让我帮你整理，30 秒搞定")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .offset(y: bubbleOffset)
            .opacity(bubbleOpacity)
            .padding(.top, 36)

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onNext()
            }) {
                Text("来吧，30 秒搞定")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x4A3F5C))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(Color.white)
                    )
                    .shadow(color: Color(hex: 0x4A3F5C).opacity(0.2), radius: 8, y: 4)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
            .opacity(buttonOpacity)
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(AppleSpring.bouncy.delay(0.15)) {
            cupScale = 1.0
            cupOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            steamPhase = true
        }

        withAnimation(AppleSpring.smooth.delay(0.5)) {
            bubbleOpacity = 1.0
            bubbleOffset = 0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
            buttonOpacity = 1.0
        }
    }
}

private struct SmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}
