import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜索通知、课程、服务..."
    var onTap: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.campusBlue.opacity(0.6))
                .font(.system(size: 15, weight: .medium))

            if let onTap {
                Text(placeholder)
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap() }
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textPrimary)
            }

            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary.opacity(0.6))
                        .font(.system(size: 16))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.04),
                    lineWidth: 0.5
                )
        )
    }
}
