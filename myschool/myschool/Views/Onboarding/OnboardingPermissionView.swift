import SwiftUI

struct OnboardingPermissionView: View {
    var onDone: () -> Void

    @State private var contentOpacity = 0.0
    @State private var bellWobble = false

    private let benefits: [(icon: String, title: String, color: Color)] = [
        ("bolt.fill", "紧急通知实时推送", Color(hex: 0xFFAB40)),
        ("calendar.badge.clock", "考试安排定时提醒", Color(hex: 0x9B86B8)),
        ("sparkles", "个性化精准推荐", Color(hex: 0x34C759)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(Color(hex: 0xFFF8F5))
                        .symbolRenderingMode(.hierarchical)
                        .rotationEffect(.degrees(bellWobble ? 8 : -8))
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: bellWobble
                        )
                }

                VStack(spacing: 12) {
                    Text("开启通知")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("重要信息第一时间送达\n考试安排、紧急通知不再错过")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // 卖点图标行
                VStack(spacing: 14) {
                    ForEach(benefits, id: \.title) { benefit in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(benefit.color.opacity(0.2))
                                    .frame(width: 40, height: 40)

                                Image(systemName: benefit.icon)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(benefit.color)
                            }

                            Text(benefit.title)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 8)
            }

            Spacer()

            VStack(spacing: 14) {
                Button {
                    requestNotification()
                } label: {
                    Text("好的，开启通知")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x4A3F5C))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.white))
                        .shadow(color: Color(hex: 0x4A3F5C).opacity(0.15), radius: 8, y: 4)
                }

                Button(action: onDone) {
                    Text("以后再说")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { contentOpacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { bellWobble = true }
        }
    }

    private func requestNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async { onDone() }
        }
    }
}
