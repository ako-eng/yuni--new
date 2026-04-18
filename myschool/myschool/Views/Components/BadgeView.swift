import SwiftUI

struct BadgeView: View {
    let count: Int
    @State private var appeared = false

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, count > 9 ? 5 : 4)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [AppColors.softRed, AppColors.softRed.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Capsule())
                .frame(minWidth: 18, minHeight: 18)
                .scaleEffect(appeared ? 1.0 : 0.3)
                .onAppear {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                        appeared = true
                    }
                }
        }
    }
}

struct DotBadge: View {
    var color: Color = AppColors.softRed
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0.7)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 5
                )
            )
            .frame(width: 8, height: 8)
            .scaleEffect(pulse ? 1.2 : 1.0)
            .opacity(pulse ? 0.7 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
