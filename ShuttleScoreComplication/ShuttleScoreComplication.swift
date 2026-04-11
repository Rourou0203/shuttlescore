import WidgetKit
import SwiftUI

// MARK: - Language Helper

private var isZh: Bool {
    Locale.current.language.languageCode?.identifier == "zh"
}

// MARK: - Timeline Entry

struct ComplicationEntry: TimelineEntry {
    let date: Date
}

// MARK: - Timeline Provider

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(ComplicationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let entry = ComplicationEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Complication Widget

struct ShuttleScoreComplication: Widget {
    let kind: String = "ShuttleScoreComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName(isZh ? "羽毛球计分" : "Badminton")
        .description(isZh ? "快速开始计分" : "Quick start scoring")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}

// MARK: - Complication View

struct ComplicationView: View {
    var entry: ComplicationEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: "figure.badminton")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isZh ? "计分" : "Score")
                        .font(.system(size: 8, weight: .medium))
                }
            }
            .widgetURL(URL(string: "shuttlescore://start"))

        case .accessoryRectangular:
            HStack(spacing: 6) {
                Image(systemName: "figure.badminton")
                    .font(.system(size: 18, weight: .semibold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(isZh ? "羽毛球计分" : "Badminton")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isZh ? "点击开始" : "Tap to start")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .widgetURL(URL(string: "shuttlescore://start"))

        case .accessoryCorner:
            Image(systemName: "figure.badminton")
                .font(.system(size: 16, weight: .semibold))
                .widgetLabel(isZh ? "计分" : "Score")
                .widgetURL(URL(string: "shuttlescore://start"))

        default:
            Image(systemName: "figure.badminton")
                .widgetURL(URL(string: "shuttlescore://start"))
        }
    }
}

// MARK: - Widget Bundle

@main
struct ShuttleScoreComplicationBundle: WidgetBundle {
    var body: some Widget {
        ShuttleScoreComplication()
    }
}
