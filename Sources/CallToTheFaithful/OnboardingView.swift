import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager
    @State private var step: Int = 0
    @State private var selectedPreset: SchedulePreset?
    @State private var editableMasses: [MassTime] = []

    private let presets = SchedulePreset.allPresets

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $step) {
                presetsStep
                    .tag(0)
                customizeStep
                    .tag(1)
                permissionsStep
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

            HStack {
                if step > 0 {
                    Button("Back") {
                        withAnimation { step -= 1 }
                    }
                }
                Spacer()
                Button(primaryButtonTitle) {
                    handlePrimaryAction()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("Welcome")
        .onAppear(perform: prepareInitialState)
    }

    private var presetsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a starting schedule")
                .font(.title3)
                .bold()
            Text("Pick the preset that best reflects your parish rhythm. You can fine-tune it next.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(presets) { preset in
                Button {
                    apply(preset)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.title)
                                .font(.headline)
                            Text(preset.details)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if preset.id == selectedPreset?.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(preset.id == selectedPreset?.id ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customizeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fine-tune service times")
                .font(.title3)
                .bold()
            Text("Adjust the bell schedule to match your community's needs. These times are saved to your device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if editableMasses.isEmpty {
                Text("Add services from the previous step to begin customizing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(Array(editableMasses.enumerated()), id: \.element.id) { index, mass in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mass.weekday.name)
                                    .font(.headline)
                                if let label = mass.label, !label.isEmpty {
                                    Text(label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            DatePicker(
                                "",
                                selection: bindingForMass(at: index),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stay notified")
                .font(.title3)
                .bold()
            Text("Allow notifications so we can gently tap your wrist before each bell rings.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label(statusDescription, systemImage: statusImageName)
                    .font(.headline)

                Button("Enable notifications") {
                    scheduleManager.requestNotificationPermissions()
                }
                .buttonStyle(.bordered)
            }

            Toggle(isOn: $scheduleManager.isAngelusEnabled) {
                Text("Angelus reminders")
            }
            Text("We'll ring at 6am, noon, and 6pm when enabled, alongside your Mass schedule.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case 0, 1:
            return "Next"
        default:
            return "Get started"
        }
    }

    private func handlePrimaryAction() {
        switch step {
        case 0:
            if selectedPreset == nil && editableMasses.isEmpty, let firstPreset = presets.first {
                apply(firstPreset)
            }
            withAnimation { step = 1 }
        case 1:
            scheduleManager.updateMasses(editableMasses)
            withAnimation { step = 2 }
        default:
            scheduleManager.completeOnboarding()
        }
    }

    private func prepareInitialState() {
        editableMasses = scheduleManager.schedule.masses
        if let matchingPreset = presets.first(where: { $0.masses == scheduleManager.schedule.masses }) {
            selectedPreset = matchingPreset
        }
        if editableMasses.isEmpty, let firstPreset = presets.first {
            apply(firstPreset)
        }
        scheduleManager.refreshNotificationStatus()
    }

    private func apply(_ preset: SchedulePreset) {
        selectedPreset = preset
        scheduleManager.applyPreset(preset)
        editableMasses = scheduleManager.schedule.masses
    }

    private func time(from mass: MassTime) -> Date {
        let hour = mass.time.hour ?? 9
        let minute = mass.time.minute ?? 0
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private func bindingForMass(at index: Int) -> Binding<Date> {
        Binding(
            get: {
                guard editableMasses.indices.contains(index) else { return Date() }
                return time(from: editableMasses[index])
            },
            set: { newValue in
                guard editableMasses.indices.contains(index) else { return }
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                editableMasses[index].time = DateComponents(hour: components.hour, minute: components.minute)
            }
        )
    }

    private var statusDescription: String {
        switch scheduleManager.notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications are enabled"
        case .denied:
            return "Notifications are disabled"
        case .notDetermined:
            return "Notifications pending approval"
        @unknown default:
            return "Notifications status unknown"
        }
    }

    private var statusImageName: String {
        switch scheduleManager.notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined:
            return "bell"
        @unknown default:
            return "bell"
        }
    }
}
