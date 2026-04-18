import SwiftUI

struct LoginView: View {
    var onLoginSuccess: () -> Void

    @State private var studentId = ""
    @State private var password = ""
    @State private var agreedToTerms = false
    @State private var isVerifying = false
    @State private var showPassword = false

    private var studentIdValid: Bool {
        studentId.count >= 8
    }

    private var passwordValid: Bool {
        password.count >= 6
    }

    private var canLogin: Bool {
        agreedToTerms && studentIdValid && passwordValid
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                formSection
                Spacer(minLength: 40)
            }
        }
        .background(AppColors.background)
        .ignoresSafeArea(.container, edges: .top)
    }

    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x4A3F5C),
                    Color(hex: 0x6B5B7F),
                    Color(hex: 0x9B86B8),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Spacer().frame(height: 60)

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: 0xFFF8F5))
                    .shadow(color: Color(hex: 0x4A3A5C).opacity(0.3), radius: 8, y: 4)

                Text("欢迎使用\(AppBranding.displayName)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("软糯校园 · 一口掌握")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))

                Spacer().frame(height: 30)
            }
        }
        .frame(height: 260)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 28,
                bottomTrailingRadius: 28
            )
        )
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            Text("未注册的学号验证后将自动创建账户")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("学号")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(AppColors.textSecondary)
                    TextField("请输入学号", text: $studentId)
                        .keyboardType(.numberPad)
                        .font(.system(size: 15, design: .rounded))
                }
                .padding(14)
                .background(AppColors.cardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(studentIdValid ? Color(hex: 0x9B86B8).opacity(0.4) : Color.gray.opacity(0.15), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("密码")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(AppColors.textSecondary)
                    if showPassword {
                        TextField("请输入密码", text: $password)
                            .font(.system(size: 15, design: .rounded))
                    } else {
                        SecureField("请输入密码", text: $password)
                            .font(.system(size: 15, design: .rounded))
                    }
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .padding(14)
                .background(AppColors.cardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(passwordValid ? Color(hex: 0x9B86B8).opacity(0.4) : Color.gray.opacity(0.15), lineWidth: 1)
                )
            }

            HStack(spacing: 6) {
                Button {
                    withAnimation(AppleSpring.snappy) {
                        agreedToTerms.toggle()
                    }
                } label: {
                    Image(systemName: agreedToTerms ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(agreedToTerms ? Color(hex: 0x9B86B8) : AppColors.textSecondary)
                }
                Text("已阅读并同意")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Text("《用户协议》")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color(hex: 0x9B86B8))
                Text("和")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Text("《隐私政策》")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color(hex: 0x9B86B8))
            }
            .padding(.top, 4)

            Button {
                performLogin()
            } label: {
                HStack(spacing: 8) {
                    if isVerifying {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text("登录 / 注册")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(canLogin ? Color(hex: 0x4A3F5C) : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(canLogin ? Color.white : Color.white.opacity(0.15))
                        .shadow(color: Color(hex: 0x4A3F5C).opacity(canLogin ? 0.12 : 0), radius: 8, y: 4)
                )
                .overlay(
                    Capsule()
                        .stroke(canLogin ? Color(hex: 0x9B86B8).opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            .disabled(!canLogin || isVerifying)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private func performLogin() {
        isVerifying = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // 调用登录API
        Task {
            do {
                try await APIService.shared.login(studentId: studentId, password: password)
                DispatchQueue.main.async {
                    isVerifying = false
                    onLoginSuccess()
                }
            } catch {
                DispatchQueue.main.async {
                    isVerifying = false
                    // 显示错误信息
                    print("登录失败: \(error.localizedDescription)")
                }
            }
        }
    }
}
