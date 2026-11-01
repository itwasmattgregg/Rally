import SwiftUI

/// Single iOS/iPadOS app: phone hosts/relays; iPad (default) joins as display.
struct CompanionRootView: View {
    @Environment(PhoneSessionAuthority.self) private var authority
    @Environment(CompanionDisplayPreferences.self) private var displayPrefs
    @State private var mode: Mode

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

    init() {
        let defaultMode: Mode = UIDevice.current.userInterfaceIdiom == .pad ? .join : .host
        _mode = State(initialValue: defaultMode)
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
