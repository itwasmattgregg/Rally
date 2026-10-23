import SwiftUI

/// iPhone display-only host: live scores + QR/session code + Bonjour advertise.
struct HostScoreboardView: View {
    @Environment(PhoneSessionAuthority.self) private var authority
    @Environment(BoardAdvertiser.self) private var advertiser

    var body: some View {
        ZStack(alignment: .bottom) {
            DisplayScoreboardView(state: authority.state, compactChrome: true)

            VStack(spacing: 12) {
                Text(authority.statusMessage)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(ScoreTheme.inkMuted)

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
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
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
}
