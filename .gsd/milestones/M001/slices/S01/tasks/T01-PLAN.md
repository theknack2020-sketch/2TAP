# T01: Xcode Project Scaffold

**Slice:** S01
**Milestone:** M001

## Goal
Create a working Xcode project with XcodeGen — SwiftUI app with SpriteKit dependency, proper directory structure, and verified build on iOS simulator.

## Must-Haves

### Truths
- `xcodebuild -scheme TwoTapGame -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build` succeeds
- App launches on simulator showing a placeholder screen

### Artifacts
- `project.yml` — XcodeGen config targeting iOS 17+, SwiftUI lifecycle
- `TwoTapGame/App/TwoTapGameApp.swift` — @main app entry point
- `TwoTapGame/App/ContentView.swift` — placeholder root view
- `TwoTapGame/Resources/Assets.xcassets/` — asset catalog with AccentColor and AppIcon
- `TwoTapGame.xcodeproj` — generated Xcode project

### Key Links
- `TwoTapGameApp.swift` → `ContentView.swift` via WindowGroup body
- `project.yml` → generates `TwoTapGame.xcodeproj` via `xcodegen generate`

## Steps
1. Create directory structure: App, Game, Views, Models, Resources
2. Create project.yml for XcodeGen (iOS 17+, SwiftUI lifecycle, SpriteKit framework)
3. Create TwoTapGameApp.swift with @main entry point
4. Create ContentView.swift with placeholder text
5. Create Assets.xcassets with AccentColor and AppIcon stubs
6. Run xcodegen generate
7. Build with xcodebuild and verify success

## Context
- Using XcodeGen to avoid committing .xcodeproj internals
- iOS 17+ for @Observable, modern SwiftUI APIs
- SpriteKit linked as system framework (not SPM)
- Bundle ID: com.ufuk.twotapgame (or similar)
