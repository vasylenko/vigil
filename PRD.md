# Vigil — PRD

## Overview
**Vigil** is a lightweight macOS menu bar application that prevents the system from sleeping. Dead simple but effective.

**Motivation**: Learning project + desire for a lightweight alternative to Amphetamine and similar tools. No bloat, no subscriptions, no unnecessary features.

> For technical architecture, see [ARCHITECTURE.md](ARCHITECTURE.md).

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
- [ ] Notification when timer expires

### v1.0 — Polish and Distribution
- [ ] Homebrew Cask formula
- [ ] Mac App Store submission (sandbox-compatible)
- [ ] Notarized DMG for direct download

## Resolved Decisions
1. **Icon design**: Custom character artwork — full opacity when active, dimmed when inactive (menu bar + popover hero)
2. **Sleep modes**: Two presets — "Display & System" and "System Only" — one active at a time
3. **Notifications (MVP)**: None — icon state change is sufficient for user-initiated toggles. Notifications reserved for timer expiry (v0.3)
4. **Quit while active**: No confirmation dialog — just quit and release
5. **Error UX (MVP)**: Silent failure — if sleep prevention can't activate, the toggle stays off. Acceptable because the underlying API virtually never fails in practice
