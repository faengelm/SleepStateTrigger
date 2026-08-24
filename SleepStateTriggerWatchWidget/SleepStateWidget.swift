import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SleepStateEntry: TimelineEntry {
    let date: Date
    let state: String
}

// MARK: - Timeline Provider

struct SleepStateProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepStateEntry {
        SleepStateEntry(date: .now, state: "awake")
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepStateEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepStateEntry>) -> Void) {
        let entry = currentEntry()
        let next = Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> SleepStateEntry {
        let ud = UserDefaults(suiteName: "group.com.sleepstatetrigger.app") ?? .standard
        let state = ud.string(forKey: "watchSleepState") ?? "unknown"
        return SleepStateEntry(date: .now, state: state)
    }
}

// MARK: - Complication Views

struct SleepStateComplicationView: View {
    let entry: SleepStateEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            rectangularView
                .containerBackground(.clear, for: .widget)
        case .accessoryInline:
            inlineView
        default:
            circularView
                .containerBackground(.clear, for: .widget)
        }
    }

    private var circularView: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.title3)
            Text(shortName)
                .font(.system(size: 9))
                .minimumScaleFactor(0.5)
        }
        .widgetAccentable()
    }

    private var rectangularView: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text("Sleep State")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(displayName)
                    .font(.headline)
            }
        }
    }

    private var inlineView: some View {
        Label(displayName, systemImage: icon)
    }

    // MARK: - State Mapping

    private var displayName: String {
        switch entry.state {
        case "awake":   return "Awake"
        case "asleep":  return "Asleep"
        case "inBed":   return "In Bed"
        case "rem":     return "REM"
        case "core":    return "Core"
        case "deep":    return "Deep"
        default:        return "—"
        }
    }

    private var shortName: String {
        switch entry.state {
        case "awake":   return "Awake"
        case "asleep":  return "Sleep"
        case "inBed":   return "Bed"
        case "rem":     return "REM"
        case "core":    return "Core"
        case "deep":    return "Deep"
        default:        return "—"
        }
    }

    private var icon: String {
        switch entry.state {
        case "awake":   return "sun.max.fill"
        case "asleep":  return "moon.fill"
        case "inBed":   return "bed.double.fill"
        case "rem":     return "moon.stars.fill"
        case "core":    return "powersleep"
        case "deep":    return "moon.zzz.fill"
        default:        return "questionmark.circle"
        }
    }
}

// MARK: - Widget

@main
struct SleepStateWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SleepStateComplication", provider: SleepStateProvider()) { entry in
            SleepStateComplicationView(entry: entry)
        }
        .configurationDisplayName("Sleep State")
        .description("Shows current sleep stage on your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}
