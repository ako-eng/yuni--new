import SwiftUI

struct MockAIChatView: View {
    @State private var viewModel = MockAIChatViewModel()
    @State private var input = ""
    @FocusState private var fieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let maxBubbleW = geo.size.width * 0.74
                VStack(spacing: 0) {
                    Text("校园通知、课表与常见问题")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(AppColors.iMessageChatBackground.opacity(0.95))

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, msg in
                                    MockChatBubbleRow(
                                        message: msg,
                                        index: index,
                                        messages: viewModel.messages,
                                        maxBubbleWidth: maxBubbleW,
                                        showStreamingCursor: streamingCursor(for: msg)
                                    )
                                    .id(msg.id)
                                    .padding(.top, topSpacing(for: index))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .background(AppColors.iMessageChatBackground)
                        .onChange(of: viewModel.messages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: viewModel.streamTick) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                    }

                    iMessageInputBar(
                        input: $input,
                        fieldFocused: $fieldFocused,
                        canSend: canSend && !viewModel.isGenerating,
                        disabled: viewModel.isGenerating,
                        onSend: submit
                    )
                }
            }
            .navigationTitle("芋泥助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("清空") {
                        viewModel.clearSession()
                    }
                    .font(.system(size: 17, weight: .regular))
                    .disabled(viewModel.isGenerating)
                }
            }
            .navigationDestination(for: Notice.self) { notice in
                NoticeDetailView(noticeId: notice.id, presentation: .pushed)
            }
        }
        .onAppear {
            viewModel.loadWelcomeIfNeeded()
        }
        .task {
            await NoticeStore.shared.ensureLoaded()
        }
    }

    private func topSpacing(for index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        let prev = viewModel.messages[index - 1].role
        let cur = viewModel.messages[index].role
        if sameRoleGroup(prev, cur) { return 4 }
        return 10
    }

    private func sameRoleGroup(_ a: MockChatRole, _ b: MockChatRole) -> Bool {
        switch (a, b) {
        case (.user, .user): return true
        case (.assistant, .assistant): return true
        case (.thinking, .thinking): return true
        default: return false
        }
    }

    private func streamingCursor(for msg: MockChatMessage) -> Bool {
        if msg.linkedCompetitionNotices != nil { return false }
        guard viewModel.isGenerating,
              msg.role == .assistant,
              let last = viewModel.messages.last,
              last.id == msg.id
        else { return false }
        return true
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last?.id else { return }
        withAnimation(AppleSpring.smooth) {
            proxy.scrollTo(last, anchor: .bottom)
        }
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        guard canSend, !viewModel.isGenerating else { return }
        let t = input
        input = ""
        viewModel.send(t, reduceMotion: reduceMotion)
        fieldFocused = false
    }
}

// MARK: - Input bar (iMessage-like)

private struct iMessageInputBar: View {
    @Binding var input: String
    var fieldFocused: FocusState<Bool>.Binding
    let canSend: Bool
    let disabled: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("输入内容", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.iMessageInputFieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
                .focused(fieldFocused)
                .disabled(disabled)

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(canSend ? AppColors.iMessageOutgoingBubble : AppColors.iMessageSendDisabledFill)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .padding(.bottom, 4)
        .background(.bar)
    }
}

// MARK: - Bubble row

private struct MockChatBubbleRow: View {
    let message: MockChatMessage
    let index: Int
    let messages: [MockChatMessage]
    let maxBubbleWidth: CGFloat
    let showStreamingCursor: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.role == .user { Spacer(minLength: 0) }

            MockChatBubble(
                message: message,
                showStreamingCursor: showStreamingCursor,
                bubbleShape: bubbleShape
            )
            .frame(maxWidth: maxBubbleWidth, alignment: message.role == .user ? .trailing : .leading)

            if message.role != .user { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private var bubbleShape: MockBubbleShape {
        MockBubbleShape.compute(index: index, messages: messages, role: message.role)
    }
}

// MARK: - Bubble shape (stacked iMessage-like corners)

private struct MockBubbleShape: Equatable {
    let topLeading: CGFloat
    let topTrailing: CGFloat
    let bottomLeading: CGFloat
    let bottomTrailing: CGFloat

