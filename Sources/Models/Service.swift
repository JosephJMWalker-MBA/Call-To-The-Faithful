import Foundation

struct Service: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let scheduledDate: Date

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }

    var formattedRelativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: scheduledDate, relativeTo: Date())
    }
}
