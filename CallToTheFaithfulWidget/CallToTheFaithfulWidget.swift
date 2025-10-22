import WidgetKit
import SwiftUI

struct ServiceEntry: TimelineEntry {
    let date: Date
    let service: Service?
}

struct ServiceProvider: TimelineProvider {
    func placeholder(in context: Context) -> ServiceEntry {
        ServiceEntry(date: Date(), service: placeholderService)
    }

    func getSnapshot(in context: Context, completion: @escaping (ServiceEntry) -> Void) {
        let entry = ServiceEntry(date: Date(), service: ScheduleManager.nextService())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ServiceEntry>) -> Void) {
        let currentDate = Date()
        let nextService = ScheduleManager.nextService(after: currentDate)
        let entry = ServiceEntry(date: currentDate, service: nextService)

        let refreshDate = nextService?.startDate ?? currentDate.addingTimeInterval(60 * 30)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private var placeholderService: Service {
        Service(title: "Sunday Mass", startDate: Date().addingTimeInterval(60 * 60))
    }
}

struct CallToTheFaithfulWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: ServiceProvider.Entry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryInline:
            accessoryInlineView
        default:
            fallbackView
        }
    }

    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.service?.title ?? "No Upcoming Service")
                .font(.headline)
                .minimumScaleFactor(0.8)
                .lineLimit(2)

            if let startDate = entry.service?.startDate {
                Text(startDate, style: .timer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Schedule unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetAccentable()
    }

    private var accessoryInlineView: some View {
        if let service = entry.service {
            return Text("\(service.title) in \(service.startDate, style: .timer)")
        } else {
            return Text("No upcoming service")
        }
    }

    private var fallbackView: some View {
        VStack(alignment: .leading) {
            Text(entry.service?.title ?? "No Upcoming Service")
                .font(.headline)
            if let startDate = entry.service?.startDate {
                Text(startDate, style: .timer)
            }
        }
    }
}

struct CallToTheFaithfulWidget: Widget {
    let kind: String = "CallToTheFaithfulWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ServiceProvider()) { entry in
            CallToTheFaithfulWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Service")
        .description("See the title and countdown to the next service.")
        .supportedFamilies([.accessoryInline, .accessoryRectangular, .systemSmall])
    }
}
