import Foundation

struct UserOnboardingProfile: Codable {
    var college: String
    var major: String
    var grade: String
    var preferredCategories: [String]
    var preferredTags: [String]
    var profileSlogan: String
    var additionalNote: String?
    var completedAt: Date?

    private static let storageKey = "user.onboardingProfile"

    static func load() -> UserOnboardingProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(UserOnboardingProfile.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static var hasCompleted: Bool {
        load()?.completedAt != nil
    }

    /// 清除本地画像（用于「重新走一遍推荐引导」或调试）。
    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// 计算一条通知与用户偏好的匹配度（0-100）。
    /// 分数对同一条通知保持稳定，但不会因为仅命中类别就全部整齐地落在 60。
    func matchScore(category: String, tags: [String], noticeID: String) -> Int {
        let categoryMatched = preferredCategories.contains(category)
        let matchedTags = tags.filter { preferredTags.contains($0) }

        guard categoryMatched || !matchedTags.isEmpty else { return 0 }

        var score = 0
        let categorySeed = Self.stableSeed(from: "cat|\(noticeID)|\(category)")
        let tagSeed = Self.stableSeed(from: "tag|\(noticeID)|\(matchedTags.sorted().joined(separator: "|"))")

        if categoryMatched {
            // 52...68：同为“命中类别”，但不同通知会有稳定的轻微差异。
            score += 52 + (categorySeed % 17)
        }

        if !matchedTags.isEmpty {
            // 每个命中标签提供 8 分，再叠加 0...4 的稳定扰动。
            score += min(28, matchedTags.count * 8 + (tagSeed % 5))
        }

        if categoryMatched && matchedTags.count >= 2 {
            score += 4
        }

        return min(score, 95)
    }

    private static func stableSeed(from text: String) -> Int {
        text.unicodeScalars.reduce(0) { partial, scalar in
            (partial * 31 + Int(scalar.value)) % 10_000
        }
    }

    static func generateSlogan(college: String, categories: [String], tags: [String]) -> String {
        let slogans: [(keywords: Set<String>, text: String)] = [
            (["考试", "教务"], "你是图书馆的常客，考试周的战士。校园的每一条重要通知，芋泥都帮你盯着。"),
            (["竞赛", "科研"], "身处学术殿堂，心系四方赛场。竞赛、科研——你的校园雷达已开启。"),
            (["校企", "生活"], "兼顾校园与职场，生活与梦想并行。芋泥帮你捕捉每一个机会。"),
            (["图书馆"], "书卷为伴，知识为友。图书馆的每一条动态，芋泥替你留意。"),
            (["安全"], "安全无小事，芋泥帮你守住校园平安线。提醒从不缺席。"),
            (["后勤"], "宿舍报修、水电缴费、设施通知——芋泥替你操心生活琐事。"),
            (["考试", "竞赛"], "既能征战赛场，也能攻克考场。学术与竞技双线并行，芋泥为你保驾护航。"),
            (["教务", "科研"], "课表与课题齐飞，学业与科研共进。芋泥帮你把每一步安排得明明白白。"),
            (["生活", "图书馆"], "图书馆自习、食堂觅食、社团活动——你的校园生活，芋泥全程陪伴。"),
            (["校企"], "简历已备好，offer 在路上。校招、实习、宣讲，芋泥帮你一个不漏。"),
            (["综合"], "校园大小事，芋泥全知道。你只管专注学业，其余交给我。"),
        ]
        let catSet = Set(categories)
        for s in slogans {
            if !s.keywords.intersection(catSet).isEmpty {
                return s.text
            }
        }
        let tagStr = tags.prefix(3).joined(separator: "、")
        if !tagStr.isEmpty {
            return "关注 \(tagStr) 的你，校园资讯尽在掌握。芋泥已为你开启专属推荐。"
        }
        return "校园千万条通知，芋泥帮你挑重点。你的专属信息流已就绪。"
    }
}
