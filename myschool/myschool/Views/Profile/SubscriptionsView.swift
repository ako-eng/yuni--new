import SwiftUI

struct SubscriptionsView: View {
    private let store = NoticeStore.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryCard
                categoryList
            }
            .padding(.vertical, 8)
        }
        .background(AppColors.background)
        .navigationTitle("我的订阅")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(store.subscriptionCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.campusBlue)
                Text("已订阅分类")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 40)

            VStack(spacing: 4) {
                Text("\(NoticeCategory.allCases.count - store.subscriptionCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Text("未订阅分类")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private var categoryList: some View {
        VStack(spacing: 0) {
            ForEach(Array(NoticeCategory.allCases.enumerated()), id: \.element) { index, category in
                categoryRow(category)

                if index < NoticeCategory.allCases.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
    }

    private func categoryRow(_ category: NoticeCategory) -> some View {
        let isSubscribed = store.isSubscribed(category)
        let noticeCount = store.notices.filter { $0.category == category }.count
        let unreadCount = store.unreadCount(for: category)

        return HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(category.color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(category.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: 8) {
                    Text("\(noticeCount)条通知")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                    if unreadCount > 0 {
                        Text("\(unreadCount)条未读")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppColors.softRed)
                    }
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.toggleSubscription(category)
                }
            } label: {
                Text(isSubscribed ? "已订阅" : "订阅")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSubscribed ? AppColors.textSecondary : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(isSubscribed ? AppColors.background : AppColors.campusBlue)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
