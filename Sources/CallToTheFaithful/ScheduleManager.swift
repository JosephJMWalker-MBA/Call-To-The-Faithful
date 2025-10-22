import Foundation
import UserNotifications
#if canImport(WatchKit)
import WatchKit
#endif

public struct ScheduledService: Identifiable, Equatable {
    public enum Kind: Equatable {
        case mass(MassTime)
        case angelus
    }

    public let id: UUID
    public let kind: Kind
    public let date: Date

    public init(id: UUID = UUID(), kind: Kind, date: Date) {
        self.id = id
        self.kind = kind
        self.date = date
    }

    public var title: String {
        switch kind {
        case let .mass(mass):
            if let label = mass.label, !label.isEmpty {
                return label
            }
            return "\(mass.weekday.name) Mass"
        case .angelus:
            return "Angelus"
        }
    }

    public var subtitle: String? {
        switch kind {
        case let .mass(mass):
            return mass.label?.isEmpty == false ? mass.weekday.name : nil
        case .angelus:
            return "Traditional devotion"
        }
    }
}

@MainActor
public final class ScheduleManager: ObservableObject {
    @Published public private(set) var schedule: ParishSchedule {
        didSet {
            persistSchedule()
            refreshUpcomingService()
        }
    }

    @Published public var isAngelusEnabled: Bool {
        didSet {
            guard oldValue != isAngelusEnabled else { return }
            userDefaults.set(isAngelusEnabled, forKey: Self.angelusDefaultsKey)
            refreshUpcomingService()
        }
    }

    @Published public private(set) var nextService: ScheduledService?
    @Published public private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var isOnboardingPresented: Bool

    private var storage: ParishScheduleStorage
    private let userDefaults: UserDefaults

    private static let angelusDefaultsKey = "isAngelusEnabled"
    private static let onboardingDefaultsKey = "hasCompletedOnboarding"

    public init(
        defaultSchedule: ParishSchedule = .empty,
        storage: ParishScheduleStorage = ParishScheduleStorage(),
        userDefaults: UserDefaults = .standard,
        now: Date = Date()
    ) {
        var workingStorage = storage
        self.userDefaults = userDefaults

        let initialSchedule: ParishSchedule
        if let persisted = workingStorage.load() {
            initialSchedule = persisted
        } else {
            initialSchedule = defaultSchedule
            workingStorage.save(defaultSchedule)
        }

        self.storage = workingStorage
        self.schedule = initialSchedule

        let hasAngelusPreference = userDefaults.object(forKey: Self.angelusDefaultsKey) != nil
        if !hasAngelusPreference {
            userDefaults.set(true, forKey: Self.angelusDefaultsKey)
        }
        isAngelusEnabled = userDefaults.bool(forKey: Self.angelusDefaultsKey)

        let hasCompletedOnboarding = userDefaults.bool(forKey: Self.onboardingDefaultsKey)
        isOnboardingPresented = !hasCompletedOnboarding

        refreshUpcomingService(now: now)
        refreshNotificationStatus()
    }

    public func applyPreset(_ preset: SchedulePreset) {
        schedule = ParishSchedule(parishName: preset.title, masses: preset.masses)
    }

    public func updateMasses(_ masses: [MassTime]) {
        let sortedMasses = masses.sorted { lhs, rhs in
            if lhs.weekday == rhs.weekday {
                let lhsHour = lhs.time.hour ?? 0
                let rhsHour = rhs.time.hour ?? 0
                if lhsHour == rhsHour {
                    return (lhs.time.minute ?? 0) < (rhs.time.minute ?? 0)
                }
                return lhsHour < rhsHour
            }
            return lhs.weekday.rawValue < rhs.weekday.rawValue
        }
        schedule = ParishSchedule(parishName: schedule.parishName, masses: sortedMasses)
    }

    public func refreshUpcomingService(now: Date = Date()) {
        nextService = Self.nextService(from: schedule, isAngelusEnabled: isAngelusEnabled, now: now)
    }

    public func ringBellNow() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.success)
        #endif
    }

    public func completeOnboarding() {
        userDefaults.set(true, forKey: Self.onboardingDefaultsKey)
        isOnboardingPresented = false
    }

    public func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.notificationStatus = settings.authorizationStatus
            }
        }
    }

    public func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] _, _ in
            self?.refreshNotificationStatus()
        }
    }

    private func persistSchedule() {
        storage.save(schedule)
    }
}

public extension ScheduleManager {
    static func nextService(
        now: Date = Date(),
        calendar: Calendar = .current,
        storage: ParishScheduleStorage = ParishScheduleStorage(),
        userDefaults: UserDefaults = .standard
    ) -> ScheduledService? {
        var workingStorage = storage
        let schedule = workingStorage.load() ?? .empty
        if userDefaults.object(forKey: Self.angelusDefaultsKey) == nil {
            userDefaults.set(true, forKey: Self.angelusDefaultsKey)
        }
        let isAngelusEnabled = userDefaults.bool(forKey: Self.angelusDefaultsKey)
        return nextService(from: schedule, isAngelusEnabled: isAngelusEnabled, now: now, calendar: calendar)
    }

    static func nextService(
        from schedule: ParishSchedule,
        isAngelusEnabled: Bool,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ScheduledService? {
        var candidates: [ScheduledService] = []

        let nextMass = schedule.masses.compactMap { mass -> ScheduledService? in
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

            return ScheduledService(kind: .mass(mass), date: occurrence)
        }
        .min { $0.date < $1.date }

        if let nextMass {
            candidates.append(nextMass)
        }

        if isAngelusEnabled, let angelus = nextAngelus(after: now, calendar: calendar) {
            candidates.append(angelus)
        }

        return candidates.min { $0.date < $1.date }
    }

    private static func nextAngelus(after date: Date, calendar: Calendar) -> ScheduledService? {
        let hours = [6, 12, 18]
        let now = date

        let upcoming = hours.compactMap { hour -> Date? in
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            components.calendar = calendar

            return calendar.nextDate(
                after: now,
                matching: components,
                matchingPolicy: .nextTimePreservingSmallerComponents,
                repeatedTimePolicy: .first,
                direction: .forward
            )
        }
        .min()

        guard let occurrence = upcoming else { return nil }
        return ScheduledService(kind: .angelus, date: occurrence)
    }
}

extension ScheduleManager {
    static var placeholderService: ScheduledService {
        ScheduledService(kind: .mass(MassTime(weekday: .sunday, time: DateComponents(hour: 9, minute: 30), label: "Sunday Mass")), date: Date())
    }
}
