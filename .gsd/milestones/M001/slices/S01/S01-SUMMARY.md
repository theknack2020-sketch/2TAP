---
id: S01
parent: M001
provides:
  - Fixed review prompt (totalGamesPlayed persisted via UserDefaults)
  - Cancellable failure task (no race condition)
  - GeometryReader-based scene sizing (no deprecated UIScreen.main)
  - Removed musicEnabled dead code from AudioManager + SettingsManager
  - Home button on pause overlay
  - Empty-space taps no longer penalize
key_files:
  - TwoTapGame/Game/GameScene.swift
  - TwoTapGame/Views/GameView.swift
  - TwoTapGame/Models/SettingsManager.swift
  - TwoTapGame/Game/AudioManager.swift
  - TwoTapGame/Game/DifficultyEngine.swift
key_decisions:
  - "D001: Only wrong-ball taps cost lives, not empty space"
  - "D003: Review prompt uses settings.totalGamesPlayed (UserDefaults-persisted)"
  - "D005: GeometryReader replaces UIScreen.main.bounds"
patterns_established:
  - "failureTask stored reference pattern for cancellable async work in GameScene"
drill_down_paths:
  - .gsd/milestones/M001/slices/S01/tasks/T01-PLAN.md
  - .gsd/milestones/M001/slices/S01/tasks/T02-PLAN.md
verification_result: pass
completed_at: 2026-03-16T01:00:00Z
---

# S01: Bug Fixes & Critical UX

**Fixed 6 bugs and 2 critical UX issues — game is now fair and functional**

## What Happened

Fixed the broken review prompt by using settings.totalGamesPlayed (already UserDefaults-persisted) instead of a @State counter that reset every view creation. Fixed the race condition in handleRoundFailure by storing the Task reference and cancelling it on startGame/stopGame. Replaced UIScreen.main.bounds with GeometryReader for scene sizing. Removed dead musicEnabled property and music stub methods. Added Home button to pause overlay. Removed empty-space tap penalty per D001 — only wrong-ball taps cost lives now.

All 30 existing tests pass. Build clean. Verified on iPhone 16 Pro simulator.
