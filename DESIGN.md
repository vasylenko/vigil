# Vigil Design System

## What This Document Is

Timeless design guidelines for Vigil's interface. Not code, not API references — principles for how the app should look, feel, and behave regardless of which macOS version or framework is current.

---

## Identity

Vigil is a **utility**. It exists to perform one task: prevent your Mac from sleeping. Everything in the interface serves that single purpose.

A utility earns trust by being:
- **Fast** — open, act, dismiss. Three seconds total.
- **Quiet** — it stays out of the way until needed.
- **Obvious** — no learning curve, no surprises.

Vigil's only personality is the lighthouse icon. That icon carries the entire brand. Everything around it is system-native — invisible scaffolding that lets the icon and the primary toggle speak.

---

## Principles

### 1. The Glance Test

A user opens the popover and looks for half a second. In that time, they must know:
- Is sleep prevention on or off?
- Which mode is active?

If any element competes with those two signals, it's too loud. Design every element by asking: *does this help or hurt the glance test?*

### 2. Earned Visual Weight

Every pixel of visual weight must be earned. The hierarchy:

| Weight | Element | Why it earns weight |
|--------|---------|-------------------|
| Heaviest | Lighthouse icon | Brand identity — the one thing that's "Vigil" |
| Heavy | Primary toggle | The reason the app exists |
| Medium | Mode selector | Modifies how the primary action works |
| Light | Settings rows | Used once, then forgotten |
| Lightest | Quit | Available, not encouraged |

Nothing outside this hierarchy gets visual weight. No decorative elements. No borders for structure's sake. No backgrounds unless they communicate state.

### 3. One Personality Element

The lighthouse icon is Vigil's single personality element. It's distinctive and recognizable. **Everything else is invisible.** System fonts, system controls, system colors. The moment a second element competes for personality — a custom toggle, a branded color, a non-standard font — the interface becomes noisy and the icon loses its power.

### 4. State as Reward

When the user activates sleep prevention, the interface should feel like it *responded*. The icon brightens, the hero section gains a subtle warmth. This is a reward — a gentle acknowledgment that says "I'm working."

When inactive, the interface should feel calm and receded. Not broken, not empty — just resting.

The transition between states should feel physical, like something real changed. Not instant (feels like a glitch), not slow (feels laggy). A quarter-second spring.

### 5. Respect the Platform

macOS users have deep muscle memory. They know what toggles look like, how segmented controls work, where "Quit" goes. Every deviation from platform convention costs the user cognitive effort. A custom control might look clever, but it makes the user *think* — and thinking is the enemy of a utility.

Use the system's controls exactly as they are. They handle dark mode, accessibility, and future OS design changes automatically. Fighting the platform is a maintenance burden that compounds over time.

---

## Visual Language

### Spacing

All spacing derives from a 4pt base unit. This creates rhythm — the eye recognizes the pattern subconsciously, and the interface feels "right" even if the user can't articulate why.

- **Tight** (4pt): Between elements that belong together (label and its description).
- **Standard** (8pt): Between related but distinct elements (icon and toggle row).
- **Comfortable** (12pt): Content inset from edges. Breathing room between sections.
- **Generous** (16pt): Inside the hero section. Gives the primary action room to breathe.

**The test**: If you can't justify a spacing value from this scale, the layout has a structural problem.

### Typography

Two rules:

1. **Maximum two font weights visible at once.** Regular for everything, bold for the single most important label ("Stay Awake"). More than two weights creates noise in a small surface.

2. **Size communicates hierarchy, not importance.** The app name is small because it's identity, not action. The toggle label is the same size as body text but bold — emphasis without shouting.

Use the system's semantic type styles. They're designed to create clear hierarchy at macOS viewing distances. They adapt to user accessibility settings. They'll look right in the next OS version too.

### Color

**The user's accent color is the only color.** No brand colors, no custom palette, no hardcoded values. The accent color appears only in active state — the hero background tint and the toggle's "on" state. Everything else is primary text, secondary text, or clear.

This means Vigil looks different on every Mac, and that's the point. It feels native because it *is* native. It matches the user's system, not a designer's mockup.

**Semantic colors only.** Primary text. Secondary text. System accent. System separators. These adapt to dark mode, high contrast, reduced transparency, and future OS materials automatically. Hardcoded colors are tech debt.

### Depth and Surfaces

The popover is a single-layer surface. No cards inside cards. No shadows within the popover. No elevated or recessed elements. The only depth cue is the hero section's conditional background fill — and that communicates state, not structure.

The popover itself already floats above the desktop with a system-managed shadow and material. Adding internal depth fights the container's own visual language.

### Dividers

Inset, not full-bleed. A full-bleed divider makes the popover feel like a cage — sections become cells. An inset divider (padded from left and right edges) feels like a gentle pause between ideas.

---

## Interaction Feel

### Immediacy

Every control must respond instantly. The toggle changes state on tap, not on release. The mode selector switches without delay. The quit button acts immediately — no confirmation dialog. A utility that hesitates feels broken.

### Reversibility

The primary action (sleep prevention) is freely reversible. Toggle on, toggle off. No consequences, no warnings, no "are you sure?" A user should feel safe to experiment. The lower the stakes of interacting, the more the user trusts the app.

### Animation

- **State transitions** (on/off) use a short spring animation — physical, not decorative. Something real changed.
- **The toggle itself** uses the system's built-in animation. Don't override it.
- **Text changes** are instant. Animating text content looks jittery and distracting.
- **Only animate properties that communicate state.** Icon opacity and hero background are state signals. Nothing else needs motion.

### Dismissal

The popover dismisses when the user clicks outside it. This is system behavior — don't override it, don't add a close button. Menu bar popovers are transient by nature. The user summons them, acts, and moves on.

---

## Information Density

macOS users expect higher information density than iOS users. They have a mouse for precise targeting. They sit closer to the screen. They're comfortable with smaller text and tighter spacing.

But a menu bar popover is not a window. The surface is small (~280pt wide) and transient. Density should be high enough that everything fits without scrolling, but not so high that the glance test fails.

**The rule**: Every element must be readable at arm's length without squinting. If you need to pack more in, the feature list is too long — cut features, don't shrink text.

---

## What Good Looks Like

A well-designed Vigil popover should:
- Feel like it shipped with the OS
- Be scannable in under a second
- Require zero documentation
- Look right on someone else's Mac with different accent color and appearance settings
- Still look right in next year's macOS without code changes

A poorly-designed Vigil popover:
- Has its own visual identity competing with macOS
- Makes the user read to understand state
- Uses custom controls that break in accessibility modes
- Looks good on the developer's machine, weird on everyone else's
- Breaks when the OS updates its design language
