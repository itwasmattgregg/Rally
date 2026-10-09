import SwiftUI

@main
struct RallyApp: App {
    @State private var board = ScoreBoard()

    var body: some Scene {
        WindowGroup {
            ScoreboardView()
                .environment(board)
        }
    }
}
