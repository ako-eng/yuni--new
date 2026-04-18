import SwiftUI

struct AwardsView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedLevel: AwardLevel?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryCard
                levelFilter
                awardsList
            }
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationTitle("获奖成果")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadData() }
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            awardStat(count: viewModel.awards.filter { $0.level == .national }.count, label: "国家级", color: AppColors.warmOrange)
            awardStat(count: viewModel.awards.filter { $0.level == .provincial }.count, label: "省级", color: AppColors.campusBlue)
            awardStat(count: viewModel.awards.filter { $0.level == .school }.count, label: "校级", color: AppColors.mintGreen)
        }
        .padding(.vertical, 20)
        .background(AppColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func awardStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var levelFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedLevel = nil
                } label: {
                    Text("全部")
                        .chipStyle(isSelected: selectedLevel == nil)
                }

                ForEach(AwardLevel.allCases) { level in
                    Button {
                        selectedLevel = level
                    } label: {
                        Text(level.rawValue)
                            .chipStyle(isSelected: selectedLevel == level)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var filteredAwards: [Award] {
        if let level = selectedLevel {
            return viewModel.awards.filter { $0.level == level }
        }
        return viewModel.awards
    }

    private var awardsList: some View {
        VStack(spacing: 10) {
            ForEach(filteredAwards) { award in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(levelColor(award.level).opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "rosette")
                            .font(.system(size: 20))
                            .foregroundStyle(levelColor(award.level))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(award.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Text(award.level.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(levelColor(award.level))
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text(award.category)
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textSecondary)

                            Spacer()

                            Text(award.formattedDate)
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                .padding(14)
                .background(AppColors.cardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 16)
            }
        }
    }

    private func levelColor(_ level: AwardLevel) -> Color {
        switch level {
        case .national: AppColors.warmOrange
        case .provincial: AppColors.campusBlue
        case .school: AppColors.mintGreen
        }
    }
}
