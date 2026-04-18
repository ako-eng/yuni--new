import SwiftUI

struct ScheduleView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedCourse: Course?
    @Namespace private var dayAnimation

    private let dayNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    private let periodStartTimes = [
        "08:00", "08:50", "09:50", "10:40",
        "11:30", "12:20", "14:00", "14:50",
        "15:50", "16:40", "18:30", "19:20",
    ]
    private let periodEndTimes = [
        "08:45", "09:35", "10:35", "11:25",
        "12:15", "13:05", "14:45", "15:35",
        "16:35", "17:25", "19:15", "20:05",
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    scheduleHeader
                    timetableSection
                    functionCards
                }
                .padding(.bottom, 20)
            }
            .background(AppColors.background)
            .navigationTitle("我的课表")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedCourse) { course in
                courseDetailSheet(course)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear { viewModel.loadData() }
    }

    // MARK: - Schedule Header (Week + Day + Summary)

    private var weekNavigator: some View {
        EmptyView()
    }

    private var daySelector: some View {
        EmptyView()
    }

    private var daySummary: some View {
        EmptyView()
    }

    private var scheduleHeader: some View {
        let courses = viewModel.coursesForActiveDay
        let dayName = dayNames[viewModel.activeDay - 1]

        return VStack(spacing: 0) {
            // Week + Day selector row
            HStack(spacing: 0) {
                // Left arrow
                Button {
                    if viewModel.currentWeek > 1 {
                        withAnimation(AppleSpring.snappy) { viewModel.currentWeek -= 1 }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(viewModel.currentWeek > 1 ? AppColors.campusBlue : AppColors.textSecondary.opacity(0.3))
                        .frame(width: 28, height: 36)
                }
                .disabled(viewModel.currentWeek <= 1)

                // Week label
                Menu {
                    ForEach(1...20, id: \.self) { week in
                        Button {
                            withAnimation(AppleSpring.smooth) { viewModel.currentWeek = week }
                        } label: {
                            HStack {
                                Text("第\(week)周")
                                if week == MockData.currentWeek { Text("(本周)") }
                                if week == viewModel.currentWeek { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("第\(viewModel.currentWeek)周")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)

                        if viewModel.currentWeek == MockData.currentWeek {
                            Text("本周")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1.5)
                                .background(AppColors.campusBlue)
                                .clipShape(Capsule())
                        }

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                    }
                }

                // Right arrow
                Button {
                    if viewModel.currentWeek < 20 {
                        withAnimation(AppleSpring.snappy) { viewModel.currentWeek += 1 }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(viewModel.currentWeek < 20 ? AppColors.campusBlue : AppColors.textSecondary.opacity(0.3))
                        .frame(width: 28, height: 36)
                }
                .disabled(viewModel.currentWeek >= 20)

                Spacer()

                // Day summary inline
                if courses.isEmpty {
                    Text("\(dayName)无课")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppColors.campusBlue)
                            .frame(width: 5, height: 5)
                        Text("\(dayName)\(courses.count)节")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // Day selector
            HStack(spacing: 0) {
                ForEach(1...7, id: \.self) { day in
                    let isActive = day == viewModel.activeDay
                    let isToday = day == viewModel.todayDayOfWeek && viewModel.currentWeek == MockData.currentWeek
                    let hasCourses = viewModel.coursesForCurrentWeek.contains { $0.dayOfWeek == day }

                    VStack(spacing: 3) {
                        Text(dayNames[day - 1])
                            .font(.system(size: 12, weight: isActive ? .bold : .regular, design: .rounded))
                            .foregroundStyle(isActive ? .white : (isToday ? AppColors.campusBlue : AppColors.textSecondary))

                        Circle()
                            .fill(hasCourses ? (isActive ? .white.opacity(0.8) : AppColors.campusBlue.opacity(0.4)) : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background {
                        if isActive {
                            Capsule()
                                .fill(AppColors.campusBlue)
                                .matchedGeometryEffect(id: "dayIndicator", in: dayAnimation)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(AppleSpring.snappy) { viewModel.selectedDay = day }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .background(AppColors.cardWhite)
    }

    // MARK: - Timetable

    private var timetableSection: some View {
        WeeklyGridView(
            courses: viewModel.coursesForCurrentWeek,
            todayDayOfWeek: viewModel.currentWeek == MockData.currentWeek ? viewModel.todayDayOfWeek : -1,
            selectedDay: viewModel.activeDay,
            onCourseTap: { course in
                selectedCourse = course
            }
        )
        .padding(.horizontal, 8)
        .id(viewModel.currentWeek)
        .transition(.push(from: .trailing))
    }

    // MARK: - Function Cards

    private var functionCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习服务")
                .font(AppFonts.sectionTitle())
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 16)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                NavigationLink { GPAView() } label: {
                    functionCard(
                        icon: "chart.bar.fill",
                        title: "学业成绩",
                        value: String(format: "%.2f", viewModel.overallGPA),
                        color: AppColors.campusBlue
                    )
                }
                .buttonStyle(PressableButtonStyle())

                NavigationLink { ExamView() } label: {
                    functionCard(
                        icon: "clock.badge.exclamationmark",
                        title: "考试安排",
                        value: viewModel.nextExam.map { "\($0.daysUntil)天后" } ?? "暂无",
                        color: AppColors.warmOrange
                    )
                }
                .buttonStyle(PressableButtonStyle())

                NavigationLink { AwardsView() } label: {
                    functionCard(
                        icon: "rosette",
                        title: "获奖成果",
                        value: "\(viewModel.awards.count)项",
                        color: AppColors.softRed
                    )
                }
                .buttonStyle(PressableButtonStyle())

                NavigationLink {
                    placeholderPage(title: "学分进度", icon: "chart.pie.fill")
                } label: {
                    functionCard(
                        icon: "chart.pie.fill",
                        title: "学分进度",
                        value: String(format: "%.0f/170", viewModel.grades.reduce(0) { $0 + $1.credit }),
                        color: AppColors.mintGreen
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 16)
        }
    }

    private func functionCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
                Text(value)
                    .font(AppFonts.smallNumber())
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()
        }
        .padding(14)
        .cardStyle()
    }

    private func placeholderPage(title: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)
            Text("暂未开放，敬请期待")
                .font(AppFonts.callout())
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Course Detail Sheet

    private func courseDetailSheet(_ course: Course) -> some View {
        let color = AppColors.courseColors[course.colorIndex % AppColors.courseColors.count]
        let startIdx = max(0, min(course.startPeriod - 1, periodStartTimes.count - 1))
        let endIdx = max(0, min(course.endPeriod - 1, periodEndTimes.count - 1))
        let timeRange = periodStartTimes[startIdx] + " - " + periodEndTimes[endIdx]
        let weeksText = formatWeeks(course.weeks)

        return VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 80)
                .overlay(
                    VStack(spacing: 4) {
                        Text(course.name)
                            .font(AppFonts.title())
                            .foregroundStyle(.white)
                        Text(dayNames[course.dayOfWeek - 1] + " 第\(course.startPeriod)-\(course.endPeriod)节")
                            .font(AppFonts.callout())
                            .foregroundStyle(.white.opacity(0.85))
                    }
                )

            VStack(spacing: 20) {
                detailRow(icon: "person.fill", label: "授课教师", value: course.teacher, color: color)
                Divider()
                detailRow(icon: "mappin.circle.fill", label: "上课教室", value: course.room, color: color)
                Divider()
                detailRow(icon: "clock.fill", label: "上课时间", value: timeRange, color: color)
                Divider()
                detailRow(icon: "calendar", label: "上课周次", value: weeksText, color: color)
            }
            .padding(24)

            Spacer()
        }
    }

    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24)

            Text(label)
                .font(AppFonts.callout())
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(AppFonts.body())
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formatWeeks(_ weeks: [Int]) -> String {
        guard !weeks.isEmpty else { return "无" }
        let sorted = weeks.sorted()
        if sorted == Array(sorted.first!...sorted.last!) {
            return "第\(sorted.first!)—\(sorted.last!)周"
        }
        let isOdd = sorted.allSatisfy { $0 % 2 == 1 }
        let isEven = sorted.allSatisfy { $0 % 2 == 0 }
        if isOdd {
            return "第\(sorted.first!)—\(sorted.last!)周(单周)"
        } else if isEven {
            return "第\(sorted.first!)—\(sorted.last!)周(双周)"
        }
        return weeks.map { String($0) }.joined(separator: ",") + "周"
    }
}
