import SwiftUI

/// Single iOS/iPadOS app: phone hosts/relays; iPad (default) joins as display.
/// Mode is owned by the app so Host/Join can start/stop Bonjour and background hosting.
struct CompanionRootView: View {
    @Environment(CompanionDisplayPreferences.self) private var displayPrefs
    @Binding var mode: Mode

    enum Mode: String, CaseIterable, Identifiable {
        case host
        case join
        var id: String { rawValue }
        var title: String {
            switch self {
            case .host: "Host"
            case .join: "Join"
            }
        }
    }

    var body: some View {
        Group {
            switch mode {
            case .host:
                HostScoreboardView(mode: $mode)
            case .join:
                JoinScoreboardView(mode: $mode)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(!displayPrefs.chromeExpanded)
    }
}
