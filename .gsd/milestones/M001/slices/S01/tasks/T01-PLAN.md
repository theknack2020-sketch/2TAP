# T01: Fix bugs — review prompt, race condition, deprecated API, dead code

**Slice:** S01
**Milestone:** M001

## Goal
Fix 4 bugs: broken review prompt (R001), race condition in failure handling (R002), deprecated UIScreen.main (R005), dead musicEnabled code (R006).

## Must-Haves

### Truths
- gamesPlayed counter persists across app relaunches (stored in UserDefaults)
- handleRoundFailure uses cancellable Task pattern — no phantom life loss possible
- GameView scene sizing uses GeometryReader, not UIScreen.main
- No musicEnabled property in SettingsManager or AudioManager
- All 30 existing tests pass
- Build clean

### Artifacts
- `Models/SettingsManager.swift` — gamesPlayed persisted via UserDefaults, musicEnabled removed
- `Game/GameScene.swift` — handleRoundFailure uses stored Task reference with cancellation
- `Views/GameView.swift` — GeometryReader for scene sizing
- `Game/AudioManager.swift` — startMusic/stopMusic/updateMusicState removed

### Key Links
- GameView → SettingsManager.gamesPlayed for review prompt
- GameScene.handleRoundFailure → Task cancellation via stored reference

## Steps
1. Read current SettingsManager — add gamesPlayed property with UserDefaults persistence, remove musicEnabled
2. Read current GameView — replace UIScreen.main with GeometryReader, update review prompt to use settings.totalGamesPlayed
3. Read current GameScene — add stored Task reference for failure handling, cancel on startGame/startNextRound
4. Read current AudioManager — remove startMusic/stopMusic/updateMusicState
5. Run xcodegen generate
6. Build and run tests
7. Verify on simulator

## Context
- SettingsManager already has totalGamesPlayed — may be able to reuse that instead of adding new property
- Race condition: the core issue is Task.sleep in handleRoundFailure can outlive the game session
- DifficultyEngine comment "Starts at 5" is misleading but not a code bug — fix comment while there
