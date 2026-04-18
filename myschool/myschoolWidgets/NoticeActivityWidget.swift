import ActivityKit
import SwiftUI
import WidgetKit

struct NoticeActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NoticeActivityAttributes.self) { context in
            lockScreenView(context: context)
                .widgetURL(noticeURL(context.attributes.noticeId))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.attributes.categoryIcon)
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                        Text("\(context.attributes.categoryName) · \(context.attributes.source)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.timeString)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.attributes.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(context.state.summary)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(2)

                        HStack {
                            if context.state.isUrgent {
                                Label("紧急通知", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.orange)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            Text("查看详情 →")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text(context.attributes.source)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }
            } compactTrailing: {
                Text(context.state.isUrgent ? "紧急" : "新通知")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(context.state.isUrgent ? .orange : .blue)
            } minimal: {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
            }
            .widgetURL(noticeURL(context.attributes.noticeId))
        }
    }

    private func noticeURL(_ noticeId: String) -> URL {
        URL(string: "myschool://notice/\(noticeId)")!
    }

    // MARK: - Lock Screen View

    private func lockScreenView(context: ActivityViewContext<NoticeActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(context.state.isUrgent ? Color.orange : Color.blue)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: context.attributes.categoryIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(context.state.isUrgent ? .orange : .blue)

                    Text(context.attributes.source)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(context.state.isUrgent ? .orange : .blue)

                    if context.state.isUrgent {
                        Text("紧急")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.orange)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text(context.state.timeString)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Text(context.attributes.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Text(context.state.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
    }
}
