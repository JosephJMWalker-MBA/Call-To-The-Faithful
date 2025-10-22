import Foundation

struct Service: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let startDate: Date
}

enum ScheduleManager {
    private static let calendar = Calendar(identifier: .gregorian)

    /// Returns the next service after the provided date.
    static func nextService(after date: Date = .init()) -> Service? {
        let services = upcomingServices(from: date)
        return services.sorted { $0.startDate < $1.startDate }.first
    }

    private static func upcomingServices(from date: Date) -> [Service] {
        let baseHour = 9
        let baseMinute = 0
        let weekOffsets = Array(0..<8)
        let now = date

        guard let firstSunday = calendar.nextDate(after: now,
                                                  matching: DateComponents(weekday: 1,
                                                                           hour: baseHour,
                                                                           minute: baseMinute),
                                                  matchingPolicy: .nextTimePreservingSmallerComponents,
                                                  repeatedTimePolicy: .first,
                                                  direction: .forward) else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"

        return weekOffsets.compactMap { offset in
            guard let serviceDate = calendar.date(byAdding: .weekOfYear, value: offset, to: firstSunday) else {
                return nil
            }
            let dateString = formatter.string(from: serviceDate)
            return Service(title: "Sunday Mass \(dateString)", startDate: serviceDate)
        }.filter { $0.startDate > now }
    }
}
