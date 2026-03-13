import SwiftUI
import UIKit

/// A named collection of colors used for ball rendering.
struct ColorPalette: Identifiable, Hashable {
    let id: String
    let name: String
    let colors: [UIColor]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ColorPalette, rhs: ColorPalette) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Built-in Palettes

extension ColorPalette {
    /// Metallic/glossy palette — rich, complex colors. Default palette.
    static let metallic = ColorPalette(
        id: "metallic",
        name: "Metallic",
        colors: [
            UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0),  // Gold
            UIColor(red: 0.72, green: 0.45, blue: 0.20, alpha: 1.0),  // Copper
            UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0),  // Silver
            UIColor(red: 0.18, green: 0.55, blue: 0.34, alpha: 1.0),  // Emerald
            UIColor(red: 0.15, green: 0.35, blue: 0.73, alpha: 1.0),  // Sapphire
            UIColor(red: 0.78, green: 0.08, blue: 0.22, alpha: 1.0),  // Ruby
            UIColor(red: 0.50, green: 0.18, blue: 0.56, alpha: 1.0),  // Amethyst
            UIColor(red: 0.90, green: 0.44, blue: 0.13, alpha: 1.0),  // Amber
            UIColor(red: 0.00, green: 0.60, blue: 0.60, alpha: 1.0),  // Teal
            UIColor(red: 0.86, green: 0.24, blue: 0.44, alpha: 1.0),  // Rose
            UIColor(red: 0.38, green: 0.64, blue: 0.18, alpha: 1.0),  // Peridot
            UIColor(red: 0.07, green: 0.25, blue: 0.50, alpha: 1.0),  // Navy
            UIColor(red: 0.82, green: 0.71, blue: 0.55, alpha: 1.0),  // Champagne
            UIColor(red: 0.44, green: 0.16, blue: 0.07, alpha: 1.0),  // Bronze
            UIColor(red: 0.55, green: 0.47, blue: 0.76, alpha: 1.0),  // Lavender
            UIColor(red: 0.93, green: 0.57, blue: 0.13, alpha: 1.0),  // Tangerine
            UIColor(red: 0.22, green: 0.69, blue: 0.67, alpha: 1.0),  // Turquoise
            UIColor(red: 0.60, green: 0.10, blue: 0.10, alpha: 1.0),  // Garnet
        ]
    )

    /// Neon/vivid palette — bright, electric colors.
    static let neon = ColorPalette(
        id: "neon",
        name: "Neon",
        colors: [
            UIColor(red: 1.00, green: 0.07, blue: 0.57, alpha: 1.0),  // Hot Pink
            UIColor(red: 0.00, green: 1.00, blue: 0.50, alpha: 1.0),  // Neon Green
            UIColor(red: 0.00, green: 0.75, blue: 1.00, alpha: 1.0),  // Electric Blue
            UIColor(red: 1.00, green: 0.92, blue: 0.00, alpha: 1.0),  // Neon Yellow
            UIColor(red: 0.75, green: 0.00, blue: 1.00, alpha: 1.0),  // Purple Glow
            UIColor(red: 1.00, green: 0.40, blue: 0.00, alpha: 1.0),  // Orange Neon
            UIColor(red: 0.00, green: 1.00, blue: 1.00, alpha: 1.0),  // Cyan
            UIColor(red: 1.00, green: 0.00, blue: 0.00, alpha: 1.0),  // Red Neon
            UIColor(red: 0.50, green: 1.00, blue: 0.00, alpha: 1.0),  // Lime
            UIColor(red: 1.00, green: 0.41, blue: 0.71, alpha: 1.0),  // Pink Glow
            UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 1.0),  // Cornflower
            UIColor(red: 0.00, green: 0.80, blue: 0.40, alpha: 1.0),  // Spring Green
            UIColor(red: 1.00, green: 0.65, blue: 0.00, alpha: 1.0),  // Amber Glow
            UIColor(red: 0.58, green: 0.00, blue: 0.83, alpha: 1.0),  // Violet
            UIColor(red: 0.25, green: 0.88, blue: 0.82, alpha: 1.0),  // Aquamarine
        ]
    )

    /// Pastel palette — soft, muted colors.
    static let pastel = ColorPalette(
        id: "pastel",
        name: "Pastel",
        colors: [
            UIColor(red: 1.00, green: 0.71, blue: 0.76, alpha: 1.0),  // Pastel Pink
            UIColor(red: 0.68, green: 0.85, blue: 0.90, alpha: 1.0),  // Pastel Blue
            UIColor(red: 0.60, green: 0.98, blue: 0.60, alpha: 1.0),  // Pastel Green
            UIColor(red: 1.00, green: 1.00, blue: 0.60, alpha: 1.0),  // Pastel Yellow
            UIColor(red: 0.80, green: 0.60, blue: 0.80, alpha: 1.0),  // Pastel Purple
            UIColor(red: 1.00, green: 0.85, blue: 0.73, alpha: 1.0),  // Pastel Peach
            UIColor(red: 0.69, green: 0.88, blue: 0.90, alpha: 1.0),  // Powder Blue
            UIColor(red: 0.94, green: 0.90, blue: 0.55, alpha: 1.0),  // Pastel Gold
            UIColor(red: 0.80, green: 0.73, blue: 0.96, alpha: 1.0),  // Pastel Lavender
            UIColor(red: 0.56, green: 0.93, blue: 0.56, alpha: 1.0),  // Light Green
            UIColor(red: 1.00, green: 0.63, blue: 0.48, alpha: 1.0),  // Coral
            UIColor(red: 0.69, green: 0.77, blue: 0.87, alpha: 1.0),  // Steel Blue
            UIColor(red: 0.96, green: 0.76, blue: 0.76, alpha: 1.0),  // Misty Rose
            UIColor(red: 0.73, green: 0.91, blue: 0.73, alpha: 1.0),  // Mint
        ]
    )

    /// All available palettes.
    static let allPalettes: [ColorPalette] = [.metallic, .neon, .pastel]

    /// Default palette.
    static let `default` = metallic
}
