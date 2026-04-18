import SwiftUI

struct PushPrefsView: View {
    private let store = NoticeStore.shared

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { store.allPushEnabled },
                    set: { store.allPushEnabled = $0 }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.campusBlue)
                            .frame(width: 32, height: 32)
                            .background(AppColors.campusBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("全部通知")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppColors.textPrimary)
                            Text("开启或关闭所有分类推送")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                .tint(AppColors.campusBlue)
            }

            Section("通知分类") {
                ForEach(NoticeCategory.allCases) { category in
                    Toggle(isOn: Binding(
                        get: { store.pushPreferences[category] ?? true },
                        set: { _ in store.togglePush(for: category) }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(category.color)
                                .frame(width: 32, height: 32)
                                .background(category.color.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text(category.displayName)
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                    .tint(AppColors.campusBlue)
                }
            }

            Section {
                Text("关闭某个分类的推送后，您将不再收到该分类的通知提醒，但仍可在通知列表中查看。")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("推送偏好设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}
