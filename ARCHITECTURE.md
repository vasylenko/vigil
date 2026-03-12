# Vigil — Architecture

> Living document. Update when the system changes.
> For product requirements and roadmap, see [PRD.md](PRD.md).

## Overview

**Vigil** is a macOS menu bar utility that prevents idle sleep using Apple's IOPMAssertion API. It lives exclusively in the menu bar (no Dock icon) and provides two sleep prevention modes through a SwiftUI popover.

## System Context

```
                        ┌─────────────────────┐
                        │   macOS Menu Bar     │
                        │  ┌───────────────┐   │
  User clicks icon ───► │  │    Vigil      │   │
                        │  │  (menu bar    │   │
                        │  │   extra)      │   │
                        │  └───────┬───────┘   │
                        └──────────┼───────────┘
                                   │ popover
                        ┌──────────▼───────────┐
                        │    MenuBarView        │
                        │  ┌─────────────────┐  │
                        │  │ Hero: toggle     │  │
                        │  │ Mode: picker     │──┼──► SleepManager
                        │  │ Settings         │  │        │
                        │  │ Quit             │  │        │
                        │  └─────────────────┘  │        │
                        └───────────────────────┘        │
                                                         │
                     ┌───────────────────────────────────┘
                     │
         ┌───────────▼───────────┐      ┌──────────────────────┐
         │   IOKit (IOPMLib)     │      │   UserDefaults       │
         │                       │      │                      │
         │  IOPMAssertionCreate  │      │  rememberLastState   │
         │  IOPMAssertionRelease │      │  wasActiveAtQuit     │
         │                       │      │  sleepMode           │
         └───────────────────────┘      └──────────────────────┘
                     │
         ┌───────────▼───────────┐      ┌──────────────────────┐
         │   powerd (daemon)     │      │   SMAppService       │
         │                       │      │                      │
         │  Manages all power    │      │  Login item           │
         │  assertions system-   │      │  registration via    │
         │  wide                 │      │  ServiceManagement   │
         └───────────────────────┘      └──────────────────────┘
```

## File Structure

```
vigil/
├── CLAUDE.md                      ← AI quick-reference
├── ARCHITECTURE.md                ← This file
├── PRD.md                         ← Product requirements
├── app/                           ← macOS app
│   ├── Vigil.xcodeproj/           ← Xcode project
│   ├── Vigil/
│   │   ├── VigilApp.swift         ← App entry point, MenuBarExtra scene
│   │   ├── SleepManager.swift     ← Core engine: assertions, state, modes
│   │   ├── MenuBarView.swift      ← Popover UI: hero, mode picker, settings
│   │   └── Assets.xcassets/
│   │       ├── AppIcon.appiconset/    ← App icon (10 sizes, 16–1024px)
│   │       ├── MenuBarIcon.imageset/  ← Menu bar icon (18px @1x, 36px @2x)
│   │       └── AccentColor.colorset/  ← System accent color
│   ├── VigilTests/
│   │   └── VigilTests.swift       ← SleepManager unit tests
│   └── VigilUITests/
│       ├── VigilUITests.swift     ← UI test target (template)
│       └── VigilUITestsLaunchTests.swift
└── website/                       ← Static promo site (Vercel)
```

## Development

### Prerequisites
- **Xcode 26** (or later)
- **macOS 15.6+** (Sequoia) — both as build host and deployment target

### Build & Run
```bash
# CLI build
xcodebuild build -project app/Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'

# Or open in Xcode and Cmd+R
open app/Vigil.xcodeproj
```

### Run Tests
```bash
xcodebuild test -project app/Vigil.xcodeproj -scheme Vigil -destination 'platform=macOS'
```

The `VigilTests` target contains unit tests covering `SleepManager` (state persistence, mode switching, toggle, init restoration). Tests also run from Xcode via **Cmd+U**.

**AppLauncher pattern**: The app uses an `AppLauncher` entry point that detects test runs via `NSClassFromString("XCTestCase")` and substitutes a lightweight `TestApp` (empty `WindowGroup`) instead of the real `MenuBarExtra` scene. This prevents the menu bar app from installing itself and blocking the test runner.

