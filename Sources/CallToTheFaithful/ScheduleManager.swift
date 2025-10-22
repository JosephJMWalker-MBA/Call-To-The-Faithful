import Foundation

public struct ScheduledService {
    public let title: String
    public let date: Date

    public init(title: String, date: Date) {
        self.title = title
        self.date = date
    }
}

public enum ScheduleManager {
    public static func nextService(
        now: Date = Date(),
        calendar: Calendar = Calendar.current,
        storage: ParishScheduleStorage = ParishScheduleStorage()
    ) -> ScheduledService? {
        var workingStorage = storage
        guard let schedule = workingStorage.load() else { return nil }
        return nextService(from: schedule, now: now, calendar: calendar)
    }

    public static func nextService(
        from schedule: ParishSchedule,
        now: Date = Date(),
        calendar: Calendar = Calendar.current
    ) -> ScheduledService? {
        let masses = schedule.masses
        guard !masses.isEmpty else { return nil }

        let nextMass = masses.compactMap { mass -> (MassTime, Date)? in
            var components = mass.time
            components.weekday = mass.weekday.rawValue
            components.calendar = calendar

            guard let occurrence = calendar.nextDate(
                after: now,
                matching: components,
                matchingPolicy: .nextTimePreservingSmallerComponents,
                repeatedTimePolicy: .first,
                direction: .forward
            ) else {
                return nil
            }

            return (mass, occurrence)
        }
        .min { $0.1 < $1.1 }

        guard let (mass, date) = nextMass else { return nil }

        let title: String
        if let label = mass.label, !label.isEmpty {
            title = label
        } else {
            title = "\(mass.weekday.name) Service"
        }

        return ScheduledService(title: title, date: date)
    }
}
