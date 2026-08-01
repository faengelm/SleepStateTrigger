import SwiftUI

struct ContentView: View {
    @ObservedObject private var sleepManager = SleepStateManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared

    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                stateSection
                setupSection
                testSection
                if !sleepManager.stateHistory.isEmpty {
                    historySection
                }
            }
            .navigationTitle("Sleep State Trigger")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAbout = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
        .task {
            sleepManager.loadSavedState()
            await notificationManager.requestAuthorization()
            await sleepManager.requestAuthorization()
        }
    }

    // MARK: - Current State

    private var stateSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: sleepManager.currentState.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(sleepManager.currentState.color)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(sleepManager.currentState.displayName)
                        .font(.title2.bold())

                    if let time = sleepManager.lastTransitionTime {
                        Text("Since \(time, format: .dateTime.hour().minute())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Waiting for Apple Watch sleep data")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Current Sleep State")
        }
    }

    // MARK: - Setup

    private var setupSection: some View {
        Section {
            PermissionRow(
                title: "HealthKit",
                icon: "heart.fill",
                iconColor: .red,
                isEnabled: sleepManager.isAuthorized
            ) {
                Task { await sleepManager.requestAuthorization() }
            }

            PermissionRow(
                title: "Notifications",
                icon: "bell.fill",
                iconColor: .orange,
                isEnabled: notificationManager.isAuthorized
            ) {
                Task { await notificationManager.requestAuthorization() }
            }

            HStack {
                Label {
                    Text("Background Monitoring")
                } icon: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(.blue)
                }
                Spacer()
                Text(sleepManager.isMonitoring ? "Active" : "Inactive")
                    .foregroundStyle(sleepManager.isMonitoring ? .green : .secondary)
                    .font(.subheadline)
            }
        } header: {
            Text("Setup")
        } footer: {
            Text("HealthKit reads sleep data written by Apple Watch. Background monitoring detects state changes while the app is closed.")
        }
    }

    // MARK: - Test Notifications

    private var testSection: some View {
        Section {
            Button {
                notificationManager.sendSleepNotification()
            } label: {
                Label("Send Sleep Notification", systemImage: "moon.fill")
            }

            Button {
                notificationManager.sendWakeNotification()
            } label: {
                Label("Send Wake Notification", systemImage: "sun.max.fill")
            }
        } header: {
            Text("Test Notifications")
        } footer: {
            Text("Tap to verify notifications work. Wear your Apple Watch to bed tonight to test real sleep detection.")
        }
    }

    // MARK: - History

    private var historySection: some View {
        Section {
            ForEach(sleepManager.stateHistory) { transition in
                HStack(spacing: 12) {
                    Image(systemName: transition.to.icon)
                        .foregroundStyle(transition.to.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(transition.from.displayName) \u{2192} \(transition.to.displayName)")
                            .font(.subheadline)
                        Text(transition.timestamp, format: .dateTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Recent Transitions")
        }
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            Spacer()
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Enable", action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
    }
}

#Preview {
    ContentView()
}
