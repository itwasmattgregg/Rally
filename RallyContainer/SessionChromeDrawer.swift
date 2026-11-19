import SwiftUI

/// Trailing-edge session chrome (QR / code / status / themes / fonts).
/// Collapsed: no bottom grabber and no score inset — only a thin trailing-edge
/// swipe target so numerals stay edge-to-edge. Expanded: side panel overlays
/// the board; swipe toward the trailing edge (or tap scrim) to dismiss.
struct SessionChromeDrawer<Content: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    private let spring = Animation.spring(response: 0.38, dampingFraction: 0.86)
    private let dragThreshold: CGFloat = 48
    /// Narrow trailing hit strip — does not reserve score layout space.
    private let edgeHitWidth: CGFloat = 20

    var body: some View {
        if isExpanded {
            GeometryReader { geo in
                let panelWidth = resolvedPanelWidth(for: geo.size)
                ZStack(alignment: .trailing) {
                    Color.black.opacity(0.38)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { setExpanded(false) }
                        .accessibilityLabel("Dismiss session chrome")
                        .accessibilityAddTraits(.isButton)

                    panel(width: panelWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .gesture(dismissGesture)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        } else {
            // No GeometryReader when collapsed — only the trailing strip participates in hit-testing.
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                    .allowsHitTesting(false)
                trailingEdgeAffordance
            }
        }
    }

    private func resolvedPanelWidth(for size: CGSize) -> CGFloat {
        let landscape = size.width > size.height
        let fraction: CGFloat = landscape ? 0.42 : 0.88
        return min(max(size.width * fraction, 280), min(380, size.width))
    }

    private func panel(width: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            content()
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(panelBackground)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Session chrome")
        .accessibilityValue("Expanded")
        .accessibilityHint("Swipe right or tap outside to dismiss")
    }

    private var panelBackground: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 18,
            bottomLeadingRadius: 18,
            bottomTrailingRadius: 0,
            topTrailingRadius: 0,
            style: .continuous
        )
        .fill(.ultraThinMaterial)
        .overlay {
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .strokeBorder(ScoreTheme.hairline, lineWidth: 1)
        }
        .ignoresSafeArea(edges: .trailing)
    }

    /// Trailing-edge swipe target + hairline tick for discoverability.
    /// Overlay only — no bottom/score inset and no full-width hit blocking.
    private var trailingEdgeAffordance: some View {
        ZStack(alignment: .trailing) {
            Color.clear
                .frame(width: edgeHitWidth)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())

            Capsule()
                .fill(ScoreTheme.ink.opacity(0.22))
                .frame(width: 3, height: 34)
                .padding(.trailing, 5)
        }
        .frame(width: edgeHitWidth)
        .frame(maxHeight: .infinity)
        .gesture(openGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Session chrome")
        .accessibilityValue("Collapsed")
        .accessibilityHint("Swipe left from the trailing edge to show session details")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            setExpanded(true)
        }
    }

    /// Open: horizontal drag from trailing edge toward leading (negative width).
    private var openGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onEnded { value in
                let dx = value.translation.width
                let predicted = value.predictedEndTranslation.width
                // Prefer clearly horizontal swipes so vertical score-scroll noise is ignored.
                guard abs(dx) >= abs(value.translation.height) * 0.65 else { return }
                if predicted < -dragThreshold || dx < -dragThreshold {
                    setExpanded(true)
                }
            }
    }

    /// Dismiss: swipe toward trailing edge (positive width).
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onEnded { value in
                let dx = value.translation.width
                let predicted = value.predictedEndTranslation.width
                guard abs(dx) >= abs(value.translation.height) * 0.55 else { return }
                if predicted > dragThreshold || dx > dragThreshold {
                    setExpanded(false)
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