**Test architecture**:
- **Framework**: Swift Testing (`@Test`, `@Suite`, `#expect`) — not XCTest
- **Serialization**: `@Suite(.serialized)` — assertions are process-global state, so tests must not run concurrently
- **DI**: `SleepManager` accepts `defaults: UserDefaults` parameter (defaults to `.standard`) — tests inject isolated `UserDefaults` suites via `UserDefaults(suiteName:)` to avoid cross-test contamination
- **Integration-style**: Tests create real IOPMAssertions and verify them via `findAssertions(forPid:)`, a helper that queries the kernel with `IOPMCopyAssertionsByProcess`

### Verify Sleep Prevention
```bash
# While app is running with toggle ON:
pmset -g assertions | grep Vigil
```

## Component Design

### AppLauncher / VigilApp (entry point)

```
@main AppLauncher
  │
  ├── XCTestCase detected? → TestApp (empty WindowGroup)
  │
  └── Production → VigilApp
        │
        ├── @State sleepManager: SleepManager    ← owns the model
        │
        └── Scene: MenuBarExtra(.window)
              ├── label: Image("MenuBarIcon")    ← custom icon, opacity = state
              └── content: MenuBarView           ← receives sleepManager
```

**Why AppLauncher**: MenuBarExtra apps install themselves in the menu bar and stay resident, which blocks the XCTest runner. `AppLauncher` checks for `XCTestCase` at launch and substitutes a lightweight `TestApp` during test runs.

**Why `@State` not `@StateObject`**: The project uses `@Observable` (Swift Observation framework), not `ObservableObject`/`@Published`. With `@Observable`, `@State` is the correct ownership wrapper — it preserves the instance across scene body re-evaluations.

**Why `.window` not `.menu`**: The `.window` style enables rich SwiftUI views (toggles, pickers, custom layouts). The `.menu` style only supports basic `Button` items.

### SleepManager (core engine)

```
SleepManager (@Observable)
  │
  ├── Properties
  │   ├── isActive: Bool                  ← current assertion state
  │   ├── sleepMode: SleepMode            ← which assertion type to use
  │   ├── rememberLastState: Bool         ← persist state across launches
  │   └── assertionID: IOPMAssertionID    ← handle for active assertion
  │
  ├── Lifecycle
  │   ├── init()                          ← restore persisted state + register willTerminate observer
  │   ├── toggle()                        ← primary UI entry point (activate or deactivate)
  │   ├── activate()                      ← create assertion
  │   ├── deactivate()                    ← release assertion
  │   └── saveState()                     ← persist before quit (called by Quit button + willTerminate)
  │
  └── Mode switching (while active)
      │
      sleepMode.didSet
        ├── deactivate()    ← release old assertion
        └── activate()      ← create new assertion with new type
```

**Assertion lifecycle**:
```
  activate()                              deactivate()
      │                                       │
      ▼                                       ▼
  IOPMAssertionCreateWithName(            IOPMAssertionRelease(
    sleepMode.assertionType,                assertionID
    kIOPMAssertionLevelOn,              )
    reason                              isActive = false
  )                                     assertionID = 0
  if success → isActive = true
```

**State persistence flow**:
```
  App launch
      │
      ├── Read rememberLastState from UserDefaults
      ├── Read sleepMode from UserDefaults
      │
      └── if rememberLastState AND wasActiveAtQuit
              │
              └── activate()    ← auto-resume
```

### SleepMode (assertion types)

```
  SleepMode
  │
  ├── .displayAndSystem
  │     assertion: kIOPMAssertPreventUserIdleDisplaySleep
  │     behavior:  screen ON + system ON
  │     use case:  presentations, reading, demos
  │
  └── .systemOnly
        assertion: kIOPMAssertPreventUserIdleSystemSleep
        behavior:  screen may sleep, system ON
        use case:  downloads, builds, backups
```

**Why only two modes**: IOKit provides more assertion types (`PreventDiskIdle`, `PreventSystemSleep`), but:
- `PreventDiskIdle` is irrelevant with SSDs (all modern Macs)
- `PreventSystemSleep` blocks lid-close sleep — too aggressive for most users
- Two modes cover the real-world use cases without exposing IOKit jargon

