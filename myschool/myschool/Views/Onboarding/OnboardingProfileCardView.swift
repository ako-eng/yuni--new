import SwiftUI

struct OnboardingProfileCardView: View {
    let profile: OnboardingState
    var onEnter: () -> Void
    var onFeedback: (String) -> Void

    @State private var cardScale = 0.85
    @State private var cardOpacity = 0.0
    @State private var showFeedbackSheet = false
    @State private var feedbackText = ""
    @State private var quickFeedbackSelected: String?
    @State private var cupNodAngle: Double = 0
    @State private var showSubmittedMessage = false
    @Environment(\.displayScale) private var displayScale

    private var slogan: String {
        UserOnboardingProfile.generateSlogan(
            college: profile.college,
            categories: profile.selectedCategories.map(\.rawValue),
            tags: profile.selectedTags
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            profileCard
                .scaleEffect(cardScale)
                .opacity(cardOpacity)

            Spacer()

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Button(action: onEnter) {
                        Text("进入\(AppBranding.displayName)")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x4A3F5C))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color.white))
                            .shadow(color: Color(hex: 0x4A3F5C).opacity(0.15), radius: 8, y: 4)
                    }
                }

                Button {
                    saveCardToAlbum()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 13))
                        Text("保存到相册")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }

                Button {
                    showFeedbackSheet = true
                } label: {
                    Text("还不够懂我")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .sheet(isPresented: $showFeedbackSheet) {
            feedbackSheet
                .presentationDetents([.medium])
        }
        .onAppear {
            withAnimation(AppleSpring.bouncy.delay(0.15)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
    }

    @ViewBuilder
    private var profileCard: some View {
        VStack(spacing: 20) {
            // IP 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xC4B0DC).opacity(0.4), Color(hex: 0x9B86B8).opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color(hex: 0x6B5B7F))
            }

            HStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 16))
                Text("\(profile.college) · \(profile.grade)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundStyle(Color(hex: 0x6B5B7F))

            Text(slogan)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x3D2F4D))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)

            FlowLayout(spacing: 8) {
                ForEach(profile.selectedCategories) { cat in
                    HStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 10))
                        Text(cat.displayName)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(cat.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(cat.color.opacity(0.12))
                    )
                }
            }

            if !profile.selectedTags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(profile.selectedTags.prefix(5), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: 0x9B86B8))
                    }
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xF5EEFA), Color.white, Color(hex: 0xFFF8F5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: 0x4A3F5C).opacity(0.15), radius: 20, y: 10)
        )
        .padding(.horizontal, 28)
    }

    @MainActor
    private func saveCardToAlbum() {
        let renderer = ImageRenderer(content:
            profileCard
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x4A3F5C), Color(hex: 0x9B86B8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 380)
        )
        renderer.scale = displayScale

        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private var feedbackSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: 0x9B86B8))
                        .rotationEffect(.degrees(cupNodAngle))
                }
                .padding(.top, 10)

                if showSubmittedMessage {
                    Text("收到！马上按你的口味推荐")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x9B86B8))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("告诉芋泥你还关注什么？")
                        .font(.system(size: 17, weight: .bold, design: .rounded))

                    // 快捷选项
                    VStack(spacing: 10) {
                        quickOption("我最怕错过补考通知")
                        quickOption("我在找实习机会")
                        quickOption("社团活动我都想知道")
                        quickOption("奖学金评选别让我漏掉")
                    }

                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 80)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 4)

                    Button {
                        submitFeedback()
                    } label: {
                        Text("提交")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(Color(hex: 0x9B86B8))
                            )
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("补充偏好")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { showFeedbackSheet = false }
                }
            }
        }
    }

    private func quickOption(_ text: String) -> some View {
        Button {
            withAnimation(AppleSpring.snappy) {
                quickFeedbackSelected = text
                feedbackText = text
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                Spacer()
                if quickFeedbackSelected == text {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: 0x9B86B8))
                }
            }
            .foregroundStyle(quickFeedbackSelected == text ? Color(hex: 0x4A3F5C) : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(quickFeedbackSelected == text ? Color(hex: 0x9B86B8).opacity(0.12) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }

    private func submitFeedback() {
        let combined = feedbackText
        onFeedback(combined)

        withAnimation(.easeInOut(duration: 0.15).repeatCount(3, autoreverses: true)) {
            cupNodAngle = 5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.15)) { cupNodAngle = 0 }
        }

        withAnimation(AppleSpring.smooth.delay(0.5)) {
            showSubmittedMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showFeedbackSheet = false
            showSubmittedMessage = false
            feedbackText = ""
            quickFeedbackSelected = nil
        }
    }
}
