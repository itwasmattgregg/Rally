import SwiftUI

struct TeamColumn: View {
    let name: String
    let score: Int
    let accent: Color
    let glow: Color
    let reduced: Bool
    var highlighted: Bool = false
    let onUp: () -> Void
    let onDown: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.scoreLabel(.caption2))
                .foregroundStyle(reduced ? ScoreTheme.inkMuted : accent.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .overlay(alignment: .bottom) {
                    if highlighted && !reduced {
                        Capsule()
                            .fill(accent)
                            .frame(width: 14, height: 2)
                            .offset(y: 3)
                            .transition(.opacity.combined(with: .scale))
                    }
                }

            Button(action: bump) {
                Text("\(score)")
                    .font(.scoreHero(size: scoreFontSize))
                    .foregroundStyle(reduced ? ScoreTheme.ink.opacity(0.7) : ScoreTheme.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentTransition(.numericText(value: Double(score)))
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .shadow(color: reduced ? .clear : glow, radius: pulse ? 10 : 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(name) score \(score)")
            .accessibilityHint("Tap to add one point")

            Button(action: drop) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(reduced ? ScoreTheme.inkMuted : accent.opacity(0.85))
                    .frame(width: 28, height: 22)
                    .background(
                        Capsule()
                            .fill(ScoreTheme.resetFill)
                            .overlay(
                                Capsule()
                                    .strokeBorder(accent.opacity(reduced ? 0.15 : 0.35), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(score == 0)
            .opacity(score == 0 ? 0.35 : 1)
            .accessibilityLabel("Subtract one from \(name)")
        }
        .padding(.vertical, 2)
        .animation(.easeInOut(duration: 0.2), value: highlighted)
    }

    private var scoreFontSize: CGFloat {
        switch score {
        case 0...9: 44
        case 10...99: 36
        default: 28
        }
    }

    private func bump() {
        onUp()
        WatchHaptics.scoreUp()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            pulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                pulse = false
            }
        }
    }

    private func drop() {
        onDown()
        WatchHaptics.scoreDown()
    }
}
