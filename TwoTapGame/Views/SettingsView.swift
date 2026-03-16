import SwiftUI

/// Settings screen — sound, music, theme, palette, high score reset.
struct SettingsView: View {
    @Environment(SettingsManager.self) private var settings
    let onDismiss: () -> Void

    @State private var showResetConfirm = false
    @State private var showResetFinal = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            List {
                // MARK: - Sound & Haptics
                Section {
                    Toggle(isOn: $settings.soundEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                    }

                    Toggle(isOn: $settings.hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }
                } header: {
                    Text("Audio & Haptics")
                }

                // MARK: - Appearance
                Section {
                    Picker(selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush.fill")
                    }

                    // Color Palette
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Ball Colors", systemImage: "circle.hexagongrid.fill")

                        HStack(spacing: 12) {
                            ForEach(ColorPalette.allPalettes) { palette in
                                PaletteButton(
                                    palette: palette,
                                    isSelected: settings.selectedPaletteId == palette.id
                                ) {
                                    settings.selectedPaletteId = palette.id
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                } header: {
                    Text("Appearance")
                }

                // MARK: - High Score
                Section {
                    HStack {
                        Label("Best Score", systemImage: "trophy.fill")
                        Spacer()
                        Text("\(settings.highScore)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Best Combo", systemImage: "flame.fill")
                        Spacer()
                        Text("x\(settings.highScoreBestCombo)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Most Rounds", systemImage: "arrow.counterclockwise")
                        Spacer()
                        Text("\(settings.highScoreRounds)")
                            .foregroundStyle(.secondary)
                    }

                    // Per-difficulty scores
                    HStack {
                        Label("Easy Best", systemImage: "circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Text("\(settings.highScoreEasy)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Normal Best", systemImage: "circle.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text("\(settings.highScoreNormal)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Insane Best", systemImage: "circle.fill")
                            .foregroundStyle(.red)
                        Spacer()
                        Text("\(settings.highScoreInsane)")
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset High Score", systemImage: "trash")
                    }
                } header: {
                    Text("Records")
                }

                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Reset High Score?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) {
                    showResetFinal = true
                }
            } message: {
                Text("This will permanently delete your best score.")
            }
            .alert("Are you sure?", isPresented: $showResetFinal) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    settings.resetHighScore()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

/// A small palette preview button.
private struct PaletteButton: View {
    let palette: ColorPalette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Color preview dots
                HStack(spacing: 2) {
                    ForEach(0..<min(4, palette.colors.count), id: \.self) { i in
                        Circle()
                            .fill(Color(palette.colors[i]))
                            .frame(width: 12, height: 12)
                    }
                }

                Text(palette.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(onDismiss: {})
        .environment(SettingsManager.shared)
}
