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
        Task {
            let studentId = AppSession.shared.studentId
            guard !studentId.isEmpty else {
                await MainActor.run {
                    allCourses = MockData.courses
                    grades = MockData.grades
                    exams = MockData.exams
                    awards = MockData.awards
                }
                return
            }

            do {
                async let courseTask = APIService.shared.getSchedule(studentId: studentId)
                async let studentDataTask = APIService.shared.getStudentData(studentId: studentId)
                let (courseDTOs, studentData) = try await (courseTask, studentDataTask)

                let mappedCourses = courseDTOs.map { dto in
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

                await MainActor.run {
                    allCourses = mappedCourses
                    grades = studentData.grades
                    exams = studentData.exams
                    awards = studentData.awards
                }
                print("课表/学业数据加载成功，课表 \(mappedCourses.count) 门")
            } catch {
                print("课表/学业数据加载失败: \(error.localizedDescription)")
                await MainActor.run {
                    allCourses = MockData.courses
                    grades = MockData.grades
                    exams = MockData.exams
                    awards = MockData.awards
                }
            }
        }
    }
}
