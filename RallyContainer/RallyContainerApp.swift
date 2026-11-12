import SwiftUI

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
            relay.onStateChanged = { state in
                backgroundHost.extend(reason: "Rally score fan-out")
                advertiser.broadcast(state)
            }
            relay.onDisplayPrefs = { snapshot in
                displayPrefs.applyFromWatch(snapshot)
            }
            watchRelay = relay
        }
    }

    private func applyMode(_ newMode: CompanionRootView.Mode) {
        switch newMode {
        case .host:
            browser.disconnect()
            browser.stopBrowsing()
            authority.bootstrapHostIfNeeded()
            advertiser.start(authority: authority)
            backgroundHost.extend(reason: "Rally host session")
        case .join:
            advertiser.stop()
            backgroundHost.end()
            browser.startBrowsing()
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        guard mode == .host else { return }
        switch phase {
        case .active:
            if !advertiser.isAdvertising {
                advertiser.start(authority: authority)
            }
            backgroundHost.extend(reason: "Rally host foreground")
        case .inactive, .background:
            backgroundHost.extend(reason: "Rally host background")
            if !advertiser.isAdvertising {
                advertiser.start(authority: authority)
            }
        @unknown default:
            break
        }
    }
}
