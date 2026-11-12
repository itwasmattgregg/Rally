import SwiftUI

/// Bottom drawer for companion session chrome (QR/code/status/themes).
/// Collapsed to a system-style grabber so scores stay as large as possible.
struct SessionChromeDrawer<Content: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    private let spring = Animation.spring(response: 0.38, dampingFraction: 0.86)
    private let dragThreshold: CGFloat = 36

    var body: some View {
        VStack(spacing: 0) {
            grabber
                .gesture(handleGesture)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Session chrome")
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
                .accessibilityHint(isExpanded ? "Collapses session details" : "Expands session details")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    setExpanded(!isExpanded)
                }

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

    /// Subtle capsule grabber — tap or drag like a system sheet handle.
    private var grabber: some View {
        Capsule()
            .fill(ScoreTheme.ink.opacity(0.35))
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, isExpanded ? 10 : 14)
            .contentShape(Rectangle())
    }

    private var handleGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onEnded { value in
                let dy = value.translation.height
                let predicted = value.predictedEndTranslation.height

                // Short travel → one-tap toggle (sheet-handle feel).
                if hypot(value.translation.width, dy) < 10 {
                    setExpanded(!isExpanded)
                    return
                }

                if isExpanded {
                    if predicted > dragThreshold || dy > dragThreshold {
                        setExpanded(false)
                    }
                } else if predicted < -dragThreshold || dy < -dragThreshold {
                    setExpanded(true)
                }
            }
    }

    private func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded else { return }
        withAnimation(spring) {
            isExpanded = expanded
        }
    }
}

/// Compact theme chooser for the session drawer.
struct NumberThemePicker: View {
    @Binding var theme: ScoreNumberTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Number theme")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(ScoreTheme.inkMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ScoreNumberTheme.allCases) { option in
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

/// Compact font chooser for the session drawer (alongside color themes).
struct NumberFontPicker: View {
    @Binding var fontStyle: ScoreNumberFont

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Number font")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(ScoreTheme.inkMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ScoreNumberFont.allCases) { option in
                        Button {
                            fontStyle = option
                        } label: {
                            HStack(spacing: 6) {
                                if option.usesSegmentedDigits {
                                    SegmentedScoreText(
                                        value: 88,
                                        digitHeight: 12,
                                        color: ScoreTheme.ink,
                                        ghostOpacity: 0.2
                                    )
                                }
                                Text(option.title)
                                    .font(.system(.caption2, design: option.design).weight(.semibold))
                                    .foregroundStyle(ScoreTheme.ink)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(fontStyle == option ? ScoreTheme.resetFill : Color.clear)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                fontStyle == option
                                                    ? ScoreTheme.ink.opacity(0.35)
                                                    : ScoreTheme.hairline,
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.title)
                        .accessibilityAddTraits(fontStyle == option ? .isSelected : [])
                    }
                }
            }
        }
    }
}
