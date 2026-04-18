import SwiftUI

/// 单圈椭圆轨道，图标等角距分布，避免双轨叠在同一象限造成的「错乱」感。
struct MatchingOrbitLayer: View {
    let icons: [String]
    /// 与用户第一个偏好类别对应的 SF Symbol，用于略放大高亮。
    var highlightedIconName: String?
    var orbitAngle: Double
    var phase: MatchingPhase
    var entranceVisible: Bool

    private let rx: CGFloat = 120
    private let ry: CGFloat = 86

    /// 去重后最多 6 个，保证角度间距 ≥ 60°，视觉清晰。
    private var displayIcons: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for s in icons {
            if seen.insert(s).inserted {
                out.append(s)
            }
            if out.count >= 6 { break }
        }
        if out.isEmpty {
            return ["bell.fill"]
        }
        return out
    }

    private var count: Int { max(displayIcons.count, 1) }

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                .frame(width: rx * 2, height: ry * 2)

            ForEach(Array(displayIcons.enumerated()), id: \.offset) { i, icon in
                let n = Double(count)
                let base = (360.0 / n) * Double(i) + orbitAngle
                let radians = base * .pi / 180
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(iconOpacity(for: icon)))
                    .offset(
                        x: rx * cos(radians),
                        y: ry * sin(radians)
                    )
                    .opacity(entranceVisible ? 1 : 0)
                    .scaleEffect((entranceVisible ? 1 : 0.35) * iconScale(for: icon))
                    .animation(
                        .spring(response: 0.48, dampingFraction: 0.78)
                            .delay(Double(i) * 0.05),
                        value: entranceVisible
                    )
            }
        }
    }

    private func iconOpacity(for icon: String) -> Double {
        let base: Double
        switch phase {
        case .warmingUp: base = 0.22
        case .analyzing: base = 0.28
        case .deepMatching: base = 0.34
        case .finishing: base = 0.3
        }
        if let h = highlightedIconName, h == icon {
            return min(0.95, base + 0.18)
        }
        return base
    }

    private func iconScale(for icon: String) -> CGFloat {
        guard let h = highlightedIconName, h == icon else { return 1.0 }
        return 1.2
    }
}
