import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var avatarGlow = false
    @State private var shimmerPhase: CGFloat = -1
    @State private var statsAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    userCard
                    statsRow
                    messageSection
                    preferencesSection
                    systemSection
                    logoutButton
                    versionInfo
                }
                .padding(.bottom, 30)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
        }
    }

    // MARK: - User Card

    private var userCard: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x0A84FF),
                    Color(hex: 0x007AFF),
                    Color(hex: 0x5AC8FA),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AngularGradient(
                colors: [.clear, .white.opacity(0.08), .clear, .white.opacity(0.04), .clear],
                center: .center,
                angle: .degrees(shimmerPhase * 360)
            )
            .blendMode(.overlay)

            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.1), .clear],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 200
                ))
                .offset(x: 80, y: -40)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 66, height: 66)
                        .scaleEffect(avatarGlow ? 1.1 : 1.0)
                        .opacity(avatarGlow ? 0.3 : 0.8)

                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.3))
                        .frame(width: 60, height: 60)

                    Image(systemName: viewModel.user.avatarName)
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                        avatarGlow = true
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.user.name)
                        .font(AppFonts.title())
                        .foregroundStyle(.white)
                    Text(viewModel.user.studentId)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                    Text("\(viewModel.user.department) · \(viewModel.user.grade)")
                        .font(AppFonts.smallCaption())
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.4))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: viewModel.unreadMessageCount, label: "未读消息", color: AppColors.softRed)
            statDivider
            statItem(value: viewModel.favoriteCount, label: "我的收藏", color: AppColors.warmOrange)
            statDivider
            statItem(value: viewModel.subscriptionCount, label: "已订阅", color: AppColors.campusBlue)
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .offset(y: -10)
        .onAppear {
            withAnimation(AppleSpring.smooth.delay(0.2)) {
                statsAppeared = true
            }
        }
    }

    private func statItem(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(AppFonts.title())
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(AppleSpring.smooth, value: value)
            Text(label)
                .font(AppFonts.smallCaption())
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(AppColors.separatorLight)
            .frame(width: 0.5, height: 30)
    }

    // MARK: - Message Section

    private var messageSection: some View {
        VStack(spacing: 0) {
            sectionHeader("消息管理")

            VStack(spacing: 0) {
                NavigationLink {
                    MessageCenterView()
                } label: {
                    profileRow(icon: "bell.badge.fill", iconColor: AppColors.softRed, title: "消息中心", badge: viewModel.unreadMessageCount)
                }
                Divider().padding(.leading, 52)
                NavigationLink {
                    FavoritesView()
                } label: {
                    profileRow(icon: "star.fill", iconColor: AppColors.warmOrange, title: "我的收藏", subtitle: "\(viewModel.favoriteCount)条")
                }
                Divider().padding(.leading, 52)
                NavigationLink {
                    SubscriptionsView()
                } label: {
                    profileRow(icon: "bookmark.fill", iconColor: AppColors.campusBlue, title: "我的订阅", subtitle: "\(viewModel.subscriptionCount)个分类")
                }
            }
            .background(AppColors.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(spacing: 0) {
            sectionHeader("偏好设置")

            VStack(spacing: 0) {
                NavigationLink {
                    PushPrefsView()
                } label: {
                    profileRow(icon: "slider.horizontal.3", iconColor: AppColors.mintGreen, title: "推送偏好设置")
                }
                Divider().padding(.leading, 52)
                NavigationLink {
                    PushPrefsView()
                } label: {
                    profileRow(icon: "bell.fill", iconColor: AppColors.campusBlue, title: "通知管理")
                }
            }
            .background(AppColors.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - System Section

    private var systemSection: some View {
        VStack(spacing: 0) {
            sectionHeader("系统")

            VStack(spacing: 0) {
                NavigationLink {
                    placeholderPage(title: "账号与隐私", icon: "lock.shield.fill")
                } label: {
                    profileRow(icon: "lock.shield.fill", iconColor: AppColors.textSecondary, title: "账号与隐私")
                }
                Divider().padding(.leading, 52)
                NavigationLink {
                    SettingsView()
                } label: {
                    profileRow(icon: "gearshape.fill", iconColor: AppColors.textSecondary, title: "设置")
                }
                Divider().padding(.leading, 52)
                NavigationLink {
                    feedbackPage
                } label: {
                    profileRow(icon: "bubble.left.fill", iconColor: AppColors.mintGreen, title: "意见反馈")
                }
                Divider().padding(.leading, 52)
                NavigationLink {
                    AboutView()
                } label: {
                    profileRow(icon: "info.circle.fill", iconColor: AppColors.campusBlue, title: "关于我们")
                }
            }
            .background(AppColors.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
    }

    private func profileRow(icon: String, iconColor: Color, title: String, subtitle: String? = nil, badge: Int = 0) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            if let subtitle {
                Text(subtitle)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }

            if badge > 0 {
                BadgeView(count: badge)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var logoutButton: some View {
        Button {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            viewModel.logout()
        } label: {
            Text("退出登录")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.softRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.cardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var versionInfo: some View {
        Text("版本 1.0.0")
            .font(AppFonts.smallCaption())
            .foregroundStyle(AppColors.textSecondary.opacity(0.5))
    }

    private func placeholderPage(title: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)
            Text("暂未开放，敬请期待")
                .font(AppFonts.callout())
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var feedbackPage: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("意见反馈")
                    .font(AppFonts.sectionTitle())
                    .foregroundStyle(AppColors.textPrimary)
                Text("请描述您遇到的问题或建议")
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)

            TextEditor(text: .constant(""))
                .frame(height: 160)
                .scrollContentBackground(.hidden)
                .background(AppColors.cardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.separatorLight, lineWidth: 0.5))
                .padding(.horizontal, 16)

            Button {} label: {
                Text("提交反馈")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(AppColors.background)
        .navigationTitle("意见反馈")
        .navigationBarTitleDisplayMode(.inline)
    }
}
