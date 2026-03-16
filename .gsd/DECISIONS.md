# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D001 | M001 | arch | Empty-space tap handling | Only penalize wrong-ball taps, not empty space | Moving balls + tight spacing = too many accidental misses; feels unfair to casual players | Yes — if playtesters say it's too easy |
| D002 | M001 | arch | Color-blind mode approach | Shape overlays on balls (triangle, square, circle, star, diamond) | Shapes are faster to distinguish than patterns at game speed; uses Apple's Differentiate Without Color API | No |
| D003 | M001 | pattern | Review prompt persistence | Move gamesPlayed counter to UserDefaults via SettingsManager | @State resets every view creation — counter never accumulates | No |
| D004 | M001 | arch | Per-difficulty tracking | Separate high scores and leaderboard IDs per difficulty | Single leaderboard unfairly mixes Easy/Normal/Insane players | No |
| D005 | M001 | pattern | Scene sizing | GeometryReader instead of UIScreen.main.bounds | UIScreen.main deprecated in iOS 16; GeometryReader is the SwiftUI-native approach | No |
