import Foundation

struct QuickAction: Identifiable, Hashable {
    enum ActionType {
        case ringNow
        case scheduleNextMass
        case updateParishProfile
        case manageVolunteers
    }

    let id = UUID()
    let type: ActionType
    let title: String
    let subtitle: String
    let systemImageName: String
    let requiresConfirmation: Bool
    let confirmationPrompt: String
    let placeholderMessage: String
}

struct QuickActionFeedback: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}
