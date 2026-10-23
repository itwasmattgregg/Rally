import SwiftUI

/// iPad (or phone) spectator: enter/browse code, fullscreen scores, reconnect banner.
struct JoinScoreboardView: View {
    @Environment(BoardBrowser.self) private var browser
    @State private var code = ""
    @FocusState private var codeFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            if let state = browser.state, browser.isConnected || browser.isReconnecting {
                DisplayScoreboardView(state: state)
                if browser.isReconnecting {
                    reconnectBanner
                }
            } else {
                joinChrome
            }
        }
        .onAppear {
            browser.startBrowsing()
        }
    }

    private var reconnectBanner: some View {
        Text(browser.statusMessage)
            .font(.system(.footnote, design: .rounded).weight(.bold))
            .foregroundStyle(ScoreTheme.fieldTop)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(ScoreTheme.away, in: Capsule())
            .padding(.top, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: browser.isReconnecting)
    }

    private var joinChrome: some View {
        ZStack {
            LinearGradient(
                colors: [ScoreTheme.fieldTop, ScoreTheme.fieldBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Rally")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(ScoreTheme.home)

                Text("Join a court board")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(ScoreTheme.ink)

                TextField("CODE", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .focused($codeFocused)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(ScoreTheme.resetFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ScoreTheme.hairline, lineWidth: 1)
                    )
                    .frame(maxWidth: 280)

                Button {
                    browser.join(code: code)
                } label: {
                    Text("Join")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(ScoreTheme.home)
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).count < 4)

                if !browser.nearby.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nearby")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(ScoreTheme.inkMuted)
                        ForEach(browser.nearby) { board in
                            Button {
                                browser.join(board)
                            } label: {
                                HStack {
                                    Text(board.name)
                                        .foregroundStyle(ScoreTheme.ink)
                                    Spacer()
                                    Text(board.code)
                                        .foregroundStyle(ScoreTheme.home)
                                        .fontWeight(.bold)
                                }
                                .font(.system(.body, design: .rounded))
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: 320)
                    .padding(.top, 8)
                }

                Text(browser.statusMessage)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(ScoreTheme.inkMuted)

                if let error = browser.lastError {
                    Text(error)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(ScoreTheme.away)
                }
            }
            .padding(24)
        }
    }
}
