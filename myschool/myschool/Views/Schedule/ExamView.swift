import SwiftUI

struct ExamView: View {
    @State private var viewModel = ScheduleViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                countdownCard
                examList
            }
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationTitle("考试安排")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadData() }
    }

    @ViewBuilder
    private var countdownCard: some View {
        if let next = viewModel.nextExam {
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.warmOrange)
                    Text("距最近考试")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Text("\(next.daysUntil)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.warmOrange)
                + Text(" 天")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)

                Text(next.courseName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(next.formattedDate)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [AppColors.warmOrange.opacity(0.08), AppColors.warmOrange.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.warmOrange.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var examList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("考试列表")
                .font(AppFonts.sectionTitle())
                .padding(.horizontal, 16)

            ForEach(viewModel.exams) { exam in
                HStack(spacing: 14) {
                    VStack(spacing: 2) {
                        Text("\(exam.daysUntil)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(exam.daysUntil <= 7 ? AppColors.softRed : AppColors.campusBlue)
                        Text("天")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(width: 50)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(exam.courseName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)

                        HStack(spacing: 12) {
                            Label(exam.formattedDate, systemImage: "calendar")
                            Label(exam.location, systemImage: "mappin.circle")
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)

                        HStack(spacing: 4) {
                            Image(systemName: "chair.fill")
                                .font(.system(size: 10))
                            Text("座位号: \(exam.seatNumber)")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(AppColors.campusBlue)
                    }

                    Spacer()
                }
                .padding(14)
                .background(AppColors.cardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 16)
            }
        }
    }
}
