import SwiftUI
import UIKit

@main
struct RallyContainerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var authority = PhoneSessionAuthority()
    @State private var advertiser = BoardAdvertiser()
    @State private var browser = BoardBrowser()
    @State private var displayPrefs = CompanionDisplayPreferences()
    @State private var watchRelay: PhoneWatchRelay?
    @State private var backgroundHost = CourtBackgroundHost()
    @State private var mode: CompanionRootView.Mode = {
        UIDevice.current.userInterfaceIdiom == .pad ? .join : .host
    }()

    var body: some Scene {
        WindowGroup {
            CompanionRootView(mode: $mode)
                .environment(authority)
                .environment(advertiser)
                .environment(browser)
                .environment(displayPrefs)
                .task { configureRelay() }
                .onChange(of: mode) { _, newMode in
                    applyMode(newMode)
                }
                .onAppear { applyMode(mode) }
                .onChange(of: scenePhase) { _, phase in
                    handleScenePhase(phase)
                }
        }
    }

    private func configureRelay() {
        if watchRelay == nil {
            let relay = PhoneWatchRelay(authority: authority)
            // WC delivery can wake a suspended phone; extend + reassert Host path.
            relay.onWatchWake = {
                backgroundHost.extend(reason: "Rally WC wake")
                if !advertiser.isAdvertising {
                    advertiser.start(authority: authority)
                }
            }
            relay.onStateChanged = { state in
                backgroundHost.extend(reason: "Rally score fan-out")
                advertiser.broadcast(state)
            }
            relay.onDisplayPrefs = { snapshot in
                backgroundHost.extend(reason: "Rally display prefs")
                displayPrefs.applyFromWatch(snapshot)
            }
            watchRelay = relay
        }
    }

    private func applyMode(_ newMode: CompanionRootView.Mode) {
        // iPad display stays lit; phone Host is allowed to lock on the floor.
        UIApplication.shared.isIdleTimerDisabled = (newMode == .join)

        switch newMode {
        case .host:
            browser.disconnect()
            browser.stopBrowsing()
            authority.bootstrapHostIfNeeded()
            advertiser.start(authority: authority)
            backgroundHost.start()
        case .join:
            advertiser.stop()
            backgroundHost.stop()
            browser.startBrowsing()
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if mode == .host {
                if !advertiser.isAdvertising {
                    advertiser.start(authority: authority)
                }
                backgroundHost.extend(reason: "Rally host foreground")
            }
            UIApplication.shared.isIdleTimerDisabled = (mode == .join)
        case .inactive, .background:
            guard mode == .host else { return }
            backgroundHost.extend(reason: "Rally host background")
            if !advertiser.isAdvertising {
                advertiser.start(authority: authority)
            }
        @unknown default:
            break
        }
    }
}
