import Foundation

struct Course: Identifiable, Hashable {
    let id: String
    let name: String
    let teacher: String
    let room: String
    let dayOfWeek: Int
    let startPeriod: Int
    let endPeriod: Int
    let colorIndex: Int
    let weeks: [Int]

    func isActive(in week: Int) -> Bool {
        weeks.contains(week)
    }
}

struct GradeRecord: Identifiable, Hashable {
    let id: String
    let courseName: String
    let credit: Double
    let score: Double
    let gradePoint: Double
    let semester: String
}

struct ExamInfo: Identifiable, Hashable {
    let id: String
    let courseName: String
    let examDate: Date
    let location: String
    let seatNumber: String

    var daysUntil: Int {
        max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: examDate)).day ?? 0)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: examDate)
    }
}

struct Award: Identifiable, Hashable {
    let id: String
    let name: String
    let level: AwardLevel
    let date: Date
    let category: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
}

enum AwardLevel: String, CaseIterable, Identifiable, Codable {
    case national = "国家级"
    case provincial = "省级"
    case school = "校级"

    var id: String { rawValue }
}
