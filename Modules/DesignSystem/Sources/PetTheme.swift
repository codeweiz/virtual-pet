import SwiftUI

/// Color tokens. DesignSystem is domain-agnostic — it exposes a palette; mapping
/// a *mood* to colors happens one layer up (where PetKit is also available).
public enum PetPalette {
    public static let periwinkle = Color(red: 0.55, green: 0.45, blue: 0.95)
    public static let blush = Color(red: 0.97, green: 0.66, blue: 0.86)
    public static let mint = Color(red: 0.50, green: 0.90, blue: 0.78)
    public static let butter = Color(red: 0.99, green: 0.85, blue: 0.45)
    public static let coral = Color(red: 0.99, green: 0.55, blue: 0.50)
    public static let ink = Color(red: 0.12, green: 0.10, blue: 0.22)
}

public enum PetMetrics {
    public static let corner: CGFloat = 24
    public static let spacing: CGFloat = 12
}

extension Font {
    public static let petTitle = Font.system(.title2, design: .rounded).weight(.bold)
    public static let petCaption = Font.system(.caption, design: .rounded).weight(.medium)
}
