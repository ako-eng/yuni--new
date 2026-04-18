import SwiftUI

struct LatestNoticeList: View {
    let notices: [Notice]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最新动态")
                    .font(AppFonts.sectionTitle())
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                NavigationLink {
                    NoticeListView(embedded: true)
                } label: {
                    HStack(spacing: 3) {
                        Text("查看全部")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(AppColors.campusBlue)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(Array(notices.enumerated()), id: \.element.id) { index, notice in
                    NavigationLink(value: notice) {
                        NoticeRowView(notice: notice)
                    }
                    .buttonStyle(CardPressButtonStyle())
                    .scrollFade()
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(AppleSpring.interactive, value: configuration.isPressed)
    }
}