**Why PreventUserIdleDisplaySleep covers both**: Per Apple's IOPMLib.h, preventing display sleep implicitly prevents system idle sleep. One assertion handles both — no need for two separate ones.

### MenuBarView (UI)

```
  MenuBarView
  │
  ├── heroSection
  │   ├── Image("MenuBarIcon")         ← character icon, opacity = state
  │   ├── Toggle "Stay Awake"          ← calls sleepManager.toggle()
  │   └── Text (status)               ← mode description or "off"
  │
  ├── modeSection
  │   ├── Picker(.segmented)           ← Display & System / System Only
  │   └── Text (mode description)
  │
  ├── settingsSection
  │   ├── Toggle "Launch at Login"     ← SMAppService.mainApp
  │   └── Toggle "Remember Last State" ← sleepManager.rememberLastState
  │
  └── footerSection
      └── Button "Quit Vigil"          ← saveState() + terminate
```

**Toggle binding pattern**: The Stay Awake toggle uses a custom `Binding` that calls `sleepManager.toggle()` on set (not a direct bool assignment). This routes all state changes through activate/deactivate, ensuring the IOPMAssertion is always in sync.

**Launch at Login**: Uses `@State private var launchAtLogin` synced from `SMAppService.mainApp.status` on `.onAppear`. Registration/unregistration uses `try?` — the system may deny silently, and we re-read status on next appear.

## Data Flow

```
  User taps toggle
       │
       ▼
  Binding.set calls sleepManager.toggle()
       │
       ├── isActive? → deactivate() → IOPMAssertionRelease
       │
       └── !isActive? → activate() → IOPMAssertionCreateWithName
                                            │
                                            ▼
                              isActive = true (if success)
                                            │
                    ┌───────────────────────┬┘
                    ▼                       ▼
            Menu bar icon              Hero icon
            opacity changes            opacity changes
            (VigilApp)                 (MenuBarView)
```

```
  User changes mode (while active)
       │
       ▼
  sleepMode.didSet
       │
       ├── UserDefaults.set(sleepMode)
       │
       ├── deactivate()
       │     └── IOPMAssertionRelease (old type)
       │
       └── activate()
             └── IOPMAssertionCreateWithName (new type)
```

```
  User quits app
       │
       ▼
  Quit button action
       │
       ├── sleepManager.saveState()
       │     └── if rememberLastState → write isActive to UserDefaults
       │
       └── NSApplication.shared.terminate(nil)
             └── OS releases any remaining IOPMAssertions automatically
```

## Key Technical Constraints

| Constraint | Detail |
|-----------|--------|
| **Sandbox** | Enabled. IOPMAssertion is sandbox-compatible. No entitlement needed. |
| **LSUIElement** | `YES` in Info.plist. No Dock icon, no Cmd+Tab entry. |
| **MainActor isolation** | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. All types are MainActor-isolated by default. IOPMAssertion C functions are safe to call from MainActor. |
| **File sync** | `PBXFileSystemSynchronizedRootGroup` — new `.swift` files in `app/Vigil/` auto-included in build. No need to edit `project.pbxproj`. |
| **Deployment target** | macOS 15.6 (Sequoia). All APIs available since macOS 13-14. |
| **Bundle ID** | `serhiivasylenko.vigil` |

## Assertion Behavior Matrix

| Scenario | Idle sleep | Display sleep | Lid close | Manual sleep | Critical battery |
|----------|-----------|---------------|-----------|-------------|-----------------|
| **Display & System mode ON** | Blocked | Blocked | Sleeps | Sleeps | Sleeps |
| **System Only mode ON** | Blocked | Allowed | Sleeps | Sleeps | Sleeps |
| **Both modes OFF** | Normal | Normal | Sleeps | Sleeps | Sleeps |

Assertions are *requests* — macOS overrides them for lid close, manual sleep (Apple menu), and critical battery. This is correct behavior.

