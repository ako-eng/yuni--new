import SwiftUI

struct OnboardingFlowView: View {
    var onFinished: () -> Void

    @State private var currentStep = 0
    @State private var profile = OnboardingState()

    private let totalSteps = 7

    var body: some View {
        ZStack {
            taroGradientBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if currentStep > 0 && currentStep < 5 {
                    progressBar
                        .padding(.top, 8)
                        .padding(.horizontal, 40)
                }

                TabView(selection: $currentStep) {
                    OnboardingGreetView(onNext: { advanceTo(1) })
                        .tag(0)

                    OnboardingSchoolView(
                        selectedCollege: $profile.college,
                        selectedMajor: $profile.major,
                        selectedGrade: $profile.grade,
                        onNext: { advanceTo(2) }
                    )
                    .tag(1)

                    OnboardingPreferenceView(
                        selectedCategories: $profile.selectedCategories,
                        onNext: { advanceTo(3) }
                    )
                    .tag(2)

                    OnboardingTagsView(
                        selectedTags: $profile.selectedTags,
                        onNext: { advanceTo(4) },
                        onSkip: { advanceTo(4) }
                    )
                    .tag(3)

                    OnboardingMatchingView(
                        categories: profile.selectedCategories.map(\.rawValue),
                        onDone: { advanceTo(5) }
                    )
                    .tag(4)

                    OnboardingProfileCardView(
                        profile: profile,
                        onEnter: { advanceTo(6) },
                        onFeedback: { note in
                            profile.additionalNote = note
                        }
                    )
                    .tag(5)

                    OnboardingPermissionView(onDone: { finishOnboarding() })
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppleSpring.smooth, value: currentStep)
            }
        }
    }

    /// 步骤 1…4（学院 / 偏好 / 标签 / 匹配）对应连续填充，与 Tab 切换同步动画。
    private var preferenceSegmentProgress: CGFloat {
        guard currentStep > 0 && currentStep < 5 else { return 0 }
        return CGFloat(currentStep) / 4.0
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let fillW = max(6, geo.size.width * preferenceSegmentProgress)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.25))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.98), Color.white.opacity(0.78)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillW)
                    .animation(AppleSpring.smooth, value: currentStep)
                    .overlay(alignment: .trailing) {
                        if preferenceSegmentProgress > 0.04 {
                            Circle()
                                .fill(Color.white.opacity(0.55))
                                .frame(width: 7, height: 7)
                                .offset(x: -1)
                        }
                    }
            }
        }
        .frame(height: 6)
    }

    private var taroGradientBackground: some View {
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
    }

    private func advanceTo(_ step: Int) {
        withAnimation(AppleSpring.smooth) {
            currentStep = step
        }
    }

    private func finishOnboarding() {
        let slogan = UserOnboardingProfile.generateSlogan(
            college: profile.college,
            categories: profile.selectedCategories.map(\.rawValue),
            tags: profile.selectedTags
        )
        var saved = UserOnboardingProfile(
            college: profile.college,
            major: profile.major,
            grade: profile.grade,
            preferredCategories: profile.selectedCategories.map(\.rawValue),
            preferredTags: profile.selectedTags,
            profileSlogan: slogan,
            additionalNote: profile.additionalNote,
            completedAt: Date()
        )
        saved.save()

        var store = NoticeStore.shared
        store.subscribedCategories = Set(profile.selectedCategories)

        withAnimation(AppleSpring.gentle) {
            onFinished()
        }
    }
}

@Observable
class OnboardingState {
    var college = ""
    var major = ""
    var grade = ""
    var selectedCategories: [NoticeCategory] = []
    var selectedTags: [String] = []
    var additionalNote: String?
}
