import Foundation

final class ScheduleManager: ObservableObject {
    @Published var selectedPreset: SchedulePreset
    @Published var massTime: DateComponents
    @Published var angelusTime: DateComponents
    @Published var isAngelusEnabled: Bool

    init(preset: SchedulePreset = .parish) {
        self.selectedPreset = preset
        self.massTime = preset.defaultMassTime
        self.angelusTime = preset.defaultAngelusTime
        self.isAngelusEnabled = true
    }

    func applyPreset(_ preset: SchedulePreset) {
        selectedPreset = preset
        massTime = preset.defaultMassTime
        angelusTime = preset.defaultAngelusTime
    }

    func nextService(after date: Date = Date()) -> Service? {
        var candidates: [Service] = []
        let calendar = Calendar.current

        if let nextMass = nextOccurrence(for: massTime, after: date, calendar: calendar) {
            candidates.append(Service(name: "Mass", scheduledDate: nextMass))
        }

        if isAngelusEnabled,
           let nextAngelus = nextOccurrence(for: angelusTime, after: date, calendar: calendar) {
            candidates.append(Service(name: "Angelus", scheduledDate: nextAngelus))
        }

        return candidates.sorted { $0.scheduledDate < $1.scheduledDate }.first
    }

    func updateMassTime(to date: Date, calendar: Calendar = .current) {
        massTime = calendar.dateComponents([.hour, .minute], from: date)
    }

    func updateAngelusTime(to date: Date, calendar: Calendar = .current) {
        angelusTime = calendar.dateComponents([.hour, .minute], from: date)
    }

    func date(for components: DateComponents, calendar: Calendar = .current) -> Date {
        let now = Date()
        let midnight = calendar.startOfDay(for: now)
        return calendar.date(bySettingHour: components.hour ?? 0,
                             minute: components.minute ?? 0,
                             second: components.second ?? 0,
                             of: midnight) ?? now
    }

    private func nextOccurrence(for components: DateComponents,
                                after date: Date,
                                calendar: Calendar) -> Date? {
        var targetComponents = components
        targetComponents.second = components.second ?? 0
        return calendar.nextDate(after: date,
                                 matching: targetComponents,
                                 matchingPolicy: .nextTime,
                                 direction: .forward)
    }
}
