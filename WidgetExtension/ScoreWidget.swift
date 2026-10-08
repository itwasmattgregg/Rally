import SwiftUI
import WidgetKit

struct ScoreEntry: TimelineEntry {
    let date: Date
    let home: Int
    let away: Int

    var relevance: TimelineEntryRelevance? {
        let active = home + away > 0
        return TimelineEntryRelevance(score: active ? 80 : 5, duration: 60 * 60)
    }
}

struct ScoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScoreEntry {
        ScoreEntry(date: .now, home: 12, away: 9)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScoreEntry) -> Void) {
        let scores = ScoreDefaults.readScores()
        completion(ScoreEntry(date: .now, home: scores.home, away: scores.away))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScoreEntry>) -> Void) {
        let scores = ScoreDefaults.readScores()
        let entry = ScoreEntry(date: .now, home: scores.home, away: scores.away)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
    }
}

struct ScoreWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ScoreEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("SCOREKEEP")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                Text("\(entry.home)  –  \(entry.away)")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .invalidatableContent()
            }
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryCorner:
            Text("\(entry.home)–\(entry.away)")
                .font(.system(.body, design: .rounded).weight(.bold))
                .widgetLabel { Text("Score") }
                .containerBackground(for: .widget) { Color.clear }
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Text("\(entry.home)–\(entry.away)")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .minimumScaleFactor(0.6)
            }
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            Text("Score \(entry.home)–\(entry.away)")
                .containerBackground(for: .widget) { Color.clear }
        default:
            Text("\(entry.home)–\(entry.away)")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .containerBackground(for: .widget) { Color.clear }
        }
    }
}

struct ScoreKeepWidget: Widget {
    let kind = "ScoreKeepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScoreProvider()) { entry in
            ScoreWidgetView(entry: entry)
        }
        .configurationDisplayName("Score")
        .description("Glanceable score while you wear the watch.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}

@main
struct ScoreKeepWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScoreKeepWidget()
    }
}
