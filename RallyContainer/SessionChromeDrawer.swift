import SwiftUI

/// Bottom drawer for companion session chrome (QR/code/status/themes).
/// Collapsed to a thin handle so scores are not covered.
struct SessionChromeDrawer<Content: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(spacing: 6) {
                    Capsule()
                        .fill(ScoreTheme.ink.opacity(0.35))
                        .frame(width: 36, height: 5)
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                        Text(isExpanded ? "Hide session" : "Session")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(ScoreTheme.inkMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, isExpanded ? 8 : 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Hide session chrome" : "Show session chrome")

            if isExpanded {
                content()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 18,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
            .overlay(alignment: .top) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 18,
                    style: .continuous
                )
                .strokeBorder(ScoreTheme.hairline, lineWidth: 1)
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// Compact theme chooser for the session drawer.
struct NumberThemePicker: View {
    @Binding var theme: CompanionNumberTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Number theme")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(ScoreTheme.inkMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CompanionNumberTheme.allCases) { option in
                        Button {
                            theme = option
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(option.home)
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(option.away)
                                    .frame(width: 10, height: 10)
                                Text(option.title)
                                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                                    .foregroundStyle(ScoreTheme.ink)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(theme == option ? ScoreTheme.resetFill : Color.clear)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                theme == option ? ScoreTheme.ink.opacity(0.35) : ScoreTheme.hairline,
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.title)
                        .accessibilityAddTraits(theme == option ? .isSelected : [])
                    }
                }
            }
        }
    }
}
