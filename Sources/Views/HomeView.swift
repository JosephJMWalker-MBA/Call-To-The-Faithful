import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @StateObject private var bellRinger = BellRinger()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    private var nextService: Service? {
        scheduleManager.nextService()
    }

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            angelusToggle
            ringBellButton
            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle("Call to Prayer")
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingContainerView(isPresented: $showOnboarding)
                .environmentObject(scheduleManager)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            if let service = nextService {
                Text("Next Service")
                    .font(.headline)
                Text(service.name)
                    .font(.title3)
                    .bold()
                Text(service.formattedTime)
                    .font(.title2)
                Text(service.formattedRelativeDate)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("No services scheduled")
                    .font(.headline)
                Text("Add a time from onboarding to begin the call.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var angelusToggle: some View {
        Toggle(isOn: $scheduleManager.isAngelusEnabled) {
            VStack(alignment: .leading) {
                Text("Angelus Reminder")
                Text("Midday bell at \(scheduleManager.date(for: scheduleManager.angelusTime), style: .time)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle())
    }

    private var ringBellButton: some View {
        Button {
            bellRinger.ringBell()
        } label: {
            HStack {
                Image(systemName: "bell.fill")
                Text("Ring bell now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    HomeView()
        .environmentObject(ScheduleManager())
}
