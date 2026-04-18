import SwiftUI

struct SettingsView: View {
    private var themeManager = ThemeManager.shared
    @State private var notificationEnabled = true
    @State private var showClearCacheAlert = false
    @State private var showReplayOnboardingAlert = false
    @State private var cacheCleared = false
    @State private var apiURLSavedHint: String?
    @AppStorage("myschool.teacherMode.enabled") private var teacherModeEnabled = false

    var body: some View {
        List {
            Section {
                Text(APIConfiguration.baseURLString)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
                    .textSelection(.enabled)
                Button {
                    apiURLSavedHint = "正在重新加载…"
                    Task {
                        await NoticeStore.shared.refresh()
                        if NoticeStore.shared.usingMockFallback {
                            let detail = NoticeStore.shared.lastConnectFailureSummary ?? ""
                            let detailLine = detail.isEmpty ? "" : "\n\(detail)"
                            apiURLSavedHint = "仍无法连接，请核对服务端是否在 \(APIConfiguration.baseURLString) 正常运行。\n可先在 Safari 打开同一根地址下的 /api/health 测试。\(detailLine)"
                        } else {
                            apiURLSavedHint = "已连接通知服务。"
                        }
                    }
                } label: {
                    Text("重新加载通知")
                }
                if let hint = apiURLSavedHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            } header: {
                Text("校园通知接口")
            } footer: {
                Text(
                    "接口根地址固定为 \(APIConfiguration.baseURLString)，不可在 App 内修改。"
                )
            }

            Section {
                Toggle(isOn: $teacherModeEnabled) {
                    settingRow(icon: "person.badge.key.fill", color: AppColors.warmOrange, title: "教师模式")
                }
                .tint(AppColors.campusBlue)
                if teacherModeEnabled {
                    NavigationLink {
                        TeacherPublishNoticeView()
                    } label: {
                        settingRow(icon: "square.and.pencil", color: AppColors.campusBlue, title: "发布校园通知")
                    }
                }
            } header: {
                Text("教师模式")
            } footer: {
                Text("默认关闭，不显示发布入口。开启后可在本机填写并提交通知到已连接的后端（需 myschool_back 支持 POST /api/notices/add）。当前无教师账号鉴权，请勿在公网环境使用。")
            }

            Section("通知") {
                Toggle(isOn: $notificationEnabled) {
                    settingRow(icon: "bell.fill", color: AppColors.campusBlue, title: "接收通知推送")
                }
                .tint(AppColors.campusBlue)

                NavigationLink {
                    PushPrefsView()
                } label: {
                    settingRow(icon: "slider.horizontal.3", color: AppColors.mintGreen, title: "推送偏好设置")
                }
            }

            Section("显示") {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            themeManager.appearanceMode = mode
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(colorForMode(mode))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            Text(mode.rawValue)
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer()

                            if themeManager.appearanceMode == mode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.campusBlue)
                            }
                        }
                    }
                }
            }

            Section("存储") {
                Button {
                    showClearCacheAlert = true
                } label: {
                    HStack {
                        settingRow(icon: "trash.fill", color: AppColors.softRed, title: "清除缓存")
                        Spacer()
                        Text(cacheCleared ? "0 MB" : "23.5 MB")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .alert("确定清除缓存？", isPresented: $showClearCacheAlert) {
                    Button("取消", role: .cancel) {}
                    Button("清除", role: .destructive) {
                        cacheCleared = true
                    }
                } message: {
                    Text("清除后将重新加载所有数据")
                }
            }

            Section {
                Button {
                    showReplayOnboardingAlert = true
                } label: {
                    settingRow(icon: "sparkles", color: Color(hex: 0x9B86B8), title: "重新设置推荐偏好")
                }
            } header: {
                Text("个性化推荐")
            } footer: {
                Text("首次使用会在登录后进入「学院、通知类别、标签」等引导。若重装后直接进入主页，多半是覆盖安装保留了数据；也可在此重新走一遍引导。")
            }
            .alert("重新设置推荐偏好？", isPresented: $showReplayOnboardingAlert) {
                Button("取消", role: .cancel) {}
                Button("进入引导") {
                    AppSession.shared.restartOnboardingFromMain()
                }
            } message: {
                Text("将清除本机的推荐画像并重新显示引导流程，完成后返回当前账号的主页。")
            }

            Section("隐私") {
                NavigationLink {
                    placeholderPage(title: "隐私设置", icon: "lock.shield.fill")
                } label: {
                    settingRow(icon: "lock.shield.fill", color: AppColors.textSecondary, title: "隐私设置")
                }
                NavigationLink {
                    placeholderPage(title: "用户协议", icon: "doc.text.fill")
                } label: {
                    settingRow(icon: "doc.text.fill", color: AppColors.campusBlue, title: "用户协议")
                }
                NavigationLink {
                    placeholderPage(title: "隐私政策", icon: "hand.raised.fill")
                } label: {
                    settingRow(icon: "hand.raised.fill", color: AppColors.warmOrange, title: "隐私政策")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func colorForMode(_ mode: AppearanceMode) -> Color {
        switch mode {
        case .system: .gray
        case .light: AppColors.warmOrange
        case .dark: .indigo
        }
    }

    private func settingRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private func placeholderPage(title: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
            Text("暂未开放，敬请期待")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
