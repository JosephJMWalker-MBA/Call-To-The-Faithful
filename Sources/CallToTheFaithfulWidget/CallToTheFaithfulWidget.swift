import SwiftUI
import WidgetKit
import CallToTheFaithful

struct NextServiceEntry: TimelineEntry {
    let date: Date
    let service: ScheduledService?
}

struct NextServiceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextServiceEntry {
        NextServiceEntry(date: Date(), service: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextServiceEntry) -> Void) {
        let snapshotService = context.isPreview ? ScheduledService.placeholder : ScheduleManager.nextService()
        completion(NextServiceEntry(date: Date(), service: snapshotService))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextServiceEntry>) -> Void) {
        let now = Date()
        let service = ScheduleManager.nextService(now: now)

        let entry = NextServiceEntry(date: now, service: service)
        let refreshDate: Date

        if let nextDate = service?.date {
            refreshDate = nextDate
        } else {
            refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        }

        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct NextServiceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: NextServiceEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularContent
        case .accessoryRectangular:
            rectangularContent
        case .accessoryInline:
            inlineContent
        default:
            VStack {
                Text(entry.service?.title ?? "No Upcoming Service")
                if let date = entry.service?.date {
                    Text(date, style: .timer)
                }
            }
        }
    }

    private var circularContent: some View {
        VStack(spacing: 4) {
            Text(entry.service?.title ?? "Next")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            if let date = entry.service?.date {
                Text(date, style: .timer)
                    .font(.caption2)
                    .minimumScaleFactor(0.6)
            } else {
                Text("--")
                    .font(.caption2)
            }
        }
    }

    private var rectangularContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.service?.title ?? "No Upcoming Service")
                .font(.headline)
                .lineLimit(1)
            if let date = entry.service?.date {
                Text(date, style: .timer)
                    .font(.caption)
            } else {
                Text("Stay tuned")
                    .font(.caption)
            }
        }
    }

    private var inlineContent: some View {
        if let service = entry.service {
            Text(service.title) + Text(" ") + Text(service.date, style: .timer)
        } else {
            Text("No upcoming service")
        }
    }
}

@main
struct CallToTheFaithfulWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CallToTheFaithfulWidget", provider: NextServiceTimelineProvider()) { entry in
            NextServiceWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Service")
        .description("Keep an eye on the next service time.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private extension ScheduledService {
    static var placeholder: ScheduledService {
        let placeholderMass = MassTime(
            weekday: .sunday,
            time: DateComponents(hour: 9, minute: 30),
            label: "Sunday Mass"
        )
        let date = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        return ScheduledService(kind: .mass(placeholderMass), date: date)
    }
}
