import SwiftUI

/// Single iOS/iPadOS app: phone hosts/relays; iPad (default) joins as display.
struct CompanionRootView: View {
    @Environment(PhoneSessionAuthority.self) private var authority
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
        ZStack(alignment: .topTrailing) {
            Group {
                switch mode {
                case .host:
                    HostScoreboardView()
                case .join:
                    JoinScoreboardView()
                }
            }

            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 180)
            .padding(16)
        }
        .preferredColorScheme(.dark)
    }
}
