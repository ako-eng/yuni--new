import SwiftUI

struct GPAView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedSemester: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                gpaCard
                semesterPicker
                semesterSummary
                gradeList
            }
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationTitle("学业成绩")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
            if selectedSemester == nil {
                selectedSemester = viewModel.semesterList.first
            }
        }
    }

    // MARK: - GPA Overview

    private var gpaCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(AppColors.separatorLight, lineWidth: 8)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: viewModel.overallGPA / 5.0)
                    .stroke(
                        LinearGradient(colors: [AppColors.campusBlue, AppColors.mintGreen], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(String(format: "%.2f", viewModel.overallGPA))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("/ 5.00")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("总绩点")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: 16) {
                    miniStat(title: "总学分", value: String(format: "%.0f", viewModel.grades.reduce(0) { $0 + $1.credit }))
                    miniStat(title: "课程", value: "\(viewModel.grades.count)")
                    miniStat(title: "最高", value: String(format: "%.0f", viewModel.grades.map(\.score).max() ?? 0))
                }
            }

            Spacer()
        }
        .padding(16)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.campusBlue)
            Text(title)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Semester Picker

    private var semesterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.semesterList, id: \.self) { semester in
                    let isSelected = selectedSemester == semester
                    Button {
                        withAnimation(AppleSpring.snappy) { selectedSemester = semester }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
                    } label: {
                        HStack(spacing: 4) {
                            Text(semester)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))

                            if isSelected, let sem = selectedSemester {
                                Text(String(format: "%.2f", viewModel.semesterGPA(for: sem)))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? .white.opacity(0.8) : AppColors.campusBlue)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isSelected ? AppColors.campusBlue : AppColors.cardWhite)
                        .foregroundStyle(isSelected ? .white : AppColors.textPrimary)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(isSelected ? 0 : 0.04), radius: 3, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Semester Summary

    private var semesterSummary: some View {
        let grades = currentGrades
        let totalCredit = grades.reduce(0.0) { $0 + $1.credit }
        let avgScore = grades.isEmpty ? 0 : grades.reduce(0.0) { $0 + $1.score } / Double(grades.count)

        return HStack(spacing: 0) {
            summaryItem(title: "课程数", value: "\(grades.count)")
            summaryDivider
            summaryItem(title: "总学分", value: String(format: "%.0f", totalCredit))
            summaryDivider
            summaryItem(title: "平均分", value: String(format: "%.1f", avgScore))
            summaryDivider
            summaryItem(title: "绩点", value: String(format: "%.2f", selectedSemester.map { viewModel.semesterGPA(for: $0) } ?? 0))
        }
        .padding(.vertical, 12)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.campusBlue)
            Text(title)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(AppColors.separatorLight)
            .frame(width: 0.5, height: 24)
    }

    // MARK: - Grade List

    private var currentGrades: [GradeRecord] {
        guard let semester = selectedSemester else { return [] }
        return viewModel.grades(for: semester)
    }

    private var gradeList: some View {
        VStack(spacing: 8) {
            ForEach(currentGrades) { grade in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(grade.courseName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("\(String(format: "%.1f", grade.credit))学分 · 绩点 \(String(format: "%.1f", grade.gradePoint))")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    Text(String(format: "%.0f", grade.score))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor(grade.score))
                }
                .padding(14)
                .background(AppColors.cardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 90 { return AppColors.mintGreen }
        if score >= 80 { return AppColors.campusBlue }
        if score >= 60 { return AppColors.warmOrange }
        return AppColors.softRed
    }
}
