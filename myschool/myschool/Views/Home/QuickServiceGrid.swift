import SwiftUI

struct QuickServiceGrid: View {
    let unreadCounts: [NoticeCategory: Int]

    private let services: [(NoticeCategory?, String, String)] = [
        (.academic, "教务通知", "book.fill"),
        (.exam, "考试安排", "pencil.circle.fill"),
        (.competition, "竞赛信息", "trophy.fill"),
        (.research, "科研通知", "atom"),
        (.library, "图书馆", "books.vertical.fill"),
        (.enterprise, "校企实习", "building.2.fill"),
        (.life, "生活服务", "heart.fill"),
        (nil, "更多", "ellipsis.circle.fill"),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(services.enumerated()), id: \.offset) { index, service in
                NavigationLink(value: service.0 ?? NoticeCategory.general) {
                    serviceItem(
                        icon: service.2,
                        title: service.1,
                        category: service.0,
                        count: service.0.flatMap { unreadCounts[$0] } ?? 0
                    )
                }
                .buttonStyle(ServiceButtonStyle())
                .staggerAppear(index: index, total: services.count)
            }
        }
        .padding(.horizontal, 16)
    }

    private func serviceItem(icon: String, title: String, category: NoticeCategory?, count: Int) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    (category?.color ?? AppColors.textSecondary).opacity(0.15),
                                    (category?.color ?? AppColors.textSecondary).opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(category?.color ?? AppColors.textSecondary)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 26, height: 26)
                }

                if count > 0 {
                    BadgeView(count: count)
                        .offset(x: 6, y: -4)
                }
            }

            Text(title)
                .font(AppFonts.smallCaption())
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
        }
    }
}

private struct ServiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AppleSpring.interactive, value: configuration.isPressed)
    }
}