    static func compute(index: Int, messages: [MockChatMessage], role: MockChatRole) -> MockBubbleShape {
        let r: CGFloat = 18
        let tight: CGFloat = 4
        let tail: CGFloat = 4

        switch role {
        case .user:
            let prevUser = index > 0 && messages[index - 1].role == .user
            let nextUser = index < messages.count - 1 && messages[index + 1].role == .user
            let tl = prevUser ? tight : r
            let tr = prevUser ? tight : r
            let bl = nextUser ? tight : r
            let br = nextUser ? tight : tail
            return MockBubbleShape(topLeading: tl, topTrailing: tr, bottomLeading: bl, bottomTrailing: br)

        case .assistant, .thinking:
            let prevIn = index > 0 && isIncoming(messages[index - 1].role)
            let nextIn = index < messages.count - 1 && isIncoming(messages[index + 1].role)
            let tl = prevIn ? tight : r
            let tr = prevIn ? tight : r
            let bl = nextIn ? tight : tail
            let br = nextIn ? tight : r
            return MockBubbleShape(topLeading: tl, topTrailing: tr, bottomLeading: bl, bottomTrailing: br)
        }
    }

    private static func isIncoming(_ role: MockChatRole) -> Bool {
        role == .assistant || role == .thinking
    }
}

private struct MockChatBubble: View {
    let message: MockChatMessage
    var showStreamingCursor: Bool = false
    var bubbleShape: MockBubbleShape

    var body: some View {
        Group {
            switch message.role {
            case .user:
                userBubble
            case .assistant:
                assistantBubble
            case .thinking:
                thinkingBubble
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: bubbleShape.topLeading,
                bottomLeadingRadius: bubbleShape.bottomLeading,
                bottomTrailingRadius: bubbleShape.bottomTrailing,
                topTrailingRadius: bubbleShape.topTrailing,
                style: .continuous
            )
        )
    }

    private var userBubble: some View {
        Text(message.text)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.iMessageOutgoingBubble)
    }

    @ViewBuilder
    private var assistantBubble: some View {
        if let notices = message.linkedCompetitionNotices, !notices.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(message.text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(notices) { notice in
                    NavigationLink(value: notice) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notice.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColors.iMessageOutgoingBubble)
                                .multilineTextAlignment(.leading)
                            Text(notice.summary)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            HStack(spacing: 4) {
                                Text(notice.source)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tertiary)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.iMessageIncomingBubble)
        } else {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(message.text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.primary)
                if showStreamingCursor {
                    StreamingCursorView()
                        .padding(.leading, 1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.iMessageIncomingBubble)
        }
    }

    private var thinkingBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.iMessageOutgoingBubble)
                Text("正在组织回复")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            ThinkingDotsView()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.iMessageIncomingBubble)
    }
}

/// 思考中的动效展示
private struct ThinkingDotsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 0.16)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    let phase = reduceMotion ? 0.5 : (sin(t * 3.2 + Double(i) * 0.9) * 0.5 + 0.5)
                    Circle()
                        .fill(AppColors.iMessageOutgoingBubble.opacity(0.25 + 0.65 * phase))
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityLabel("正在思考")
        }
    }
}

private struct StreamingCursorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            Rectangle()
                .fill(AppColors.iMessageOutgoingBubble.opacity(0.85))
                .frame(width: 2, height: 16)
        } else {
            TimelineView(.animation(minimumInterval: 0.45)) { context in
                let on = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.9) < 0.45
                Rectangle()
                    .fill(AppColors.iMessageOutgoingBubble.opacity(on ? 0.9 : 0.25))
                    .frame(width: 2, height: 16)
                    .animation(.easeInOut(duration: 0.2), value: on)
            }
            .frame(width: 2, height: 16)
        }
    }
}

#Preview {
    MockAIChatView()
}
