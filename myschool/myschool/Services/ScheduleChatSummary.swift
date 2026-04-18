import Foundation

/// 与课表 Tab 一致：当前教学周 + 今日星期，从 Mock 课程生成可读文案。
enum ScheduleChatSummary {
    private static let dayNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    /// 今日（按系统日历）在第 `currentWeek` 教学周内的课程列表文案。
    static func todayScheduleText(
        courses: [Course] = MockData.courses,
        currentWeek: Int = MockData.currentWeek
    ) -> String {
        let dayOfWeek = todayDayOfWeekOneBased()
        let dayLabel = dayNames[dayOfWeek - 1]

        let todayCourses = courses
            .filter { $0.isActive(in: currentWeek) && $0.dayOfWeek == dayOfWeek }
            .sorted { $0.startPeriod < $1.startPeriod }

        if todayCourses.isEmpty {
            return "今天是\(dayLabel)（第 \(currentWeek) 周），今天没有安排课程。"
        }

        var lines: [String] = []
        lines.append("今天是\(dayLabel)（第 \(currentWeek) 周），你有这些课：")
        for c in todayCourses {
            let period = c.startPeriod == c.endPeriod
                ? "第\(c.startPeriod)节"
                : "第\(c.startPeriod)-\(c.endPeriod)节"
            lines.append("\(period) \(c.name) · \(c.room) · \(c.teacher)")
        }
        return lines.joined(separator: "\n")
    }

    /// 与 `ScheduleViewModel.todayDayOfWeek` 一致：周一=1 … 周日=7。
    static func todayDayOfWeekOneBased() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 ? 7 : weekday - 1
    }
}
