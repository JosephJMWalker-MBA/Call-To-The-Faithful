import SwiftUI

@main
struct CallToTheFaithfulApp: App {
    @StateObject private var viewModel = QuickActionViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                QuickActionsView(viewModel: viewModel)
            }
        }
    }
}
