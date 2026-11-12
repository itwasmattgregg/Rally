import SwiftUI

@main
struct RallyApp: App {
    @State private var board = ScoreBoard()
    @State private var match = MatchSession()
    @State private var displayPrefs = WatchDisplayPreferences()

    var body: some Scene {
        WindowGroup {
            MatchPager()
                .environment(board)
                .environment(match)
                .environment(displayPrefs)
                .task {
                    displayPrefs.bindPublisher { snapshot in
                        board.publishDisplayPrefs(snapshot)
                    }
                }
        }
    }
}

/// Scoreboard on the first page. Swipe up for the HealthKit workout.
private struct MatchPager: View {
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            ScoreboardView(pageFocused: page == 0)
                .tag(0)
            MatchSessionView()
                .tag(1)
        }
        .tabViewStyle(.verticalPage)
    }
}
