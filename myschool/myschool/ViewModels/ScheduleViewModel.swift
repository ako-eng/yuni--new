import SwiftUI
import Observation

@Observable
class ScheduleViewModel {
    var allCourses: [Course] = []
    var grades: [GradeRecord] = []
    var exams: [ExamInfo] = []
    var awards: [Award] = []
    var currentWeek = MockData.currentWeek
    var selectedDay: Int?

    var todayDayOfWeek: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 ? 7 : weekday - 1
    }

    var activeDay: Int {
        selectedDay ?? todayDayOfWeek
    }

    var coursesForCurrentWeek: [Course] {
        allCourses.filter { $0.isActive(in: currentWeek) }
    }

    var coursesForActiveDay: [Course] {
        coursesForCurrentWeek
            .filter { $0.dayOfWeek == activeDay }
            .sorted { $0.startPeriod < $1.startPeriod }
    }

    var overallGPA: Double { MockData.overallGPA }

    var nextExam: ExamInfo? { MockData.nextExam }

    var semesterList: [String] {
        Array(Set(grades.map(\.semester))).sorted().reversed()
    }

    var weekDescription: String {
        let total = coursesForCurrentWeek.count
        return "本周共 \(total) 节课"
    }

    func grades(for semester: String) -> [GradeRecord] {
        grades.filter { $0.semester == semester }
    }

    func semesterGPA(for semester: String) -> Double {
        let semGrades = grades(for: semester)
        let totalWeighted = semGrades.reduce(0.0) { $0 + $1.gradePoint * $1.credit }
        let totalCredits = semGrades.reduce(0.0) { $0 + $1.credit }
        return totalCredits > 0 ? totalWeighted / totalCredits : 0
    }

    func loadData() {
        // 从后端获取课表
        Task {
            do {
                let studentId = AppSession.shared.studentId
                if !studentId.isEmpty {
                    let courseDTOs = try await APIService.shared.getSchedule(studentId: studentId)
                    // 将 DTO 转换为 Course 模型
                    allCourses = courseDTOs.map { dto in
                        Course(
                            id: dto.id,
                            name: dto.name,
                            teacher: dto.teacher,
                            room: dto.room,
                            dayOfWeek: dto.dayOfWeek,
                            startPeriod: dto.startPeriod,
                            endPeriod: dto.endPeriod,
                            colorIndex: dto.colorIndex,
                            weeks: dto.weeks
                        )
                    }
                    print("课表加载成功，共 \(allCourses.count) 门课")
                } else {
                    // 如果没有学号，使用模拟数据
                    allCourses = MockData.courses
                }
            } catch {
                print("课表加载失败: \(error.localizedDescription)")
                // 加载失败时使用模拟数据
                allCourses = MockData.courses
            }
        }
        // 其他数据仍使用模拟数据
        grades = MockData.grades
        exams = MockData.exams
        awards = MockData.awards
    }
}
