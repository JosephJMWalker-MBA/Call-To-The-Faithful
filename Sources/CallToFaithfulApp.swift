import SwiftUI

@main
struct CallToFaithfulApp: App {
    @StateObject private var scheduleManager = ScheduleManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(scheduleManager)
        }
    }
}
