import Foundation
import SwiftUI

@MainActor
final class QuickActionViewModel: ObservableObject {
    @Published private(set) var actions: [QuickAction]
    @Published private var pendingConfirmation: QuickAction?
    @Published var feedback: QuickActionFeedback?

    var isConfirmationDialogPresented: Bool {
        pendingConfirmation != nil
    }

    init(actions: [QuickAction] = QuickActionViewModel.defaultActions) {
        self.actions = actions
    }

    func trigger(_ action: QuickAction) {
        if action.requiresConfirmation {
            pendingConfirmation = action
        } else {
            feedback = QuickActionFeedback(action: action)
        }
    }

    func confirmPendingAction() {
        guard let action = pendingConfirmation else { return }
        pendingConfirmation = nil
        feedback = QuickActionFeedback(action: action)
    }

    func cancelPendingAction() {
        pendingConfirmation = nil
    }

    func dismissFeedback() {
        feedback = nil
    }

    var confirmationPrompt: String {
        pendingConfirmation?.confirmationPrompt ?? ""
    }

    var confirmationTitle: String {
        pendingConfirmation?.title ?? ""
    }

    var pendingAction: QuickAction? {
        pendingConfirmation
    }
}

private extension QuickActionViewModel {
    static var defaultActions: [QuickAction] {
        [
            QuickAction(
                type: .ringNow,
                title: "Ring Bells",
                subtitle: "Alert parishioners immediately",
                systemImageName: "bell.and.waves.left.and.right",
                requiresConfirmation: true,
                confirmationPrompt: "Are you sure you want to ring the bells now?",
                placeholderMessage: "Bell ringing will be available once the call service is connected."
            ),
            QuickAction(
                type: .scheduleNextMass,
                title: "Schedule Next Mass",
                subtitle: "Set reminder for the next liturgy",
                systemImageName: "calendar.badge.plus",
                requiresConfirmation: false,
                confirmationPrompt: "",
                placeholderMessage: "Scheduling is coming soon. For now, keep your parish calendar handy."
            ),
            QuickAction(
                type: .updateParishProfile,
                title: "Update Profile",
                subtitle: "Refresh parish details",
                systemImageName: "building.columns",
                requiresConfirmation: false,
                confirmationPrompt: "",
                placeholderMessage: "Parish profile import is on the roadmap. Please manage updates on the web for now."
            ),
            QuickAction(
                type: .manageVolunteers,
                title: "Manage Volunteers",
                subtitle: "Coordinate bell ringers",
                systemImageName: "person.3.sequence",
                requiresConfirmation: true,
                confirmationPrompt: "Send a heads-up to your bell ringers?",
                placeholderMessage: "Volunteer notifications will be added in a future release."
            )
        ]
    }
}
