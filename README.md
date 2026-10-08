# ScoreKeep

Watch-only scoreboard for two teams — big tap targets, mint vs ember, no iPhone app.

## What you get

- **Tap a score** → +1 (primary action) with spring pulse + haptic
- **Minus control** under each score → −1
- **Reset** centered at the top (with confirmation)
- **Pencil** → rename HOME / AWAY (short labels)
- **Digital Crown** → +/− the last team you touched
- **Always On Display** → dims glows / ink when luminance is reduced
- **Complication / Smart Stack widget** → glance `12–9` without opening the app

## Can it stay open during Apple Fitness?

**Not while Fitness owns the workout.** watchOS allows only one active `HKWorkoutSession`. If Workout / Fitness is tracking an activity, your app cannot also claim that session, and the system will keep bringing Fitness forward on wrist raise.

| Approach | Keeps scoreboard frontmost? | Works *with* Fitness? | Notes |
|---|---|---|---|
| Normal app | Only while you’re in it | Yes (you leave Fitness to score) | Dock + complication make this fast |
| `HKWorkoutSession` in *your* app | Yes, on wrist raise | **No** — conflicts with Fitness | Fine if *you* are the workout app |
| `WKExtendedRuntimeSession` (self-care / mindfulness) | Frontmost for a limited time | Ends when user leaves your app | Wrong category for scoring; App Review risk |
| Smart Stack / complication | Glanceable | **Yes** | Best coexistence path |

**Practical recommendation:** keep ScoreKeep in the **Dock**, add the **rectangular complication** or Smart Stack widget, and open it only when you need to bump a point.

## Open in Xcode (Mac required)

This environment can’t compile watchOS binaries. On a Mac:

### Option A — New project, drop sources in (simplest)

1. Xcode → **File → New → Project → watchOS → App**
2. Product Name: `ScoreKeep`
3. Choose **Watch App** (no companion iOS app)
4. Replace generated Swift with `WatchApp/*` + `Shared/*`
5. Optional: **File → New → Target → Widget Extension** (watchOS), use `WidgetExtension/ScoreWidget.swift` + `Shared/ScoreDefaults.swift`
6. If you added the widget: enable **App Groups** on Watch + Widget → `group.com.example.ScoreKeep` (update `ScoreDefaults.suiteName` to match). This stays on-watch only — it feeds the complication, not an iPhone.
7. Run on a Watch simulator or device

### Option B — XcodeGen

```bash
brew install xcodegen
cd ScoreKeep
xcodegen
open ScoreKeep.xcodeproj
```

Then set your Team / unique bundle IDs (and App Group if using the widget).

## Design notes

- Field: deep charcoal gradient, soft mint / ember side glows
- Type: SF Rounded Heavy — scores are the product
- Motion: score spring on +1, numeric content transitions, crown haptics

## Requirements

- Xcode 15+
- watchOS 10+
