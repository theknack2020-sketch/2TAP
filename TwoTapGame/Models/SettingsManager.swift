import SwiftUI
import Observation

/// App theme options.
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Manages all user-facing settings with UserDefaults persistence.
@Observable
@MainActor
final class SettingsManager {
    static let shared = SettingsManager()

    // MARK: - Sound

    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    var musicEnabled: Bool {
        didSet { UserDefaults.standard.set(musicEnabled, forKey: "musicEnabled") }
    }

    // MARK: - Theme

    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }

    // MARK: - Color Palette

    var selectedPaletteId: String {
        didSet { UserDefaults.standard.set(selectedPaletteId, forKey: "selectedPalette") }
    }

    var selectedPalette: ColorPalette {
        ColorPalette.allPalettes.first { $0.id == selectedPaletteId } ?? .default
    }

    // MARK: - High Score

    var highScore: Int {
        didSet { UserDefaults.standard.set(highScore, forKey: "highScore") }
    }

    var highScoreBestCombo: Int {
        didSet { UserDefaults.standard.set(highScoreBestCombo, forKey: "highScoreBestCombo") }
    }

    var highScoreRounds: Int {
        didSet { UserDefaults.standard.set(highScoreRounds, forKey: "highScoreRounds") }
    }

    // MARK: - Daily Streak

    var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: "currentStreak") }
    }

    var lastPlayDate: Date? {
        didSet { UserDefaults.standard.set(lastPlayDate, forKey: "lastPlayDate") }
    }

    var bestStreak: Int {
        didSet { UserDefaults.standard.set(bestStreak, forKey: "bestStreak") }
    }

    var totalGamesPlayed: Int {
        didSet { UserDefaults.standard.set(totalGamesPlayed, forKey: "totalGamesPlayed") }
    }

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard

        // Register defaults
        defaults.register(defaults: [
            "soundEnabled": true,
            "musicEnabled": true,
            "theme": AppTheme.system.rawValue,
            "selectedPalette": ColorPalette.default.id,
            "highScore": 0,
            "highScoreBestCombo": 0,
            "highScoreRounds": 0,
        ])

        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        self.musicEnabled = defaults.bool(forKey: "musicEnabled")
        self.theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "system") ?? .system
        self.selectedPaletteId = defaults.string(forKey: "selectedPalette") ?? ColorPalette.default.id
        self.highScore = defaults.integer(forKey: "highScore")
        self.highScoreBestCombo = defaults.integer(forKey: "highScoreBestCombo")
        self.highScoreRounds = defaults.integer(forKey: "highScoreRounds")
        self.currentStreak = defaults.integer(forKey: "currentStreak")
        self.lastPlayDate = defaults.object(forKey: "lastPlayDate") as? Date
        self.bestStreak = defaults.integer(forKey: "bestStreak")
        self.totalGamesPlayed = defaults.integer(forKey: "totalGamesPlayed")

        // Check streak on init
        updateStreak()
    }

    // MARK: - Actions

    func updateHighScore(score: Int, bestCombo: Int, rounds: Int) {
        if score > highScore {
            highScore = score
            highScoreBestCombo = bestCombo
            highScoreRounds = rounds
        }
    }

    func resetHighScore() {
        highScore = 0
        highScoreBestCombo = 0
        highScoreRounds = 0
    }

    /// Record a game was played today. Updates streak.
    func recordGamePlayed() {
        totalGamesPlayed += 1

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastPlayDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                return // already played today
            }

            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if daysBetween == 1 {
                // Consecutive day
                currentStreak += 1
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            // First ever game
            currentStreak = 1
        }

        lastPlayDate = Date()
        bestStreak = max(bestStreak, currentStreak)
    }

    /// Check if streak is still valid (called on app launch).
    private func updateStreak() {
        guard let last = lastPlayDate else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: last)
        let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysBetween > 1 {
            // Streak broken — missed a day
            currentStreak = 0
        }
    }
}
