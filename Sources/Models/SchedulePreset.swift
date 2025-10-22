import Foundation

enum SchedulePreset: String, CaseIterable, Identifiable {
    case parish = "Parish"
    case monastery = "Monastery"
    case commuter = "Commuter"

    var id: String { rawValue }

    static var allPresets: [SchedulePreset] { Array(allCases) }

    var title: String { rawValue }

    var details: String { description }

    var description: String {
        switch self {
        case .parish:
            return "Great for traditional parish schedules with a mid-morning Mass."
        case .monastery:
            return "Earlier bells, suited to the rhythm of a monastic community."
        case .commuter:
            return "Evening-focused schedule for those who work during the day."
        }
    }

    var defaultMassTime: DateComponents {
        switch self {
        case .parish:
            return DateComponents(hour: 9, minute: 0)
        case .monastery:
            return DateComponents(hour: 6, minute: 30)
        case .commuter:
            return DateComponents(hour: 19, minute: 0)
        }
    }

    var defaultAngelusTime: DateComponents {
        switch self {
        case .parish:
            return DateComponents(hour: 12, minute: 0)
        case .monastery:
            return DateComponents(hour: 6, minute: 0)
        case .commuter:
            return DateComponents(hour: 18, minute: 0)
        }
    }

    var masses: [MassTime] {
        switch self {
        case .parish:
            return [
                MassTime(
                    weekday: .sunday,
                    time: DateComponents(hour: 9, minute: 0),
                    label: "Sunday Mass"
                ),
                MassTime(
                    weekday: .saturday,
                    time: DateComponents(hour: 17, minute: 0),
                    label: "Vigil Mass"
                )
            ]
        case .monastery:
            return [
                MassTime(
                    weekday: .monday,
                    time: DateComponents(hour: 6, minute: 30),
                    label: "Morning Office"
                ),
                MassTime(
                    weekday: .wednesday,
                    time: DateComponents(hour: 6, minute: 30),
                    label: "Community Mass"
                ),
                MassTime(
                    weekday: .friday,
                    time: DateComponents(hour: 6, minute: 30),
                    label: "First Friday"
                )
            ]
        case .commuter:
            return [
                MassTime(
                    weekday: .tuesday,
                    time: DateComponents(hour: 19, minute: 0),
                    label: "Weeknight Mass"
                ),
                MassTime(
                    weekday: .sunday,
                    time: DateComponents(hour: 18, minute: 0),
                    label: "Evening Service"
                )
            ]
        }
    }
}
