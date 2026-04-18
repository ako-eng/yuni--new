import SwiftUI

struct NoticeFilterBar: View {
    @Binding var selectedCategory: NoticeCategory?
    @Binding var sortByTime: Bool

    var body: some View {
        VStack(spacing: 10) {
            categoryChips
            sortBar
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                AllCategoryChip(isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(NoticeCategory.allCases) { category in
                    CategoryChip(category: category, isSelected: selectedCategory == category) {
                        if selectedCategory == category {
                            selectedCategory = nil
                        } else {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var sortBar: some View {
        HStack(spacing: 16) {
            Button {
                sortByTime = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("按时间")
                        .font(.system(size: 13, weight: sortByTime ? .semibold : .regular))
                }
                .foregroundStyle(sortByTime ? AppColors.campusBlue : AppColors.textSecondary)
            }

            Button {
                sortByTime = false
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12))
                    Text("按重要性")
                        .font(.system(size: 13, weight: !sortByTime ? .semibold : .regular))
                }
                .foregroundStyle(!sortByTime ? AppColors.campusBlue : AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}
