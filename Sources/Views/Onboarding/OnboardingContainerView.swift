import SwiftUI
import UserNotifications

struct OnboardingContainerView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @Binding var isPresented: Bool
    @State private var selection: Int = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $selection) {
                PresetSelectionView()
                    .environmentObject(scheduleManager)
                    .tag(0)
                TimeEditingView()
                    .environmentObject(scheduleManager)
                    .tag(1)
                PermissionRequestView(onFinish: finishOnboarding)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

            HStack {
                if selection > 0 {
                    Button("Back") {
                        withAnimation { selection -= 1 }
                    }
                }

                Spacer()

                if selection < 2 {
                    Button("Next") {
                        withAnimation { selection += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
        isPresented = false
    }
}

private struct PresetSelectionView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose a schedule")
                .font(.headline)
            Text("Pick the rhythm that most closely matches your community. You can fine-tune the times next.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Picker("Schedule preset", selection: $scheduleManager.selectedPreset) {
                ForEach(SchedulePreset.allCases) { preset in
                    VStack(alignment: .leading) {
                        Text(preset.rawValue)
                            .font(.body)
                        Text(preset.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .tag(preset)
                }
            }
            .onChange(of: scheduleManager.selectedPreset) { _, newValue in
                scheduleManager.applyPreset(newValue)
            }
            .labelsHidden()
            .frame(maxHeight: .infinity)
        }
        .padding()
    }
}

private struct TimeEditingView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private var massBinding: Binding<Date> {
        Binding<Date>(
            get: { scheduleManager.date(for: scheduleManager.massTime) },
            set: { scheduleManager.updateMassTime(to: $0) }
        )
    }

    private var angelusBinding: Binding<Date> {
        Binding<Date>(
            get: { scheduleManager.date(for: scheduleManager.angelusTime) },
            set: { scheduleManager.updateAngelusTime(to: $0) }
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Fine-tune the times")
                .font(.headline)
            Text("Adjust the Mass and Angelus bells to match your chapel schedule.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("Mass", selection: massBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                Toggle("Enable Angelus", isOn: $scheduleManager.isAngelusEnabled)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Angelus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("Angelus", selection: angelusBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .disabled(!scheduleManager.isAngelusEnabled)
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding()
    }
}

private struct PermissionRequestView: View {
    var onFinish: () -> Void
    @State private var permissionStatus: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Stay in sync")
                .font(.headline)
            Text("Enable notifications so the watch can tap you when it is time to ring the bells.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if !permissionStatus.isEmpty {
                Text(permissionStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("Allow Notifications") {
                requestNotifications()
            }
            .buttonStyle(.bordered)

            Button("Start ringing") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error {
                    permissionStatus = "Error: \(error.localizedDescription)"
                } else {
                    permissionStatus = granted ? "Notifications enabled" : "Notifications declined"
                }
            }
        }
    }
}

#Preview {
    OnboardingContainerView(isPresented: .constant(true))
        .environmentObject(ScheduleManager())
}
