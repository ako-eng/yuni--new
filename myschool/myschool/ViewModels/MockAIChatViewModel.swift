import Foundation
import Observation

/// 两段剧本：课表 -> 竞赛推荐；之后走关键词兜底。
private enum ChatScriptPhase: Int, Equatable {
    case idle
    case afterSchedule
    case afterCompetitions
}

@MainActor
@Observable
final class MockAIChatViewModel {
    var messages: [MockChatMessage] = []
    /// 已完成的发送轮次（每发一条用户消息 +1）。
    private(set) var userTurnCount = 0
    /// 正在思考或流式输出中，用于禁用输入。
    private(set) var isGenerating = false
    /// 流式输出时递增，驱动滚动跟随。
    private(set) var streamTick = 0

    private var streamTask: Task<Void, Never>?
    private var streamGeneration = 0
    private var scriptPhase: ChatScriptPhase = .idle

    private let noticeStore = NoticeStore.shared

    func loadWelcomeIfNeeded() {
        guard messages.isEmpty else { return }
        messages.append(MockChatMessage(role: .assistant, text: MockAIScript.welcomeMessage))
    }

    func send(_ raw: String, reduceMotion: Bool) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        streamTask?.cancel()
        streamTask = nil
        streamGeneration += 1
        let generation = streamGeneration

        messages.append(MockChatMessage(role: .user, text: trimmed))

        let turnIndex = userTurnCount
        userTurnCount += 1

        let normalized = trimmed.lowercased()

        let scriptOutcome = resolveScriptReply(raw: trimmed, normalized: normalized, turnIndex: turnIndex)
        let reply: String
        let linkedNotices: [Notice]?
        let streamReply: Bool
        let useLongThinking: Bool

        switch scriptOutcome {
        case let .schedule(text):
            reply = text
            linkedNotices = nil
            streamReply = false
            useLongThinking = true
        case let .competitions(text, notices):
            reply = text
            linkedNotices = notices
            streamReply = false
            useLongThinking = true
        case let .keyword(text):
            reply = text
            linkedNotices = nil
            streamReply = true
            useLongThinking = false
        }

        let thinkingId = UUID()
        messages.append(MockChatMessage(id: thinkingId, role: .thinking, text: ""))
        isGenerating = true

        /// 课表/竞赛剧本：假装多查一会儿再出结果；普通关键词仍较短，流式本身也有节奏。
        let thinkingNanos: UInt64 = thinkingDurationNanoseconds(longPretend: useLongThinking, reduceMotion: reduceMotion)

        streamTask = Task { @MainActor in
            defer {
                if generation == streamGeneration {
                    isGenerating = false
                }
            }
            try? await Task.sleep(nanoseconds: thinkingNanos)
            guard !Task.isCancelled, generation == streamGeneration else { return }
            messages.removeAll { $0.id == thinkingId }

            if !streamReply || reduceMotion {
                messages.append(
                    MockChatMessage(
                        role: .assistant,
                        text: reply,
                        linkedCompetitionNotices: linkedNotices
                    )
                )
                streamTick += 1
                return
            }

            let replyId = UUID()
            messages.append(MockChatMessage(id: replyId, role: .assistant, text: "", linkedCompetitionNotices: nil))
            streamTick += 1

            let chars = Array(reply)
            for ch in chars {
                guard !Task.isCancelled, generation == streamGeneration else { return }
                let delay = Self.tokenDelay(for: ch)
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled, generation == streamGeneration else { return }
                guard let idx = messages.firstIndex(where: { $0.id == replyId }) else { return }
                messages[idx].text += String(ch)
                streamTick += 1
            }
        }
    }

    private enum ScriptOutcome {
        case schedule(String)
        case competitions(String, [Notice])
        case keyword(String)
    }

    /// 思考气泡停留时长（纳秒）。`longPretend` 用于课表/竞赛等「假装在查库」的剧本。
    private func thinkingDurationNanoseconds(longPretend: Bool, reduceMotion: Bool) -> UInt64 {
        if reduceMotion {
            return longPretend ? 450_000_000 : 200_000_000
        }
        if longPretend {
            return UInt64(1_500_000_000 + UInt64.random(in: 0...1_300_000_000))
        }
        return UInt64(500_000_000 + UInt64.random(in: 0...600_000_000))
    }

    private func resolveScriptReply(raw: String, normalized: String, turnIndex: Int) -> ScriptOutcome {
        if scriptPhase == .idle, matchesTodayScheduleQuery(normalized) {
            scriptPhase = .afterSchedule
            return .schedule(ScheduleChatSummary.todayScheduleText())
        }

        if scriptPhase == .afterSchedule, matchesCompetitionRecommendQuery(normalized) {
            scriptPhase = .afterCompetitions
            let notices = competitionRecommendations(limit: 2)
            let intro = "最近值得关注的竞赛通知有这些，点标题可查看详情："
            if notices.isEmpty {
                return .keyword("暂时没有找到竞赛类通知，稍后在「通知」页刷新试试。")
            }
            return .competitions(intro, notices)
        }

        return .keyword(MockAIScript.reply(for: raw, turnIndex: turnIndex))
    }

    private func matchesTodayScheduleQuery(_ normalized: String) -> Bool {
        let hasToday = normalized.contains("今天") || normalized.contains("今日")
        let hasSchedule = normalized.contains("课表") || normalized.contains("课程")
        let hasQuestion =
            normalized.contains("什么")
            || normalized.contains("哪些")
            || normalized.contains("几节")
            || normalized.contains("吗")
            || (normalized.contains("有") && normalized.contains("课"))
        return hasToday && hasSchedule && hasQuestion
    }

    private func matchesCompetitionRecommendQuery(_ normalized: String) -> Bool {
        guard normalized.contains("竞赛") else { return false }
        return normalized.contains("推荐") || normalized.contains("最近") || normalized.contains("哪些") || normalized.contains("什么")
    }

    private func competitionRecommendations(limit: Int) -> [Notice] {
        noticeStore.notices
            .filter { $0.category == .competition }
            .sorted { $0.publishDate > $1.publishDate }
            .prefix(limit)
            .map(\.self)
    }

    /// 模拟 token 节奏：标点多停一点，中文略快于英文。
    private static func tokenDelay(for ch: Character) -> UInt64 {
        let s = String(ch)
        if "，。！？；：、,.!?;:".contains(s) {
            return UInt64(35_000_000 + UInt64.random(in: 0...45_000_000))
        }
        if ch.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
            return UInt64(20_000_000 + UInt64.random(in: 0...25_000_000))
        }
        if let scalar = ch.unicodeScalars.first, scalar.value < 128 {
            return UInt64(10_000_000 + UInt64.random(in: 0...12_000_000))
        }
        return UInt64(14_000_000 + UInt64.random(in: 0...18_000_000))
    }

    func clearSession() {
        streamTask?.cancel()
        streamTask = nil
        streamGeneration += 1
        messages.removeAll()
        userTurnCount = 0
        isGenerating = false
        streamTick = 0
        scriptPhase = .idle
        loadWelcomeIfNeeded()
    }
}
