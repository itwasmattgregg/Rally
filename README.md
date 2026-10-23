# Rally

Watch scorekeeper for two unbounded scores (mint / ember), with an optional offline iPhone/iPad companion for court displays.

**Watch stays independent** — install and score with no iOS app. Install the iPhone/iPad companion too when you want linked court displays (phone hosts/relays; iPads join over local Bonjour).

## Architecture (v1 multi-display)

Watch → WatchConnectivity → iPhone (authority + Bonjour relay) → Network.framework → iPad display(s).

- Phone/iPad UI is **display-only** (no scoring controls).
- No internet / cloud on court.
- Background on Watch via **HKWorkout** session.

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
3. +/- / undo on the board; swipe up for workout start/stop (keeps scoring available in background)

Simulator tip: run **Rally** and **Rally Watch App** as separate schemes. Watch is embedded into the iOS app on **device** archives (`iphoneos`); simulators use the Watch scheme directly so packaging stays independent.

### Optional XcodeGen

```bash
brew install xcodegen
xcodegen   # regenerates from project.yml; checked-in .xcodeproj is source of truth day-to-day
```

## Design notes

- Field: deep charcoal gradient, soft mint / ember side glows
- Type: SF Rounded Heavy — scores are the product
- Motion: score spring on +1, numeric content transitions, crown haptics

## Requirements

- Xcode 15+ (developed with Xcode 26)
- watchOS 10+ / iOS 18+
