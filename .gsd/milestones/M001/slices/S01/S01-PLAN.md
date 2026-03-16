# S01: Bug Fixes & Critical UX

**Goal:** Fix all 6 identified bugs and the 2 critical UX issues so the game is fair and functional.
**Demo:** Game plays without race conditions. Review prompt persists. Player can exit from pause. Empty-space taps don't cost lives. No deprecated API usage. No dead code.

## Must-Haves
- Review prompt gamesPlayed counter persists across app launches
- No race condition in handleRoundFailure (task cancellation pattern)
- Pause screen has "Home" button that returns to main menu
- Empty-space taps produce no penalty (only wrong-ball taps cost lives)
- UIScreen.main.bounds replaced with GeometryReader
- musicEnabled dead code removed from AudioManager and SettingsManager
- All 30 existing tests still pass
- Build clean with no warnings

## Tasks

- [ ] **T01: Fix bugs — review prompt, race condition, deprecated API, dead code**
  Fix R001 (gamesPlayed to UserDefaults), R002 (task cancellation in handleRoundFailure), R005 (GeometryReader), R006 (remove musicEnabled dead code). Build + test verification.

- [ ] **T02: Critical UX — pause Home button, empty-tap penalty removal**
  Fix R003 (Home button on pause overlay) and R004 (only wrong-ball taps cost lives). Simulator visual verification.

## Files Likely Touched
- TwoTapGame/Views/GameView.swift
- TwoTapGame/Game/GameScene.swift
- TwoTapGame/Game/GameState.swift
- TwoTapGame/Game/AudioManager.swift
- TwoTapGame/Models/SettingsManager.swift
