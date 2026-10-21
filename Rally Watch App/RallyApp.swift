import SwiftUI

@main
struct RallyApp: App {
    @State private var board = ScoreBoard()
    @State private var match = MatchSession()

    var body: some Scene {
        WindowGroup {
            MatchPager()
                .environment(board)
                .environment(match)
        }
    }
}

/// Scoreboard on the first page. Swipe up for the volleyball workout.
private struct MatchPager: View {
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            ScoreboardView(crownEnabled: page == 0)
                .tag(0)
            MatchSessionView()
                .tag(1)
        }
        .tabViewStyle(.verticalPage)
    }
}
