import SwiftUI

struct OnboardingPreferenceView: View {
    @Binding var selectedCategories: [NoticeCategory]
    var onNext: () -> Void

    @State private var headerIn = false
    @State private var subtitleIn = false
    @State private var gridIn = false
    @State private var footerIn = false
    @State private var barShimmerDeadline = Date.distantPast
    @State private var isBursting = false
    @State private var isContinuing = false
    @State private var parallax = DeviceParallaxController()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let categoryDescriptions: [NoticeCategory: String] = [
        .academic: "选课、调课、学分",
        .exam: "期末安排、补考通知",
        .competition: "学科竞赛、创新创业",
        .research: "课题申报、学术讲座",
        .life: "宿舍、食堂、活动",
        .enterprise: "校招、实习、宣讲",
        .security: "安全提醒、出入管理",
        .logistics: "维修、水电、设施",
        .library: "开放时间、讲座预约",
        .general: "全校性综合通知",
    ]

    private let categoryPatternIcons: [NoticeCategory: String] = [
        .academic: "book.fill",
        .exam: "clock.fill",
        .competition: "trophy.fill",
        .research: "atom",
        .life: "house.fill",
        .enterprise: "briefcase.fill",
        .security: "shield.fill",
        .logistics: "wrench.and.screwdriver.fill",
        .library: "books.vertical.fill",
        .general: "megaphone.fill",
    ]

    private var canProceed: Bool { selectedCategories.count >= 3 }
    private var progressRatio: CGFloat {
        min(CGFloat(selectedCategories.count) / 10.0, 1.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: 0xFFF8F5))
                Text("哪些校园资讯是你最关心的？")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.top, 24)
            .padding(.bottom, 6)
            .opacity(headerIn ? 1 : 0)
            .offset(y: headerIn ? 0 : 12)
            .blur(radius: headerIn ? 0 : 3)

            Text("至少选择 3 个类别")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.bottom, 10)
                .opacity(subtitleIn ? 1 : 0)
                .offset(y: subtitleIn ? 0 : 8)

            GeometryReader { geo in
                OnboardingCategoryBubblePool(
                    selectedCategories: $selectedCategories,
                    categoryDescriptions: categoryDescriptions,
                    categoryPatternIcons: categoryPatternIcons,
                    gridIn: gridIn,
                    isBursting: isBursting,
                    parallaxTiltX: parallax.tiltX,
                    parallaxTiltY: parallax.tiltY
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .allowsHitTesting(!isContinuing)
            }
            .frame(maxHeight: .infinity)

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Text("已选")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("\(selectedCategories.count)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x4A3F5C))
                            .frame(minWidth: 28)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.95))
                                    .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                            )
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: selectedCategories.count)
                        Text("/ 10 个类别")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    TimelineView(.animation(minimumInterval: 0.35)) { context in
                        let shimmerOn = context.date < barShimmerDeadline
                        GeometryReader { geo in
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 6)
                                .overlay(alignment: .leading) {
                                    MatchingProgressBarShine(
                                        progress: progressRatio,
                                        shimmerActive: shimmerOn,
                                        barHeight: 6,
                                        usePreferenceGradient: true
                                    )
                                    .animation(AppleSpring.smooth, value: progressRatio)
                                }
                        }
                        .frame(height: 6)
                        .padding(.horizontal, 40)
                    }
                }

                Button(action: handleNext) {
                    Text("下一步")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(canProceed ? Color(hex: 0x4A3F5C) : Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(canProceed ? Color.white : Color.white.opacity(0.15))
                        )
                }
                .disabled(!canProceed || isContinuing)
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
            .opacity(footerIn ? 1 : 0)
            .offset(y: footerIn ? 0 : 14)
        }
        .onAppear {
            runEntrance()
            parallax.start(reduceMotion: reduceMotion)
        }
        .onDisappear {
            parallax.stop()
        }
        .onChange(of: reduceMotion) { _, new in
            parallax.stop()
            parallax.start(reduceMotion: new)
        }
        .onChange(of: selectedCategories.count) { _, _ in
            barShimmerDeadline = Date().addingTimeInterval(2.6)
        }
    }

    private func runEntrance() {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
            headerIn = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                subtitleIn = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                gridIn = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                footerIn = true
            }
        }
    }

    private func handleNext() {
        guard canProceed, !isContinuing else { return }
        let unselected = Set(NoticeCategory.allCases).subtracting(selectedCategories)
        if unselected.isEmpty {
            onNext()
            return
        }
        isContinuing = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        withAnimation(AppleSpring.smooth) {
            isBursting = true
        }
        let delay = reduceMotion ? 0.52 : 0.88
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            onNext()
        }
    }
}
