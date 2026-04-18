import SwiftUI

enum AppFonts {

    // MARK: - Display & Title

    static func largeTitle() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static func title() -> Font {
        .system(size: 22, weight: .bold, design: .rounded)
    }

    static func title2() -> Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    static func headline() -> Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }

    static func sectionTitle() -> Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }

    // MARK: - Body

    static func body() -> Font {
        .system(size: 15, weight: .regular, design: .rounded)
    }

    static func callout() -> Font {
        .system(size: 14, weight: .regular, design: .rounded)
    }

    // MARK: - Caption

    static func caption() -> Font {
        .system(size: 13, weight: .regular)
    }

    static func smallCaption() -> Font {
        .system(size: 11, weight: .regular)
    }

    // MARK: - Numbers

    static func number() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static func smallNumber() -> Font {
        .system(size: 15, weight: .semibold, design: .rounded)
    }

    static func tinyNumber() -> Font {
        .system(size: 10, weight: .medium, design: .monospaced)
    }
}
