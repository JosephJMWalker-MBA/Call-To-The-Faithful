import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var scheduleManager: ScheduleManager

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        List {
            Section("Next Service") {
                if let nextService = scheduleManager.nextService {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(nextService.mass.label ?? nextService.mass.weekday.name)
                            .font(.headline)
                        Text(dateFormatter.string(from: nextService.date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(timeFormatter.string(from: nextService.date))
                            .font(.title3)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Add services to your schedule to see what is coming up next.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Angelus") {
                Toggle(isOn: $scheduleManager.isAngelusEnabled) {
                    Text("Angelus Reminders")
                }
                Text("Keep the Angelus ringing at its traditional hours when enabled.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    scheduleManager.ringBellNow()
                } label: {
                    Label("Ring bell now", systemImage: "bell.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listStyle(.carousel)
        .navigationTitle("Call to Faithful")
        .onAppear {
            scheduleManager.refreshUpcomingService()
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(ScheduleManager())
        }
    }
}
#endif
