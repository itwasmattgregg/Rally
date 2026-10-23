import SwiftUI

@main
struct RallyContainerApp: App {
    @State private var authority = PhoneSessionAuthority()
    @State private var advertiser = BoardAdvertiser()
    @State private var browser = BoardBrowser()
    @State private var watchRelay: PhoneWatchRelay?

    var body: some Scene {
        WindowGroup {
            CompanionRootView()
                .environment(authority)
                .environment(advertiser)
                .environment(browser)
                .task {
                    if watchRelay == nil {
                        let relay = PhoneWatchRelay(authority: authority)
                        relay.onStateChanged = { state in
                            advertiser.broadcast(state)
                        }
                        watchRelay = relay
                    }
                    authority.bootstrapHostIfNeeded()
                    advertiser.start(authority: authority)
                }
        }
    }
}
