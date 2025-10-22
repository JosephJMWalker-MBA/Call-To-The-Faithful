import Foundation
import UserNotifications

/// Represents the next scheduled liturgical event (Mass or Angelus) the
/// application is preparing for.
struct ScheduledService: Equatable {
    enum Kind: Equatable {
        case mass(MassTime)
        case angelus(DateComponents)
    }

    /// Identifier used when creating notification requests.
    let identifier: String

    /// Absolute date when the service will occur.
    let date: Date

    /// Kind of service that is scheduled.
    let kind: Kind
}

/// Coordinates notification scheduling for Mass reminders and daily Angelus
/// prompts.
final class ScheduleManager {
    private let notificationCenter: UNUserNotificationCenter
    private let calendar: Calendar

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current
    ) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
    }

    /// Requests the necessary authorization from the user in order to deliver
    /// local notifications.
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
                continuation.resume(returning: granted && error == nil)
            }
        }
    }

    /// Clears pending reminders and schedules notifications for all Masses and
    /// Angelus times.
    func rescheduleAll(for schedule: ParishSchedule) async {
        let massIdentifiers = schedule.masses.map(ScheduleManager.massIdentifier(for:))
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: massIdentifiers + ScheduleManager.angelusIdentifiers
        )

        for mass in schedule.masses {
            guard let trigger = massTrigger(for: mass) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Mass Reminder"
            content.body = massBody(for: mass)
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: ScheduleManager.massIdentifier(for: mass),
                content: content,
                trigger: trigger
            )

            await add(request)
        }

        for (identifier, components) in ScheduleManager.angelusSchedule {
            guard let trigger = angelusTrigger(for: components) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Angelus Prayer"
            content.body = "It's time to pray the Angelus."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            await add(request)
        }
    }

    /// Calculates the next service (Mass or Angelus) that will occur after the
    /// provided reference date.
    func nextService(
        for schedule: ParishSchedule,
        from referenceDate: Date = Date()
    ) -> ScheduledService? {
        var candidates: [ScheduledService] = []

        for mass in schedule.masses {
            guard let date = nextMassDate(for: mass, after: referenceDate) else { continue }
            candidates.append(
                ScheduledService(
                    identifier: ScheduleManager.massIdentifier(for: mass),
                    date: date,
                    kind: .mass(mass)
                )
            )
        }

        for (identifier, components) in ScheduleManager.angelusSchedule {
            guard let date = nextAngelusDate(for: components, after: referenceDate) else { continue }
            candidates.append(
                ScheduledService(
                    identifier: identifier,
                    date: date,
                    kind: .angelus(components)
                )
            )
        }

        return candidates.min(by: { $0.date < $1.date })
    }
}

private extension ScheduleManager {
    static let angelusHours: [Int] = [6, 12, 18]

    static var angelusSchedule: [(String, DateComponents)] {
        angelusHours.map { hour in
            (
                angelusIdentifier(forHour: hour),
                DateComponents(hour: hour, minute: 0, second: 0)
            )
        }
    }

    static var angelusIdentifiers: [String] {
        angelusHours.map(angelusIdentifier(forHour:))
    }

    static func angelusIdentifier(forHour hour: Int) -> String {
        String(format: "angelus-%02d00", hour)
    }

    static func massIdentifier(for mass: MassTime) -> String {
        "mass-\(mass.id.uuidString)"
    }

    func massBody(for mass: MassTime) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        guard
            let hour = mass.time.hour,
            let minute = mass.time.minute,
            let date = calendar.date(from: DateComponents(hour: hour, minute: minute))
        else {
            return "A scheduled Mass begins soon."
        }

        let timeString = formatter.string(from: date)
        if let label = mass.label, !label.isEmpty {
            return "Mass (\(label)) begins at \(timeString)."
        } else {
            return "Mass on \(mass.weekday.name) begins at \(timeString)."
        }
    }

    func massTrigger(for mass: MassTime) -> UNCalendarNotificationTrigger? {
        guard let hour = mass.time.hour, let minute = mass.time.minute else { return nil }

        var components = DateComponents()
        components.weekday = mass.weekday.rawValue
        components.hour = hour
        components.minute = minute
        components.second = mass.time.second ?? 0

        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    func angelusTrigger(for components: DateComponents) -> UNCalendarNotificationTrigger? {
        guard components.hour != nil else { return nil }
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    func nextMassDate(for mass: MassTime, after referenceDate: Date) -> Date? {
        guard mass.time.hour != nil, mass.time.minute != nil else { return nil }

        var components = DateComponents()
        components.weekday = mass.weekday.rawValue
        components.hour = mass.time.hour
        components.minute = mass.time.minute
        components.second = mass.time.second ?? 0

        return calendar.nextDate(
            after: referenceDate,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            direction: .forward
        )
    }

    func nextAngelusDate(for components: DateComponents, after referenceDate: Date) -> Date? {
        calendar.nextDate(
            after: referenceDate,
            matching: components,
            matchingPolicy: .nextTime,
            direction: .forward
        )
    }

    func add(_ request: UNNotificationRequest) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            notificationCenter.add(request) { _ in
                continuation.resume()
            }
        }
    }
}
