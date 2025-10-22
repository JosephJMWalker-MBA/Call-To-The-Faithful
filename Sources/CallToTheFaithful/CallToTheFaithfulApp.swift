import SwiftUI

@main
struct CallToTheFaithfulApp: App {
    @StateObject private var scheduleManager = ScheduleManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(scheduleManager)
            .sheet(
                isPresented: Binding(
                    get: { scheduleManager.isOnboardingPresented },
                    set: { scheduleManager.isOnboardingPresented = $0 }
                )
            ) {
                NavigationStack {
                    OnboardingView()
                }
                .environmentObject(scheduleManager)
            }
        }
    }
}
