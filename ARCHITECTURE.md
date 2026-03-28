# Vigil — Architecture

> For product requirements and roadmap, see [PRD.md](PRD.md).

## System Context

```
  User clicks icon ───► Menu bar (MenuBarExtra .window)
                              │
                              ▼
                        MenuBarView ──► SleepManager
                                            │
                    ┌───────────────────────┬┘
                    ▼                       ▼
         IOKit (IOPMLib)            UserDefaults
         IOPMAssertionCreate        rememberLastState
         IOPMAssertionRelease       wasActiveAtQuit
                    │               sleepMode
                    ▼
         powerd (kernel daemon)     SMAppService
         system-wide assertions     login item registration
```

## Design Rationale

**Why IOPMAssertion over `caffeinate`**: Sandbox-compatible, no process management, programmatic control. `caffeinate` is a child process to babysit.

**Why `@Observable` over `ObservableObject`**: Modern Swift Observation framework. Less boilerplate, better performance (fine-grained tracking). With `@Observable`, `@State` is the correct ownership wrapper (not `@StateObject`).

**Why `MenuBarExtra(.window)` over `.menu`**: Rich SwiftUI views (toggles, pickers, custom layouts). `.menu` only supports basic `Button` items.

**Why only two modes**: IOKit provides more assertion types (`PreventDiskIdle`, `PreventSystemSleep`), but:
- `PreventDiskIdle` is irrelevant with SSDs (all modern Macs)
- `PreventSystemSleep` blocks lid-close sleep — too aggressive for most users
- Two modes cover the real-world use cases without exposing IOKit jargon

**Why `PreventUserIdleDisplaySleep` covers both**: Per Apple's IOPMLib.h, preventing display sleep implicitly prevents system idle sleep. One assertion handles both — no need for two separate ones.

**Toggle binding pattern**: The Stay Awake toggle uses a custom `Binding` that calls `sleepManager.toggle()` on set (not a direct bool assignment). This routes all state changes through activate/deactivate, ensuring the IOPMAssertion is always in sync.

**Launch at Login**: Uses `@State private var launchAtLogin` synced from `SMAppService.mainApp.status` on `.onAppear`. Registration/unregistration uses `try?` — the system may deny silently, and we re-read status on next appear.

**`.fixedSize()` on root view**: Prevents MenuBarExtra NSPanel from showing resize cursor. The popover should be fixed-size.

## Key Technical Constraints

| Constraint | Detail |
|-----------|--------|
| **Sandbox** | Enabled. IOPMAssertion is sandbox-compatible. No entitlement needed. |
| **LSUIElement** | `YES` in Info.plist. No Dock icon, no Cmd+Tab entry. |
| **MainActor isolation** | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target only). All app types are MainActor-isolated by default. |
| **File sync** | `PBXFileSystemSynchronizedRootGroup` — new `.swift` files in `app/Vigil/` auto-included in build. |
| **Deployment target** | macOS 15.6 (Sequoia). All APIs available since macOS 13-14. |
| **Bundle ID** | `serhiivasylenko.vigil` |
| **Privacy manifest** | `PrivacyInfo.xcprivacy` — declares `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` (app-specific read/write). Required for App Store upload. |
| **PRODUCT_NAME** | `Vigil` (no colons — Apple rejects `:` in bundle names, ITMS-90267). App Store display name "Vigil - Stay Awake" is managed separately in App Store Connect. |

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

## Error Handling

| Failure | What happens | User sees |
|---------|-------------|-----------|
| `IOPMAssertionCreate` returns non-success | `isActive` stays `false`, toggle appears off | Toggle doesn't turn on — silent failure. |
| `IOPMAssertionRelease` on invalid ID | No-op (guarded by `isActive` check) | Nothing. |
| `SMAppService.register()` throws | `try?` swallows error | Toggle re-syncs with actual system state on next `.onAppear`. |
| `UserDefaults` key missing | Returns `false` (Bool) or `nil` (String) | App starts with defaults: inactive, Display & System mode. |
| App crash while assertion active | OS releases all assertions held by terminated process | System resumes normal sleep behavior. No leaked assertions. |

**Current trade-off**: Silent failures. The app doesn't surface IOPMAssertion errors to the user. This is acceptable because assertion creation virtually never fails in practice (the API is a simple kernel message). If this changes, add an alert or status indicator.

When making changes, update these docs to stay in sync:
- **ARCHITECTURE.md** — design rationale, behavior matrix, UserDefaults table, constraints
- **PRD.md** — scope checklist, resolved decisions
