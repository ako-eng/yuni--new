import SwiftUI

struct CourseCard: View {
    let course: Course
    var isCurrentCourse: Bool = false

    private var color: Color {
        AppColors.courseColors[course.colorIndex % AppColors.courseColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(course.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer(minLength: 0)

            HStack(spacing: 2) {
                Image(systemName: "mappin")
                    .font(.system(size: 6))
                Text(course.room)
                    .font(.system(size: 8))
            }
            .foregroundStyle(.white.opacity(0.8))
            .lineLimit(1)
        }
        .padding(5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack {
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .frame(height: 20)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
        .overlay(
            isCurrentCourse ?
            RoundedRectangle(cornerRadius: 7)
                .stroke(color, lineWidth: 2)
                .shadow(color: color.opacity(0.6), radius: 6)
            : nil
        )
    }
}
