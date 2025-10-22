import Foundation
import UserNotifications

struct ServiceSchedule {
    let identifier: String
    let dateComponents: DateComponents
    let repeats: Bool

    init(identifier: String, dateComponents: DateComponents, repeats: Bool = true) {
        self.identifier = identifier
        self.dateComponents = dateComponents
        self.repeats = repeats
    }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        if repeats {
            return calendar.nextDate(after: date,
                                      matching: dateComponents,
                                      matchingPolicy: .nextTime,
                                      direction: .forward)
        } else {
            guard let scheduledDate = calendar.date(from: dateComponents) else {
                return nil
            }
            return scheduledDate >= date ? scheduledDate : nil
        }
    }
}

struct ServiceDefinition {
    let identifier: String
    let title: String
    let body: String
    let schedules: [ServiceSchedule]

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        schedules.compactMap { $0.nextDate(after: date, calendar: calendar) }.min()
    }
}

struct ScheduledServiceOccurrence {
    let service: ServiceDefinition
    let schedule: ServiceSchedule
    let date: Date
}

final class ScheduleManager {
    static let shared = ScheduleManager()

    private let notificationCenter: UNUserNotificationCenter
    private let calendar: Calendar

    private let services: [ServiceDefinition]

    init(center: UNUserNotificationCenter = .current(), calendar: Calendar = .current) {
        self.notificationCenter = center
        self.calendar = calendar

        var massSchedules: [ServiceSchedule] = []
        let weekdayHours: [(Int, Int, Int)] = [
            (1, 9, 0),   // Sunday 9:00 AM
            (3, 19, 0),  // Tuesday 7:00 PM
            (5, 7, 30),  // Thursday 7:30 AM
            (7, 17, 0)   // Saturday 5:00 PM Vigil
        ]
        for (weekday, hour, minute) in weekdayHours {
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            massSchedules.append(ServiceSchedule(identifier: "mass-\(weekday)-\(hour)-\(minute)",
                                                 dateComponents: components,
                                                 repeats: true))
        }

        var angelusSchedules: [ServiceSchedule] = []
        let angelusHours = [6, 12, 18]
        for hour in angelusHours {
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            angelusSchedules.append(ServiceSchedule(identifier: "angelus-\(hour)",
                                                    dateComponents: components,
                                                    repeats: true))
        }

        services = [
            ServiceDefinition(identifier: "mass",
                               title: "Time for Mass",
                               body: "Join the community for the Holy Mass.",
                               schedules: massSchedules),
            ServiceDefinition(identifier: "angelus",
                               title: "Angelus Prayer",
                               body: "Pause and pray the Angelus.",
                               schedules: angelusSchedules)
        ]
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func rescheduleAll() async throws {
        let identifiers = services.flatMap { service in
            service.schedules.map { "\(service.identifier).\($0.identifier)" }
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)

        for service in services {
            for schedule in service.schedules {
                let content = UNMutableNotificationContent()
                content.title = service.title
                content.body = service.body
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: schedule.dateComponents,
                                                             repeats: schedule.repeats)
                let identifier = "\(service.identifier).\(schedule.identifier)"
                let request = UNNotificationRequest(identifier: identifier,
                                                    content: content,
                                                    trigger: trigger)
                try await add(request)
            }
        }
    }

    func nextService(from date: Date = Date()) -> ScheduledServiceOccurrence? {
        var bestOccurrence: ScheduledServiceOccurrence?

        for service in services {
            for schedule in service.schedules {
                guard let nextDate = schedule.nextDate(after: date, calendar: calendar) else {
                    continue
                }

                let occurrence = ScheduledServiceOccurrence(service: service,
                                                             schedule: schedule,
                                                             date: nextDate)
                if let currentBest = bestOccurrence {
                    if nextDate < currentBest.date {
                        bestOccurrence = occurrence
                    }
                } else {
                    bestOccurrence = occurrence
                }
            }
        }

        return bestOccurrence
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { continuation in
            notificationCenter.add(request) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
