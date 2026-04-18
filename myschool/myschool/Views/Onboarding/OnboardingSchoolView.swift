import SwiftUI

struct OnboardingSchoolView: View {
    @Binding var selectedCollege: String
    @Binding var selectedMajor: String
    @Binding var selectedGrade: String
    var onNext: () -> Void

    @State private var headerIn = false
    @State private var panelIn = false
    @State private var gradesIn = false
    @State private var footerIn = false

    private let grades = ["大一", "大二", "大三", "大四", "研一", "研二", "研三", "博士"]

    private let collegeData: [(name: String, majors: [String])] = [
        ("计算机学院", ["计算机科学与技术", "软件工程", "网络工程", "信息安全", "人工智能"]),
        ("机电工程学院", ["机械设计制造", "电气工程", "自动化", "机器人工程"]),
        ("自动化学院", ["自动化", "电气工程", "智能科学与技术", "物联网工程"]),
        ("信息工程学院", ["电子信息工程", "通信工程", "光电信息", "集成电路"]),
        ("材料与能源学院", ["材料科学与工程", "新能源材料", "高分子材料"]),
        ("轻工化工学院", ["化学工程与工艺", "制药工程", "食品科学"]),
        ("经济学院", ["经济学", "金融学", "国际经济与贸易", "数字经济"]),
        ("管理学院", ["工商管理", "会计学", "市场营销", "信息管理"]),
        ("外国语学院", ["英语", "日语", "商务英语", "翻译"]),
        ("数学与统计学院", ["数学与应用数学", "统计学", "数据科学"]),
        ("物理与光电学院", ["物理学", "光电信息", "应用物理"]),
        ("艺术与设计学院", ["工业设计", "视觉传达", "环境设计", "数字媒体"]),
        ("建筑与城市规划学院", ["建筑学", "城乡规划", "风景园林"]),
        ("土木与交通工程学院", ["土木工程", "交通工程", "工程管理"]),
        ("环境科学与工程学院", ["环境工程", "环境科学", "给排水"]),
        ("生物医药学院", ["生物工程", "生物技术", "制药工程"]),
        ("法学院", ["法学"]),
        ("马克思主义学院", ["思想政治教育"]),
        ("体育部", ["运动训练"]),
        ("其它学院", ["其它专业"]),
    ]

    private var currentMajors: [String] {
        collegeData.first(where: { $0.name == selectedCollege })?.majors ?? []
    }

    private var canProceed: Bool {
        !selectedCollege.isEmpty && !selectedMajor.isEmpty && !selectedGrade.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: 0xFFF8F5))
                Text("你在哪个学院？")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
                .clipShape(Capsule())
            )
            .padding(.top, 24)
            .padding(.bottom, 16)
            .opacity(headerIn ? 1 : 0)
            .offset(y: headerIn ? 0 : 14)
            .blur(radius: headerIn ? 0 : 3)

            HStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(collegeData, id: \.name) { college in
                            SchoolCascadeRow(
                                title: college.name,
                                isSelected: selectedCollege == college.name
                            ) {
                                lightImpact()
                                withAnimation(AppleSpring.snappy) {
                                    selectedCollege = college.name
                                    selectedMajor = college.majors.first ?? ""
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(width: 1)
                    .overlay(Color.white.opacity(0.15))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(currentMajors, id: \.self) { major in
                            SchoolCascadeRow(
                                title: major,
                                isSelected: selectedMajor == major
                            ) {
                                lightImpact()
                                withAnimation(AppleSpring.snappy) {
                                    selectedMajor = major
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 300)
            .background(schoolPanelBackground)
            .padding(.horizontal, 20)
            .scaleEffect(panelIn ? 1 : 0.97)
            .opacity(panelIn ? 1 : 0)
            .blur(radius: panelIn ? 0 : 5)

            VStack(alignment: .leading, spacing: 10) {
                Text("你的年级")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(grades, id: \.self) { grade in
                        Button {
                            lightImpact()
                            withAnimation(AppleSpring.snappy) {
                                selectedGrade = grade
                            }
                        } label: {
                            Text(grade)
                                .font(.system(size: 14, weight: selectedGrade == grade ? .semibold : .regular, design: .rounded))
                                .foregroundStyle(selectedGrade == grade ? Color(hex: 0x4A3F5C) : .white.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedGrade == grade ? Color.white : Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            selectedGrade == grade
                                                ? Color(hex: 0xC4B0DC).opacity(0.45)
                                                : Color.white.opacity(0.08),
                                            lineWidth: selectedGrade == grade ? 1.5 : 1
                                        )
                                )
                                .onboardingBubbleSelection(isSelected: selectedGrade == grade, style: .grade)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .opacity(gradesIn ? 1 : 0)
            .offset(y: gradesIn ? 0 : 18)
            .blur(radius: gradesIn ? 0 : 4)

            Spacer()

            Button(action: onNext) {
                Text("下一步")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(canProceed ? Color(hex: 0x4A3F5C) : Color.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(canProceed ? Color.white : Color.white.opacity(0.15))
                    )
            }
            .disabled(!canProceed)
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(footerIn ? 1 : 0)
            .offset(y: footerIn ? 0 : 12)
        }
        .onAppear(perform: runEntrance)
    }

    private var schoolPanelBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    .padding(2)
            )
    }

    private func runEntrance() {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
            headerIn = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                panelIn = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                gradesIn = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                footerIn = true
            }
        }
    }

    private func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Row

private struct SchoolCascadeRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .frame(width: isSelected ? 3 : 0, height: 18)
                    .animation(AppleSpring.snappy, value: isSelected)

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isSelected ? Color(hex: 0x4A3F5C) : .white.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? Color.white : Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                isSelected ? Color(hex: 0xC4B0DC).opacity(0.35) : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
            }
            .shadow(color: isSelected ? Color(hex: 0xC4B0DC).opacity(0.25) : .clear, radius: 6, y: 2)
            .onboardingBubbleSelection(isSelected: isSelected, style: .compactRow)
        }
        .buttonStyle(.plain)
    }
}