## UserDefaults Keys

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `rememberLastState` | Bool | `false` | Whether to restore state on launch |
| `wasActiveAtQuit` | Bool | `false` | Whether assertion was active at last quit (removed when `rememberLastState` is off) |
| `sleepMode` | String | `displayAndSystem` | Selected sleep prevention mode |

## Verification

```bash
# Check if assertion is active and which type:
pmset -g assertions | grep Vigil

# Expected output when Display & System is ON:
# pid XXXXX(Vigil): PreventUserIdleDisplaySleep named: "Vigil is keeping your Mac and display awake"

# Expected output when System Only is ON:
# pid XXXXX(Vigil): PreventUserIdleSystemSleep named: "Vigil is keeping your Mac awake (display may sleep)"

# No output = no active assertion (correct when toggled off or quit)
```

## Error Handling

| Failure | What happens | User sees |
|---------|-------------|-----------|
| `IOPMAssertionCreate` returns non-success | `isActive` stays `false`, toggle appears off | Toggle doesn't turn on — no assertion created. Silent failure. |
| `IOPMAssertionRelease` on invalid ID | No-op (guarded by `isActive` check) | Nothing — deactivate only runs when active. |
| `SMAppService.register()` throws | `try?` swallows error | Toggle may flip but system didn't register. On next `.onAppear`, toggle re-syncs with actual system state. |
| `UserDefaults` key missing | Returns `false` (Bool) or `nil` (String) | App starts with defaults: inactive, Display & System mode, remember state off. |
| App crash while assertion active | OS automatically releases all assertions held by terminated process | System resumes normal sleep behavior. No leaked assertions. |

**Current trade-off**: Silent failures. The app doesn't surface IOPMAssertion errors to the user. This is acceptable because assertion creation virtually never fails in practice (the API is a simple kernel message). If this changes, add an alert or status indicator.

## Extending the System

### Adding a new SleepMode

1. Add a case to `SleepMode` enum in `SleepManager.swift`
2. Implement all computed properties: `assertionType`, `assertionReason`, `label`, `description`
3. The segmented picker in `MenuBarView` auto-populates from `SleepMode.allCases` — no UI change needed
4. Existing UserDefaults persistence works automatically (uses `rawValue`)
5. Update the Assertion Behavior Matrix in this doc
6. Update `PRD.md` Scope and Resolved Decisions if the new mode changes product behavior

### Adding a new UserDefaults key

1. Add the key usage in `SleepManager.swift`
2. Update the UserDefaults Keys table in this doc
3. Consider: does the key need to be cleared on reset? Add to `saveState()` if relevant.

### Adding a new UI section

1. Create a computed property (`private var newSection: some View`) in `MenuBarView.swift`
2. Add it to the `body` VStack — maintain the pattern of `Divider().padding(.horizontal)` between sections
3. Update the MenuBarView component diagram in this doc

### Updating documents

When making changes, update these docs to stay in sync:
- **ARCHITECTURE.md** — file structure, component diagrams, data flows, decision log, behavior matrix, UserDefaults table
- **PRD.md** — scope checklist, interaction flow, resolved decisions

## Decision Log

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | IOPMAssertion over `caffeinate` | Sandbox-compatible, no process management, programmatic control. `caffeinate` is a child process to babysit. |
| 2 | `@Observable` over `ObservableObject` | Modern Swift Observation framework. Less boilerplate, better performance (fine-grained tracking). |
| 3 | Two mode presets over individual assertion toggles | Users think in terms of use cases (presentations vs downloads), not IOKit assertion types. |
| 4 | `MenuBarExtra(.window)` over `.menu` | Rich SwiftUI views (toggles, pickers, backgrounds). `.menu` only supports basic button items. |
| 5 | Single assertion per mode | `PreventUserIdleDisplaySleep` already implies system idle sleep prevention. No need for two assertions. |
| 6 | `try?` for SMAppService | System may deny login item registration silently. Graceful degradation — toggle reflects actual system state on next appear. |
| 7 | `.fixedSize()` on root view | Prevents MenuBarExtra NSPanel from showing resize cursor. The popover should be fixed-size. |

## Roadmap

See [PRD.md](PRD.md) — Scope section (v0.3 Timer, v0.4 Distribution).
