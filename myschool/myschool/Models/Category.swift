import SwiftUI

enum NoticeCategory: String, CaseIterable, Identifiable, Codable {
    case academic = "教务"
    case exam = "考试"
    case competition = "竞赛"
    case research = "科研"
    case life = "生活"
    case enterprise = "校企"
    case security = "保卫"
    case logistics = "后勤"
    case library = "图书馆"
    case general = "综合"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// 与后端 `gdut_notices.json` 常见分类写法一致（如 `教务通知`、`综合通知`）。
    var apiCategoryLabel: String {
        rawValue.hasSuffix("通知") ? rawValue : "\(rawValue)通知"
    }

    var icon: String {
        switch self {
        case .academic: "book.fill"
        case .exam: "pencil.circle.fill"
        case .competition: "trophy.fill"
        case .research: "atom"
        case .life: "heart.fill"
        case .enterprise: "building.2.fill"
        case .security: "shield.fill"
        case .logistics: "wrench.and.screwdriver.fill"
        case .library: "books.vertical.fill"
        case .general: "bell.fill"
        }
    }

    /// Maps API category strings (e.g. `综合通知`, `教务通知`) to the closest enum case.
    init?(apiCategory raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var base = trimmed
        for suffix in ["通知", "公告", "资讯", "动态"] {
            if base.hasSuffix(suffix), base.count > suffix.count {
                base = String(base.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if let exact = NoticeCategory.allCases.first(where: { $0.rawValue == base }) {
            self = exact
            return
        }
        if let contains = NoticeCategory.allCases.first(where: { base.contains($0.rawValue) || $0.rawValue.contains(base) }) {
            self = contains
            return
        }
        return nil
    }

    var color: Color {
        switch self {
        case .academic: AppColors.campusBlue
        case .exam: AppColors.softRed
        case .competition: AppColors.warmOrange
        case .research: AppColors.mintGreen
        case .life: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.68, green: 0.80, blue: 0.90, alpha: 1) : UIColor(red: 0.58, green: 0.72, blue: 0.82, alpha: 1) })
        case .enterprise: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.58, green: 0.85, blue: 0.95, alpha: 1) : UIColor(red: 0.49, green: 0.78, blue: 0.89, alpha: 1) })
        case .security: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.83, green: 0.76, blue: 0.90, alpha: 1) : UIColor(red: 0.76, green: 0.68, blue: 0.84, alpha: 1) })
        case .logistics: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.75, green: 0.90, blue: 0.80, alpha: 1) : UIColor(red: 0.66, green: 0.85, blue: 0.73, alpha: 1) })
        case .library: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.97, green: 0.73, blue: 0.78, alpha: 1) : UIColor(red: 0.96, green: 0.65, blue: 0.70, alpha: 1) })
        case .general: AppColors.textSecondary
        }
    }
}
