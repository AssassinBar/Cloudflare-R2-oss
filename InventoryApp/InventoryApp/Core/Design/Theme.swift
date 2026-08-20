import SwiftUI

/// Apple-inspired light design tokens for InventoryApp.
enum AppTheme {
    // MARK: - Colors

    static let background = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let surface = Color.white
    static let surfaceSecondary = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let separator = Color.black.opacity(0.06)

    static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.48)
    static let textTertiary = Color(red: 0.62, green: 0.62, blue: 0.65)

    static let accent = Color(red: 0.0, green: 0.48, blue: 1.0) // system-like blue
    static let accentSoft = Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.12)

    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let warning = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let danger = Color(red: 1.0, green: 0.23, blue: 0.19)

    // MARK: - Typography

    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    // MARK: - Layout

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 12
    static let spacing: CGFloat = 16
    static let pagePadding: CGFloat = 20
}

// MARK: - View helpers

struct SoftShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func softShadow() -> some View {
        modifier(SoftShadow())
    }

    func surfaceCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .softShadow()
    }
}
