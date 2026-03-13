# Requirements

## Active

### R001 — Core Game Loop
- Class: primary-user-loop
- Status: active
- Description: 2-second timer per round. Balls spawn, player taps matching-color balls within 2s. Round cycles: countdown → balls appear → player taps → result → next round.
- Why it matters: This IS the game. Without the core loop nothing else matters.
- Source: user
- Primary owning slice: M001/S01
- Supporting slices: M001/S02
- Validation: unmapped
- Notes: 2 seconds is the game's identity — never changes

### R002 — Ball Placement Algorithm
- Class: core-capability
- Status: active
- Description: Balls placed randomly on screen, non-overlapping, with at least a finger-tap gap between them. Balls fully visible, never clipped by screen edges.
- Why it matters: Overlapping balls make the game unplayable. Tight spacing causes accidental taps.
- Source: user
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Must handle variable ball counts (5-12+)

### R003 — Color Matching Logic
- Class: core-capability
- Status: active
- Description: Each round has one color that appears 2 or 3 times. All other colors are unique. Max 3 of the same color per round. Only one color repeats per round.
- Why it matters: This is the puzzle — finding the repeated color among unique ones.
- Source: user
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Never more than 3 of same color

### R004 — 3D Metallic Ball Rendering
- Class: differentiator
- Status: active
- Description: Balls rendered with 3D metallic/shiny appearance — highlights, shading, depth effect. Default palette is metallic/glossy.
- Why it matters: Visual quality differentiates from simple circle-based games. "Craft feel."
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Multiple palette options selectable in settings

### R005 — Score System with Combo Multiplier
- Class: primary-user-loop
- Status: active
- Description: Base points per correct match. Consecutive correct rounds increase combo multiplier (x2, x3, x4...). One mistake resets combo to x1.
- Why it matters: Combo creates the "one more round" tension that drives engagement.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: M001/S04
- Validation: unmapped
- Notes: Progressive scoring — high scores should feel earned

### R006 — Lives System
- Class: core-capability
- Status: active
- Description: 3 lives per game. Lose a life on wrong tap or timeout. Earn +1 life every 10 consecutive perfect rounds. Game ends when all 3 lives lost.
- Why it matters: Lives create stakes without making the game too punishing. Reward loop keeps hope alive.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R007 — Difficulty Progression
- Class: core-capability
- Status: active
- Description: Ball count increases at score thresholds (starts at 5, grows). Color similarity also increases at higher levels (harder to distinguish). 2-second timer never changes.
- Why it matters: Without progression the game gets boring. With too much, it becomes frustrating.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Ball cap determined by screen size. Timer is sacred — always 2s.

### R008 — Countdown Animation
- Class: quality-attribute
- Status: active
- Description: Before each round, large green "3-2-1" countdown appears center screen. After countdown, balls appear and timer starts.
- Why it matters: Gives the player a moment to prepare. Builds anticipation rhythm.
- Source: user
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Only at game start — between rounds the cycle is immediate (toplar kaybolur → yeni toplar belirir)

### R009 — Timer Bar
- Class: core-capability
- Status: active
- Description: Visual countdown bar at top of screen. Drains over 2 seconds. Clear visual feedback of remaining time.
- Why it matters: Without visual time feedback, the game feels unfair.
- Source: user
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: unmapped
- Notes: Direction (fill vs drain) — whichever looks better visually

### R010 — Frame Feedback
- Class: quality-attribute
- Status: active
- Description: Screen border/frame flashes green on correct match, red on wrong/timeout. Feedback is immediate and brief.
- Why it matters: Instant visual feedback without blocking gameplay. Player knows result without reading text.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: Feedback-driven, not decorative — no rainbow border effects

### R011 — Main Menu
- Class: launchability
- Status: active
- Description: Animated, friendly background (cartoon-like, appealing to kids but not childish). Game logo/banner prominently displayed. Play button and Settings button.
- Why it matters: First impression. Sets the tone — fun, inviting, polished.
- Source: user
- Primary owning slice: M001/S03
- Supporting slices: M001/S06
- Validation: unmapped
- Notes: Not static/boring. Alive, warm, "sevecen" feel. English UI.

