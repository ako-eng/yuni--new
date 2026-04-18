import SwiftUI

struct WeeklyGridView: View {
    let courses: [Course]
    let todayDayOfWeek: Int
    var selectedDay: Int = -1
    var onCourseTap: ((Course) -> Void)?

    private let periodHeight: CGFloat = 52
    private let timeColumnWidth: CGFloat = 28
    private let dayNames = ["一", "二", "三", "四", "五", "六", "日"]

    private let periodTimes = [
        "08:00", "08:50", "09:50", "10:40",
        "11:30", "12:20", "14:00", "14:50",
        "15:50", "16:40", "18:30", "19:20",
    ]

    var body: some View {
        VStack(spacing: 0) {
            dayHeader
            gridBody
        }
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var dayHeader: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: timeColumnWidth)

            ForEach(1...7, id: \.self) { day in
                Text(dayNames[day - 1])
                    .font(.system(size: 11, weight: day == todayDayOfWeek ? .bold : .regular))
                    .foregroundStyle(day == todayDayOfWeek ? AppColors.campusBlue : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .background(AppColors.background.opacity(0.5))
    }

    private var gridBody: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - timeColumnWidth
            let dayWidth = availableWidth / 7

            HStack(alignment: .top, spacing: 0) {
                timeColumn

                ZStack(alignment: .topLeading) {
                    gridLines(dayWidth: dayWidth)
                    selectedDayHighlight(dayWidth: dayWidth)
                    courseCards(dayWidth: dayWidth)
                }
                .frame(width: availableWidth)
            }
        }
        .frame(height: periodHeight * 12)
    }

    private var timeColumn: some View {
        VStack(spacing: 0) {
            ForEach(0..<12, id: \.self) { index in
                VStack(spacing: 1) {
                    Text("\(index + 1)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(periodTimes[index])
                        .font(.system(size: 6, design: .monospaced))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.6))
                }
                .frame(width: timeColumnWidth, height: periodHeight)
            }
        }
    }

    private func selectedDayHighlight(dayWidth: CGFloat) -> some View {
        Group {
            if selectedDay > 0 {
                Rectangle()
                    .fill(AppColors.campusBlue.opacity(0.04))
                    .frame(width: dayWidth, height: periodHeight * 12)
                    .offset(x: CGFloat(selectedDay - 1) * dayWidth)
            }
        }
    }

    private func gridLines(dayWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<12, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: dayWidth, height: periodHeight)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                }
            }
        }
    }

    private func courseCards(dayWidth: CGFloat) -> some View {
        ForEach(courses) { course in
            let spanHeight = CGFloat(course.endPeriod - course.startPeriod + 1) * periodHeight
            let yOffset = CGFloat(course.startPeriod - 1) * periodHeight
            let xOffset = CGFloat(course.dayOfWeek - 1) * dayWidth

            CourseCard(course: course, isCurrentCourse: course.dayOfWeek == todayDayOfWeek)
                .frame(width: dayWidth - 3, height: spanHeight - 3)
                .offset(x: xOffset + 1.5, y: yOffset + 1.5)
                .onTapGesture {
                    onCourseTap?(course)
                }
        }
    }
}
