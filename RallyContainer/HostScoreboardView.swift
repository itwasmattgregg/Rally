import SwiftUI

/// iPhone display-only host: live scores + grabber drawer for QR/session chrome + Bonjour advertise.
struct HostScoreboardView: View {
    @Environment(PhoneSessionAuthority.self) private var authority
    @Environment(BoardAdvertiser.self) private var advertiser
    @Environment(CompanionDisplayPreferences.self) private var displayPrefs
    @Binding var mode: CompanionRootView.Mode

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            // Reserve space under the board so QR/session chrome never covers numerals.
            let expandedInset: CGFloat = landscape ? 200 : 248
            let collapsedInset: CGFloat = 44

            ZStack(alignment: .bottom) {
                DisplayScoreboardView(
                    state: authority.state,
                    theme: displayPrefs.numberTheme,
                    bottomChromeInset: displayPrefs.chromeExpanded ? expandedInset : collapsedInset,
                    compactLabels: true
                )

                SessionChromeDrawer(isExpanded: Binding(
                    get: { displayPrefs.chromeExpanded },
                    set: { displayPrefs.chromeExpanded = $0 }
                )) {
                    hostChromeContent
                }
            }
        }
        .onAppear {
            authority.bootstrapHostIfNeeded()
            advertiser.start(authority: authority)
        }
        .onChange(of: authority.state.revision) { _, _ in
            advertiser.broadcast(authority.state)
        }
    }

    private var hostChromeContent: some View {
        VStack(spacing: 14) {
            modePicker

            Text(authority.statusMessage)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(ScoreTheme.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: 16) {
                QRCodeView(payload: "rallyboard:\(authority.sessionCode)")
                    .frame(width: 96, height: 96)
                    .padding(8)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(authority.sessionCode)
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(ScoreTheme.ink)
                        .tracking(4)
                    Text(advertiser.isAdvertising ? "Broadcasting" : "Starting…")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(ScoreTheme.home)
                    Text("\(authority.connectedDisplays) display\(authority.connectedDisplays == 1 ? "" : "s")")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(ScoreTheme.inkMuted)
                }
                Spacer(minLength: 0)
            }

            NumberThemePicker(
                theme: Binding(
                    get: { displayPrefs.numberTheme },
                    set: { displayPrefs.numberTheme = $0 }
                )
            )
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(CompanionRootView.Mode.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 220)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
