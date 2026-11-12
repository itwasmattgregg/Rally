import SwiftUI

/// Seven-segment score numerals — old digital clock / court scoreboard look.
struct SegmentedScoreText: View {
    let value: Int
    var digitHeight: CGFloat
    var color: Color
    /// Ghost inactive segments (classic LED). Keep low so phone stays readable.
    var ghostOpacity: Double = 0.12

    var body: some View {
        let digits = Array(String(max(value, 0)))
        HStack(spacing: digitHeight * 0.12) {
            ForEach(Array(digits.enumerated()), id: \.offset) { _, ch in
                SegmentedDigit(
                    digit: ch.wholeNumberValue ?? 0,
                    height: digitHeight,
                    color: color,
                    ghostOpacity: ghostOpacity
                )
            }
        }
        .accessibilityLabel("\(max(value, 0))")
    }
}

/// Shared score hero that switches to drawn segments when that font is selected.
struct ScoreHeroText: View {
    let value: Int
    var size: CGFloat
    var style: ScoreNumberFont = .rounded
    var color: Color
    var ghostOpacity: Double = 0.12

    var body: some View {
        Group {
            if style.usesSegmentedDigits {
                SegmentedScoreText(
                    value: value,
                    digitHeight: size,
                    color: color,
                    ghostOpacity: ghostOpacity
                )
            } else {
                Text("\(max(value, 0))")
                    .font(.scoreHero(size: size, style: style))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
        }
    }
}

// MARK: - Digit

private struct SegmentedDigit: View {
    let digit: Int
    let height: CGFloat
    let color: Color
    let ghostOpacity: Double

    var body: some View {
        let thickness = max(height * 0.12, 2)
        let width = height * 0.58
        let gap = thickness * 0.35
        let active = SegmentMask.mask(for: digit)

        ZStack {
            // a — top
            segment(on: active.contains(.a), thickness: thickness, length: width - thickness)
                .offset(y: -(height - thickness) / 2)
            // d — bottom
            segment(on: active.contains(.d), thickness: thickness, length: width - thickness)
                .offset(y: (height - thickness) / 2)
            // g — middle
            segment(on: active.contains(.g), thickness: thickness, length: width - thickness)

            // f — upper left
            segment(on: active.contains(.f), thickness: thickness, length: (height / 2) - thickness - gap, vertical: true)
                .offset(x: -(width - thickness) / 2, y: -(height / 4))
            // b — upper right
            segment(on: active.contains(.b), thickness: thickness, length: (height / 2) - thickness - gap, vertical: true)
                .offset(x: (width - thickness) / 2, y: -(height / 4))
            // e — lower left
            segment(on: active.contains(.e), thickness: thickness, length: (height / 2) - thickness - gap, vertical: true)
                .offset(x: -(width - thickness) / 2, y: height / 4)
            // c — lower right
            segment(on: active.contains(.c), thickness: thickness, length: (height / 2) - thickness - gap, vertical: true)
                .offset(x: (width - thickness) / 2, y: height / 4)
        }
        .frame(width: width, height: height)
    }

    private func segment(on: Bool, thickness: CGFloat, length: CGFloat, vertical: Bool = false) -> some View {
        let w = vertical ? thickness : max(length, 1)
        let h = vertical ? max(length, 1) : thickness
        return RoundedRectangle(cornerRadius: thickness * 0.35, style: .continuous)
            .fill(color.opacity(on ? 1 : ghostOpacity))
            .frame(width: w, height: h)
    }
}

private enum Segment: Hashable {
    case a, b, c, d, e, f, g
}

private enum SegmentMask {
    static func mask(for digit: Int) -> Set<Segment> {
        switch digit {
        case 0: [.a, .b, .c, .d, .e, .f]
        case 1: [.b, .c]
        case 2: [.a, .b, .d, .e, .g]
        case 3: [.a, .b, .c, .d, .g]
        case 4: [.b, .c, .f, .g]
        case 5: [.a, .c, .d, .f, .g]
        case 6: [.a, .c, .d, .e, .f, .g]
        case 7: [.a, .b, .c]
        case 8: [.a, .b, .c, .d, .e, .f, .g]
        case 9: [.a, .b, .c, .d, .f, .g]
        default: [.a, .b, .c, .d, .e, .f]
        }
    }
}
