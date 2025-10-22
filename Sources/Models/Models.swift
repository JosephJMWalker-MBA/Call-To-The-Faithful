import Foundation

/// Represents a single Mass that can be scheduled throughout the week.
struct MassTime: Identifiable, Codable, Hashable {
    /// Weekday for the scheduled Mass.
    var weekday: Weekday

    /// Time of day for the scheduled Mass expressed using date components.
    var time: DateComponents

    /// Optional label that can help users differentiate multiple masses on the same day.
    var label: String?

    /// Stable identifier for SwiftUI lists and identifiable collections.
    var id: UUID

    init(id: UUID = UUID(), weekday: Weekday, time: DateComponents, label: String? = nil) {
        self.id = id
        self.weekday = weekday
        self.time = time
        self.label = label
    }

    /// Ordered representation of weekdays so the schedule can be sorted reliably.
    enum Weekday: Int, CaseIterable, Codable, Identifiable {
        case sunday = 1
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday

        var id: Int { rawValue }

        /// Readable label suitable for display in the user interface.
        var name: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
    }
}

/// Encapsulates the full Mass schedule for a parish.
struct ParishSchedule: Identifiable, Codable, Hashable {
    /// Name of the parish the schedule belongs to.
    var parishName: String

    /// All scheduled Mass times associated with the parish.
    var masses: [MassTime]

    /// Stable identifier for SwiftUI lists and identifiable collections.
    var id: UUID

    init(id: UUID = UUID(), parishName: String, masses: [MassTime] = []) {
        self.id = id
        self.parishName = parishName
        self.masses = masses
    }
}

extension ParishSchedule {
    /// Convenience value for initializing state or previews.
    static let empty = ParishSchedule(parishName: "")
}