### R012 — Settings Screen
- Class: quality-attribute
- Status: active
- Description: Sound effects on/off, music on/off, theme selection (dark/light/system), color palette selection for balls.
- Why it matters: Player control over experience. Accessibility (theme). Personalization (palette).
- Source: user
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: Settings persist across sessions

### R013 — Game Over Screen
- Class: primary-user-loop
- Status: active
- Description: Shows score summary (final score, highest combo, rounds survived). Replay button, home button. Future slot for rewarded ad.
- Why it matters: Closure on the session + easy path to retry.
- Source: user
- Primary owning slice: M001/S04
- Supporting slices: none
- Validation: unmapped
- Notes: Summary should be informative but not overwhelming

### R014 — Persistent High Score
- Class: continuity
- Status: active
- Description: High score stored on device (UserDefaults). Double-confirm reset option in settings.
- Why it matters: Progress persistence. Players want to beat their record.
- Source: user
- Primary owning slice: M001/S04
- Supporting slices: M001/S03
- Validation: unmapped
- Notes: Double confirmation prevents accidental reset

### R015 — Sound Effects
- Class: quality-attribute
- Status: active
- Description: Cartoon-style tap sound on ball touch. Bomb/explosion sound on wrong tap or timeout.
- Why it matters: Audio feedback reinforces the visual feedback loop. Makes the game feel alive.
- Source: user
- Primary owning slice: M001/S05
- Supporting slices: none
- Validation: unmapped
- Notes: Sounds should be fun, not annoying. Generic/royalty-free.

### R016 — Background Music
- Class: quality-attribute
- Status: active
- Description: 10 royalty-free fun/energetic music loops. Plays randomly during gameplay. Toggleable in settings AND via small in-game icon.
- Why it matters: Sets mood and energy. Optional — some players prefer silence.
- Source: user
- Primary owning slice: M001/S05
- Supporting slices: none
- Validation: unmapped
- Notes: Must not be annoying on repeat. Variety via 10 tracks.

### R017 — Pause System
- Class: core-capability
- Status: active
- Description: 3 pause attempts per game session. Pause button visible on game screen. Game freezes timer and hides balls on pause.
- Why it matters: Real life interrupts. Limited pauses prevent abuse.
- Source: user
- Primary owning slice: M001/S02
- Supporting slices: none
- Validation: unmapped
- Notes: 3 pauses total per game, not per round

### R018 — Dark/Light/System Theme
- Class: quality-attribute
- Status: active
- Description: App supports dark mode, light mode, and system-follow. Affects menus, settings, game background.
- Why it matters: User preference and accessibility.
- Source: user
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: none

### R019 — Color Palette Selection
- Class: differentiator
- Status: active
- Description: Multiple ball color palettes selectable in settings. Default is metallic/glossy. Alternatives TBD during implementation.
- Why it matters: Personalization. Different palettes also affect difficulty perception.
- Source: inferred
- Primary owning slice: M001/S03
- Supporting slices: none
- Validation: unmapped
- Notes: Palette affects ball rendering only, not UI chrome

### R020 — AI Asset Generation
- Class: differentiator
- Status: active
- Description: Game logo, app icon, menu backgrounds, and UI visual elements generated using Gemini API at build time. Logo gets special attention — multiple variations, careful prompt engineering, best one selected.
- Why it matters: Unique, high-quality visuals without manual design. Logo is the game's identity.
- Source: user
- Primary owning slice: M001/S06
- Supporting slices: M001/S03, M001/S07
- Validation: unmapped
- Notes: Build-time only. No runtime API calls. Game works offline.

