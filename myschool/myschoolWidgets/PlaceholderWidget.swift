import SwiftUI
import WidgetKit

/// Minimal home-screen widget so WidgetKit can register a descriptor; the main feature is Live Activity (`NoticeActivityWidget`).
struct PlaceholderWidget: Widget {
    let kind = "myschool.placeholder"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { _ in
            VStack(alignment: .leading, spacing: 4) {
                Text("芋泥uni")
                    .font(.headline)
                Text("通知与 Live Activity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("芋泥uni")
        .description("快捷入口；紧急通知请使用 Live Activity。")
        // Xcode 小组件画布常请求 systemMedium；仅声明 small 会触发 “not supported by this widget kind”
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct SimpleEntry: TimelineEntry {
    let date: Date
}
