# Rally

Watch scorekeeper for two unbounded scores (mint / ember), with an optional offline iPhone/iPad companion for court displays.

**Watch stays independent** — install and score with no iOS app. Install the iPhone/iPad companion too when you want linked court displays (phone hosts/relays; iPads join over local Bonjour).

## Architecture (v1 multi-display)

Watch → WatchConnectivity → iPhone (authority + Bonjour relay) → Network.framework → iPad display(s).

- Phone/iPad UI is **display-only** (no scoring controls).
- No internet / cloud on court.
- Background on Watch via **HKWorkout** session.
- Phone Host uses a short background task so score fan-out can continue briefly after the screen locks.

## Court display setup (Bonjour)

Bonjour is the local discovery layer — no accounts, no Wi‑Fi password sharing UI, no QR required (QR is optional). Phone **advertises** a board; iPad **browses** and joins by matching a 4-character code.

### One-time device prep

1. Install **Rally** on the phone and on each iPad (same build).
2. Turn **Wi‑Fi** on for both devices (same network is ideal). Leave **Bluetooth** on — Apple uses it for peer-to-peer when Wi‑Fi alone is flaky.
3. Open Rally once on each device and tap **Allow** when iOS asks for **Local Network** access.
   - If you missed that prompt: Settings → Rally → Local Network → On.

### On court (every match)

1. **Phone → Host** (default on iPhone). You should see a big 4-letter code (e.g. `K7MP`) and “Broadcasting”.
2. **iPad → Join** (default on iPad). Type that same code and tap **Join**, or tap the matching row under **Nearby**.
3. When status shows **Connected / Live**, scores from the Watch appear on the iPad.
4. Score on the Watch as usual. Keep the Rally app open (or recently used) on the phone — it relays Watch → iPad. The phone may lock; leave Rally in Host mode so background hosting can keep the relay alive briefly.

### What the code is

- Generated once on the phone and **persisted** (same code across launches until you rotate it in-app).
- Published as Bonjour service name `Rally-XXXX` under type `_rallyboard._tcp`.
- Nearby lists only boards whose name/TXT resolve to a real 4-letter code — prefer typing the phone’s on-screen code if Nearby looks stale.

### Troubleshooting

| Symptom | Fix |
| --- | --- |
| No Local Network prompt / empty Nearby | Settings → Rally → Local Network On; force-quit and reopen Rally on both devices |
| Wrong code under Nearby | Ignore Nearby; type the code shown on the phone Host screen |
| Join stuck on “Waiting…” | Confirm phone shows Host + Broadcasting; same Wi‑Fi/BT; Local Network allowed |
| iPad connected, scores freeze after phone lock | Bring phone to foreground once, keep Rally Host open; Watch still scores alone |

## Open in Xcode

```bash
open Rally.xcodeproj
```

### Run companion (iPhone / iPad)

1. Scheme: **Rally**
2. Destination: iPhone or iPad simulator/device
3. Run — Host mode (default on phone) shows scores + session code/QR and advertises `_rallyboard._tcp`
4. On iPad (or switch the segmented control to **Join**): enter the 4-character code or pick a nearby board

### Run Watch scorekeeper

1. Scheme: **Rally Watch App**
2. Destination: Watch simulator/device
3. +/- on the board; swipe up for workout start/stop (keeps scoring available in background)

Simulator tip: run **Rally** and **Rally Watch App** as separate schemes. Watch is embedded into the iOS app on **device** archives (`iphoneos`); simulators use the Watch scheme directly so packaging stays independent. Bonjour discovery is unreliable between simulators — use two physical devices to validate Host/Join.

### Optional XcodeGen

```bash
brew install xcodegen
xcodegen   # regenerates from project.yml; checked-in .xcodeproj is source of truth day-to-day
```

## Design notes

- Field: deep charcoal gradient; Watch keeps soft side washes, phone/iPad scores are flat (no numeral glow) for court readability
- Type: selectable score fonts (Rounded default, Standard, Serif, Mono) + shared color themes; Watch Options also toggles Digital Crown scoring (off by default)
- Motion: score spring on +1, numeric content transitions, optional crown haptics

## Requirements

- Xcode 15+ (developed with Xcode 26)
- watchOS 10+ / iOS 18+