### R021 — ASO & App Store Readiness
- Class: launchability
- Status: active
- Description: Complete App Store listing — optimized title, subtitle, description, keywords, screenshots, app preview metadata. ASO best practices applied.
- Why it matters: Discoverability. A great game nobody finds is a failed game.
- Source: user
- Primary owning slice: M001/S07
- Supporting slices: none
- Validation: unmapped
- Notes: "Mükemmel şekilde hazırla" — no shortcuts on ASO

## Deferred

### R022 — Rewarded Ad Integration
- Class: core-capability
- Status: deferred
- Description: Rewarded video ad on game over screen — watch ad for extra life or score bonus.
- Why it matters: Monetization path.
- Source: user
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: User said "daha sonra koyacağız." Game over screen leaves a slot for this.

### R023 — Game Center Leaderboard
- Class: quality-attribute
- Status: deferred
- Description: Global leaderboard via Game Center.
- Why it matters: Social competition drives retention.
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: unmapped
- Notes: Natural fit but not discussed. Defer until core game is solid.

## Out of Scope

### R024 — Multiplayer
- Class: anti-feature
- Status: out-of-scope
- Description: No multiplayer or real-time competitive mode.
- Why it matters: Prevents scope creep. 2TAP is a solo reflex game.
- Source: inferred
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Could be revisited in future milestones

### R025 — Level/Chapter System
- Class: anti-feature
- Status: out-of-scope
- Description: No discrete levels or chapters. The game is endless rounds.
- Why it matters: User explicitly rejected level-based structure. Endless mode is the design.
- Source: user
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: Difficulty progression serves the role levels would

### R026 — Cross-Platform
- Class: constraint
- Status: out-of-scope
- Description: iOS only. No Android, no web.
- Why it matters: Focus. SwiftUI + SpriteKit is iOS-native.
- Source: user
- Primary owning slice: none
- Supporting slices: none
- Validation: n/a
- Notes: none

## Traceability

| ID | Class | Status | Primary owner | Supporting | Proof |
|---|---|---|---|---|---|
| R001 | primary-user-loop | active | M001/S01 | M001/S02 | unmapped |
| R002 | core-capability | active | M001/S01 | none | unmapped |
| R003 | core-capability | active | M001/S01 | none | unmapped |
| R004 | differentiator | active | M001/S02 | none | unmapped |
| R005 | primary-user-loop | active | M001/S02 | M001/S04 | unmapped |
| R006 | core-capability | active | M001/S02 | none | unmapped |
| R007 | core-capability | active | M001/S02 | none | unmapped |
| R008 | quality-attribute | active | M001/S01 | none | unmapped |
| R009 | core-capability | active | M001/S01 | none | unmapped |
| R010 | quality-attribute | active | M001/S02 | none | unmapped |
| R011 | launchability | active | M001/S03 | M001/S06 | unmapped |
| R012 | quality-attribute | active | M001/S03 | none | unmapped |
| R013 | primary-user-loop | active | M001/S04 | none | unmapped |
| R014 | continuity | active | M001/S04 | M001/S03 | unmapped |
| R015 | quality-attribute | active | M001/S05 | none | unmapped |
| R016 | quality-attribute | active | M001/S05 | none | unmapped |
| R017 | core-capability | active | M001/S02 | none | unmapped |
| R018 | quality-attribute | active | M001/S03 | none | unmapped |
| R019 | differentiator | active | M001/S03 | none | unmapped |
| R020 | differentiator | active | M001/S06 | M001/S03, M001/S07 | unmapped |
| R021 | launchability | active | M001/S07 | none | unmapped |
| R022 | core-capability | deferred | none | none | unmapped |
| R023 | quality-attribute | deferred | none | none | unmapped |
| R024 | anti-feature | out-of-scope | none | none | n/a |
| R025 | anti-feature | out-of-scope | none | none | n/a |
| R026 | constraint | out-of-scope | none | none | n/a |

## Coverage Summary

- Active requirements: 21
- Mapped to slices: 21
- Validated: 0
- Unmapped active requirements: 0
