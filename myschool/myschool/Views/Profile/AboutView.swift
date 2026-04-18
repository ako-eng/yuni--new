import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                logoSection
                descriptionSection
                teamSection
                linksSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(AppColors.background)
        .navigationTitle("关于我们")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var logoSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x9B86B8).opacity(0.18))
                    .frame(width: 80, height: 80)
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: 0x7A6594))
            }

            Text(AppBranding.displayName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("版本 1.0.0")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, 20)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("应用简介")
                .font(AppFonts.sectionTitle())
                .foregroundStyle(AppColors.textPrimary)

            Text("「\(AppBranding.displayName)」是一款面向高校学生的校园信息聚合应用，用软糯清晰的界面整合通知、课表与常用服务入口，帮你把校园资讯握在手心。")
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("开发团队")
                .font(AppFonts.sectionTitle())
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 12) {
                infoRow(title: "团队", value: "校园信息化创新团队")
                Divider()
                infoRow(title: "指导老师", value: "张教授")
                Divider()
                infoRow(title: "联系邮箱", value: "myschool@university.edu.cn")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private var linksSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                placeholderPage(title: "用户协议", icon: "doc.text.fill")
            } label: {
                linkRow(icon: "doc.text.fill", title: "用户协议")
            }
            Divider().padding(.leading, 52)
            NavigationLink {
                placeholderPage(title: "隐私政策", icon: "hand.raised.fill")
            } label: {
                linkRow(icon: "hand.raised.fill", title: "隐私政策")
            }
            Divider().padding(.leading, 52)
            NavigationLink {
                contactPage
            } label: {
                linkRow(icon: "envelope.fill", title: "联系我们")
            }
        }
        .buttonStyle(.plain)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func linkRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.campusBlue)
                .frame(width: 32, height: 32)

            Text(title)
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
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

    private var contactPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.campusBlue)
            Text("联系我们")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
            VStack(spacing: 8) {
                Text("邮箱：myschool@university.edu.cn")
                Text("电话：010-12345678")
                Text("地址：校园信息中心 A栋 305")
            }
            .font(.system(size: 14))
            .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
        .navigationTitle("联系我们")
        .navigationBarTitleDisplayMode(.inline)
    }
}
