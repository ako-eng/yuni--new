import SwiftUI

struct UrgentNoticeCard: View {
    let notice: Notice
    @State private var glowing = false

    var body: some View {
        NavigationLink(value: notice) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.warmOrange.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.warmOrange)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("紧急通知")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.warmOrange.gradient)
                            .clipShape(Capsule())

                        Text(notice.source)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text(notice.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.3))
            }
            .padding(14)
            .background(AppColors.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.warmOrange.opacity(glowing ? 0.25 : 0.1), lineWidth: 1)
            )
            .shadow(color: AppColors.warmOrange.opacity(glowing ? 0.12 : 0.06), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PressableButtonStyle(scaleAmount: 0.98))
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowing = true
            }
        }
    }
}
