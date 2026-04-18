import Foundation

enum MockChatRole: String, Codable, Sendable {
    case user
    case assistant
    /// 思考中占位气泡
    case thinking
}

struct MockChatMessage: Identifiable, Equatable, Sendable {
    let id: UUID
    let role: MockChatRole
    /// 助手消息在流式输出时会逐步追加
    var text: String
    /// 竞赛推荐剧本：可点击跳转通知详情（仅助手消息使用）
    var linkedCompetitionNotices: [Notice]?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: MockChatRole,
        text: String,
        linkedCompetitionNotices: [Notice]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.linkedCompetitionNotices = linkedCompetitionNotices
        self.createdAt = createdAt
    }
}

/// 关键词匹配与兜底回复（离线）
enum MockAIScript {
    private static let keywordRules: [(keywords: [String], reply: String)] = [
        (["食堂", "吃饭", "餐饮", "午饭", "早饭"], "一饭二饭周末部分窗口会调整时间，可在「通知」里搜「食堂」查看当周安排，具体以通知为准。"),
        (["选课", "退课", "抢课", "教务"], "选课一般在学期初开放，退课请关注教务处公布的截止日。可在通知里筛选「教务」类消息。"),
        (["图书馆", "借书", "还书", "自习"], "图书馆开馆时间与预约规则以馆方通知为准。你也可以在通知页搜索「图书馆」。"),
        (["成绩", "绩点", "gpa", "查分"], "成绩发布后可在教务系统查询；GPA 计算规则以学院手册为准。如需核对以教务系统显示为准。"),
        (["校车", "班车", "交通"], "校车时刻若有调整会发通知，请以当日通知为准。"),
        (["宿舍", "水电", "报修", "空调"], "宿舍报修可走后勤系统或宿管通知里的渠道；如需紧急处理请按通知上的联系方式联系。"),
        (["考试", "补考", "期末", "四六级"], "考试安排以学院通知为准，注意核对时间与考场。"),
        (["通知", "公告", "在哪看"], "校园通知集中在 App 底部「通知」页，可按关键词筛选。"),
        (["课表", "教室", "上课"], "课表在「课表」Tab 查看；调课信息请以教务通知为准。"),
        (["你好", "您好", "在吗", "hi", "hello"], "我在的～我是芋泥校园助手，可以帮你梳理通知、课表和校园办事相关的问题，尽管问。"),
        (["谢谢", "感谢"], "不客气，祝你校园生活顺利。"),
        (["再见", "拜拜"], "再见，有需要随时再来找我。"),
    ]

    private static let fallbackReplies: [String] = [
        "这句我暂时没理解～可以试试问我：食堂、选课、图书馆、课表、成绩……",
        "换个说法或试试校园相关的词，比如「通知」「课表」「图书馆」？",
        "我主要覆盖校园场景的问题。输入「通知」「课表」等词也许能更快帮到你。",
    ]

    /// `turnIndex`：第几次用户发言（从 0 起），用于兜底轮换。
    static func reply(for rawInput: String, turnIndex: Int) -> String {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "（发送内容不能为空）" }

        let normalized = trimmed.lowercased()

        if turnIndex == 0, !hasKeywordMatch(normalized) {
            return "收到。你也可以试试问我：食堂开放时间、选课、图书馆预约、校车或宿舍报修等。"
        }

        for rule in keywordRules {
            if rule.keywords.contains(where: { normalized.contains($0.lowercased()) }) {
                return rule.reply
            }
        }

        let i = abs(turnIndex) % fallbackReplies.count
        return fallbackReplies[i]
    }

    private static func hasKeywordMatch(_ normalized: String) -> Bool {
        for rule in keywordRules {
            if rule.keywords.contains(where: { normalized.contains($0.lowercased()) }) {
                return true
            }
        }
        return false
    }

    static let welcomeMessage = "你好，我是芋泥校园助手，可以帮你查校园通知、课表、食堂图书馆等常见问题。随便问一句试试吧～"
}
