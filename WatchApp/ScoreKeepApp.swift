import SwiftUI

@main
struct ScoreKeepApp: App {
    @State private var board = ScoreBoard()

    var body: some Scene {
        WindowGroup {
            ScoreboardView()
                .environment(board)
        }
    }
}
