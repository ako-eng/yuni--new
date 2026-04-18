import SwiftUI

struct OnboardingTagsView: View {
    @Binding var selectedTags: [String]
    var onNext: () -> Void
    var onSkip: () -> Void

    @State private var headerIn = false
    @State private var subtitleIn = false
    @State private var groupsIn = false
    @State private var footerIn = false

    private let tagGroups: [(title: String, tags: [String])] = [
        ("学业相关", ["奖学金", "四六级", "考研", "选课", "转专业", "双学位", "补考", "毕业设计", "学分", "绩点", "保研"]),
        ("生活相关", ["宿舍", "校园卡", "社团", "志愿者", "体测"]),
        ("求职相关", ["实习", "校招", "讲座", "创新创业"]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: 0xFFF8F5))
                Text("还有什么特别关注的话题吗？")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.top, 24)
            .padding(.bottom, 6)
            .opacity(headerIn ? 1 : 0)
            .offset(y: headerIn ? 0 : 12)
            .blur(radius: headerIn ? 0 : 3)

            Text("可选步骤，跳过也完全没问题")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.bottom, 20)
                .opacity(subtitleIn ? 1 : 0)
                .offset(y: subtitleIn ? 0 : 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(tagGroups.enumerated()), id: \.element.title) { groupIndex, group in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: 0xC4B0DC).opacity(0.85))
                                    .frame(width: 6, height: 6)
                                Text(group.title)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.55))
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 2)
                                    .frame(maxWidth: 56)
                                    .opacity(groupsIn ? 1 : 0)
                                    .animation(
                                        .easeOut(duration: 0.45).delay(0.08 + Double(groupIndex) * 0.06),
                                        value: groupsIn
                                    )
                            }
                            .padding(.leading, 4)

                            FlowLayout(spacing: 10) {
                                ForEach(group.tags, id: \.self) { tag in
                                    TagChip(
                                        label: tag,
                                        isSelected: selectedTags.contains(tag),
                                        onTap: { toggleTag(tag) }
                                    )
                                }
                            }
                            .animation(AppleSpring.smooth, value: selectedTags)
                        }
                        .opacity(groupsIn ? 1 : 0)
                        .offset(y: groupsIn ? 0 : 18)
                        .animation(
                            .spring(response: 0.48, dampingFraction: 0.82)
                                .delay(min(Double(groupIndex) * 0.08, 0.28)),
                            value: groupsIn
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                if !selectedTags.isEmpty {
                    HStack(spacing: 4) {
                        Text("已选")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("\(selectedTags.count)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("个标签")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                Button(action: onNext) {
                    Text("完成")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x4A3F5C))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: Color(hex: 0x4A3F5C).opacity(0.12), radius: 8, y: 4)
                        )
                }
                .buttonStyle(OnboardingPrimaryPressStyle())
                .padding(.horizontal, 40)

                Button(action: onSkip) {
                    Text("跳过")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.bottom, 50)
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: selectedTags.isEmpty)
            .opacity(footerIn ? 1 : 0)
            .offset(y: footerIn ? 0 : 12)
        }
        .onAppear(perform: runEntrance)
    }

    private func runEntrance() {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
            headerIn = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                subtitleIn = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                groupsIn = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                footerIn = true
            }
        }
    }

    private func toggleTag(_ tag: String) {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.62)) {
            if let idx = selectedTags.firstIndex(of: tag) {
                selectedTags.remove(at: idx)
            } else {
                selectedTags.append(tag)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private struct TagChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isSelected ? Color(hex: 0x4A3F5C) : .white.opacity(0.82))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(chipBackground)
                .overlay(chipOuterGlow)
                .overlay(chipInnerStroke)
                .onboardingBubbleSelection(isSelected: isSelected, style: .tagChip)
        }
        .buttonStyle(OnboardingTagPressStyle())
    }

    private var chipBackground: some View {
        Capsule()
            .fill(isSelected ? Color.white : Color.white.opacity(0.1))
    }

    @ViewBuilder
    private var chipOuterGlow: some View {
        if isSelected {
            Capsule()
                .stroke(Color.white.opacity(0.5), lineWidth: 2.2)
                .blur(radius: 0.5)
        }
    }

    @ViewBuilder
    private var chipInnerStroke: some View {
        if isSelected {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color(hex: 0xC4B0DC).opacity(0.65),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.15
                )
        } else {
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        }
    }
}

private struct OnboardingTagPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct OnboardingPrimaryPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.78), value: configuration.isPressed)
    }
}
