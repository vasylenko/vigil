# Vigil

## Purpose

macOS menu bar utility that prevents idle sleep using IOPMAssertions. Menu-bar-only app (no Dock icon) with two modes: "Display & System" and "System Only". Personal hobby project — lightweight alternative to Amphetamine.

For product roadmap, see [PRD.md](PRD.md).
For architecture and decision rationale, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Tech Stack

- **Language**: Swift 6 (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- **UI**: SwiftUI (`MenuBarExtra` with `.window` style)
- **Frameworks**: IOKit.pwr_mgt (power assertions), ServiceManagement (login items), Foundation (UserDefaults)
- **Target**: macOS 15.6 (Sequoia), Apple Silicon + Intel
- **Dependencies**: None. Zero third-party packages.
- **Build**: `xcodebuild build -project app/Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'`
- **Test**: `xcodebuild test -project app/Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'`

## Project Structure

```
vigil/
├── CLAUDE.md              # AI quick-reference
├── ARCHITECTURE.md        # System design and decision log
├── PRD.md                 # Product requirements
├── app/                   # macOS app (Xcode project)
│   ├── Vigil.xcodeproj/
│   ├── Vigil/             # Source: VigilApp.swift, SleepManager.swift, MenuBarView.swift
│   └── VigilTests/
└── website/               # Static promo site (Vercel)
```

New `.swift` files in `app/Vigil/` are auto-included in the build (PBXFileSystemSynchronizedRootGroup) — no need to edit `project.pbxproj`.

## Code Style & Conventions

- `@Observable` class + `@State` ownership (NOT `ObservableObject`/`@StateObject`/`@Published`)
- All types are MainActor-isolated by default (build setting) — no need for explicit `@MainActor`
- Custom `Binding` wrappers to route toggle changes through methods (e.g., `sleepManager.toggle()`)
- `didSet` observers for UserDefaults persistence
- `// MARK: -` comments for view section organization
- `import IOKit.pwr_mgt` (submodule import, not `import IOKit`)
- Computed properties for view decomposition (`heroSection`, `modeSection`, etc.)

## Testing

- **Framework**: Swift Testing (`@Test`, `@Suite`, `#expect`) — NOT XCTest
- **`@MainActor` required**: Test targets do NOT have `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — add `@MainActor` explicitly on test suites
- **`@Suite(.serialized)` required**: IOPMAssertions are process-global state — concurrent tests interfere with each other
- **DI**: `SleepManager` accepts `defaults: UserDefaults = .standard` — tests inject isolated suites via `UserDefaults(suiteName:)` to avoid cross-test contamination
- **Integration-style**: Tests create real IOPMAssertions and verify via `findAssertions(forPid:)`, a helper that queries the kernel with `IOPMCopyAssertionsByProcess`
- **Entry point**: `AppLauncher` (the actual `@main`) detects test runs via `NSClassFromString("XCTestCase")` and substitutes a lightweight `TestApp`. Do not add `@main` to `VigilApp` directly.

## Quirks

- **LSUIElement = YES**: No Dock icon, no Cmd+Tab. The app only appears in the menu bar and Activity Monitor.
- **Sandbox enabled**: IOPMAssertion is sandbox-compatible — no special entitlements needed.
- **App icon vs menu bar icon**: Two separate assets. App icon (1024px character artwork) shows in Finder. Menu bar icon (18px) shows in the menu bar strip.
- **Assertion lifecycle**: The OS automatically releases all IOPMAssertions if the app crashes — no leaked assertions possible.
- **Verify it works**: `pmset -g assertions | grep Vigil` shows the active assertion type and reason string.
