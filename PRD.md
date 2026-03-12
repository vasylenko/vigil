# Vigil — PRD

## Overview
**Vigil** is a lightweight macOS menu bar application that prevents the system from sleeping. It uses Apple's `IOPMAssertion` API to manage power assertions with a clean, native UI — dead simple but effective.

**Motivation**: Learning project + desire for a lightweight alternative to Amphetamine and similar tools. No bloat, no subscriptions, no unnecessary features.

> For technical architecture, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Target Users
- macOS power users who want a simple, reliable way to keep their Mac awake
- Developers, presenters, anyone running long processes who needs to prevent sleep temporarily

## Tech Stack
- **Language**: Swift 6
- **UI**: SwiftUI (`MenuBarExtra` with `.window` style)
- **IDE**: Xcode 26
- **Deployment target**: macOS 15.6 (Sequoia)
- **Architecture**: Apple Silicon + Intel (universal binary)
- **Dependencies**: None

## User Experience

### Menu Bar Icon
- **Active**: Custom character icon at full opacity
- **Inactive**: Same icon, dimmed (40% opacity)
- Menu bar only — no Dock icon

### Interaction Flow
1. User clicks the menu bar icon (custom character artwork)
2. A popover appears with:
   - Hero section: character icon + on/off toggle + status text
   - Mode picker: "Display & System" / "System Only"
   - Settings: Launch at Login, Remember Last State
   - Quit button
3. Toggling ON activates sleep prevention based on the selected mode
4. Toggling OFF deactivates sleep prevention
5. The menu bar icon dims/brightens as state feedback — no notifications needed since the user toggled explicitly

### Launch at Login
- A toggle in the dropdown to enable/disable launch at login
- Default: **OFF** on first install
- Uses macOS system API for login item registration

### State Persistence
- On launch, sleep prevention is **OFF by default**
- A "Remember last state" toggle in the popover (persisted across launches)
- When enabled, if the app was active at quit, it re-activates the assertion on next launch

## Technical Design

Uses the native macOS power assertion API — sandbox-compatible, programmatic control, and tied to the app's lifecycle with no child process management needed.

Two sleep prevention modes:
- **Display & System** — screen and system stay awake (presentations, reading)
- **System Only** — screen may sleep, system stays running (downloads, builds)

For implementation details, assertion types, and technical decision rationale, see [ARCHITECTURE.md](ARCHITECTURE.md).

### Notifications
- **MVP**: No notifications — menu bar icon state change is sufficient feedback for user-initiated toggles
- **Future (v0.3 Timer)**: System notification when a timer expires (this is a system-initiated event the user may not be watching for)

## Distribution

### MVP
- Local build from Xcode, run directly

### Future
- **Homebrew Cask**: distribute via tap
- **Direct download**: notarized DMG from GitHub Releases
- **Mac App Store**: Power assertion API is sandbox-compatible, MAS distribution is feasible

## Scope

### MVP (v0.1)
- [x] Menu bar icon with active/inactive states
- [x] Dropdown popover with on/off toggle
- [x] Create/release power assertion (idle + display sleep prevention)
- [x] Launch at login toggle (default: OFF)
- [x] "Remember last state" toggle (persisted across launches)
- [x] Quit option
- [x] App icon

### v0.2 — Sleep Modes
- [x] Mode presets: "Display & System" / "System Only" (segmented picker)
- [x] Description text explaining each mode's behavior

### v0.3 — Timer
- [ ] Timer picker (preset durations + custom)
- [ ] Auto-deactivate after timer expires
- [ ] Countdown display in the popover
- [ ] Notification when timer expires

### v0.4 — Polish and Distribution
- [ ] Homebrew Cask formula
- [ ] Notarized DMG for direct download
- [ ] Mac App Store submission (sandbox-compatible)
- [ ] Keyboard shortcut to toggle

## Resolved Decisions
1. **Icon design**: Custom character artwork — full opacity when active, dimmed when inactive (menu bar + popover hero)
2. **App name**: Vigil (keeping vigil — staying awake to watch over something)
3. **Core engine**: Native macOS power assertion API — sandbox-compatible, no child process
4. **Sleep modes**: Two presets — "Display & System" and "System Only" — one active at a time
5. **Dock icon**: None — menu bar only
6. **Launch at Login default**: OFF
7. **State persistence**: OFF by default, with opt-in "Remember last state" toggle
8. **Notifications (MVP)**: None — icon state change is sufficient for user-initiated toggles. Notifications reserved for timer expiry (v0.3)
9. **Quit while active**: No confirmation dialog — just quit and release
10. **Error UX (MVP)**: Silent failure — if sleep prevention can't activate, the toggle stays off. Acceptable because the underlying API virtually never fails in practice
