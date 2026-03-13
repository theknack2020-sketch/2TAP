# M001: 2TAP Game — Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

## Project Description

2TAP is a fast-paced iOS reflex/perception game. The name comes from "2 seconds" — the player always has exactly 2 seconds per round, no exceptions. Each round, colored 3D metallic balls appear on screen. One color is repeated (2 or 3 times), the rest are unique. The player must find and tap all matching-color balls within 2 seconds. Endless rounds, increasing difficulty, combo scoring. The game targets both kids (friendly, cartoon-like feel — "sevecen") and adults.

## Why This Milestone

This is the entire game — from empty directory to App Store-ready product. One milestone because the scope is well-defined: single-screen game loop, settings, audio, AI assets, and ASO.

## User-Visible Outcome

### When this milestone is complete, the user can:

- Open the app, see an animated main menu, tap Play, and play 2TAP end-to-end
- Adjust settings (sound, music, theme, color palette), have them persist
- See their high score, try to beat it
- Submit the app to App Store with fully optimized ASO

### Entry point / environment

- Entry point: iOS app launch
- Environment: iPhone (iOS 17+), simulator for development
- Live dependencies involved: none (fully offline game, Gemini API used only at build time for asset generation)

## Completion Class

- Contract complete means: all game mechanics work correctly — scoring, lives, combos, difficulty progression, timer, pause
- Integration complete means: SwiftUI menus ↔ SpriteKit game scene ↔ UserDefaults persistence ↔ audio system all wired together
- Operational complete means: app builds, runs on simulator, all assets generated and embedded, ASO metadata ready

## Final Integrated Acceptance

To call this milestone complete, we must prove:

- Full game session: menu → play → survive multiple rounds → game over → see score → replay
- Settings changes persist across app restarts (theme, sound, high score)
- AI-generated assets (logo, icon, backgrounds) are embedded and display correctly
- App Store listing metadata is complete and optimized

## Risks and Unknowns

- **Ball placement algorithm** — ensuring non-overlapping placement with finger gaps at higher ball counts (10+). Could hit performance or unsolvable placement scenarios. Risk: medium.
- **3D metallic ball rendering in SpriteKit** — achieving convincing 3D look with shaders or pre-rendered textures. Risk: medium.
- **Gemini API asset quality** — generated assets may need multiple iterations for acceptable quality. Logo especially needs careful prompt engineering. Risk: medium.
- **Color similarity for difficulty** — generating colors that are "similar but distinguishable" at higher difficulties without being unfair. Risk: low-medium.

## Existing Codebase / Prior Art

- Empty project — no existing code
- Skills available: `ios-factory` (end-to-end iOS production), `swiftui` (SwiftUI patterns)
- Gemini icon generation script: `~/.gsd/agent/skills/ios-factory/references/app-icon-generator.md`
- ASO guide: `~/.gsd/agent/skills/ios-factory/references/aso-guide.md`

> See `.gsd/DECISIONS.md` for all architectural and pattern decisions — it is an append-only register; read it during planning, append to it during execution.

## Relevant Requirements

- R001-R003 — Core game loop, ball placement, color matching (S01)
- R004-R007, R010, R017 — Scoring, lives, difficulty, frame feedback, pause (S02)
- R011-R012, R018-R019 — Menus, settings, theming, palettes (S03)
- R013-R014 — Game over, persistent score (S04)
- R015-R016 — Sound effects, background music (S05)
- R020 — AI asset generation with Gemini (S06)
- R021 — ASO & App Store readiness (S07)

## Scope

### In Scope

- Complete game with all mechanics (timer, balls, scoring, lives, combos, difficulty, pause)
- Main menu, settings, game over screens
- Dark/light/system theme support
- Multiple color palettes
- Sound effects and 10 background music loops
- AI-generated assets (logo with extra care, app icon, backgrounds)
- Full ASO optimization
- Xcode project setup, build, simulator testing

### Out of Scope / Non-Goals

- Multiplayer
- Level/chapter system (it's endless rounds)
- Cross-platform (iOS only)
- Rewarded ads (deferred — slot prepared)
- Game Center leaderboard (deferred)
- Real device testing (simulator only in this milestone)

## Technical Constraints

- iOS 17+ minimum (for @Observable, modern SwiftUI APIs)
- SwiftUI for all non-gameplay UI
- SpriteKit for game scene (embedded via SpriteView)
- UserDefaults for persistence (no SwiftData needed — just scores and settings)
- Gemini API at build time only — game works fully offline
- GEMINI_API_KEY required for asset generation phase

## Integration Points

- **SwiftUI ↔ SpriteKit** — SpriteView embedding, state passing via @Observable game manager
- **Game Manager ↔ UserDefaults** — high score, settings persistence
- **Audio Manager ↔ AVFoundation** — background music loops, sound effects
- **Gemini API** — build-time asset generation (logo, icon, backgrounds)

## Open Questions

- Exact ball count cap — need to test on smallest iPhone screen with finger gaps. Will determine during S01.
- Color palette alternatives beyond metallic — will design 2-3 options during S03.
- Background music sourcing — 10 royalty-free loops. Will use bundled/generated assets.

## Key User Terminology (preserve exactly)

- "sevecen" — warm, friendly, lovable feel for the UI/backgrounds
- "craft feel" implied — metallic 3D balls, not flat circles
- "2 saniye" — sacred, never changes, it's the game's identity
- "karmaşık renkler" — complex/rich colors, not primary-only
- "çizgi film sesi" — cartoon-like sound effects
- "mükemmel şekilde" — ASO must be thorough, no shortcuts
