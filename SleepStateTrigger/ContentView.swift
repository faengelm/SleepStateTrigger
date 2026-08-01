import SwiftUI

struct ContentView: View {
    @ObservedObject private var sync = ConnectivityManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared

    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                watchStateSection
                scenesSection
                if !sync.overnightLog.isEmpty {
                    overnightLogSection
                }
                testSection
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
            await notificationManager.requestAuthorization()
        }
    }

    // MARK: - Watch State

    private var watchStateSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: sync.stateIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(sync.stateColor)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(sync.stateDisplayName)
                        .font(.title2.bold())

                    if let time = sync.lastTransitionTime {
                        Text("Since \(time, format: .dateTime.hour().minute())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Waiting for Watch data")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)

            HStack {
                Label {
                    Text("Watch Monitoring")
                } icon: {
                    Image(systemName: "applewatch")
                        .foregroundStyle(.blue)
                }
                Spacer()
                if sync.isWatchPaired {
                    Text(sync.isMonitoring ? "Active" : "Inactive")
                        .foregroundStyle(sync.isMonitoring ? .green : .secondary)
                        .font(.subheadline)
                } else {
                    Text("Not Paired")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        } header: {
            Text("Current Sleep State")
        } footer: {
            Text("Sleep state is detected by the Apple Watch and synced to this device.")
        }
    }

    // MARK: - Scene Configuration

    private var scenesSection: some View {
        Section {
            // HomeKit status from watch
            HStack {
                Image(systemName: "house.fill")
                    .foregroundStyle(sync.homeName != nil ? .green : .orange)
                if let name = sync.homeName {
                    Text(name)
                        .font(.subheadline)
                } else {
                    Text(sync.homeKitStatus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if sync.availableScenes.isEmpty {
                Text("Scenes will appear once the Watch discovers your Home.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Sleep Scene", selection: Binding(
                    get: { sync.sleepSceneName },
                    set: { sync.updateSleepScene($0) }
                )) {
                    Text("None").tag(nil as String?)
                    ForEach(sync.availableScenes, id: \.self) { scene in
                        Text(scene).tag(scene as String?)
                    }
                }

                Picker("Wake Scene", selection: Binding(
                    get: { sync.wakeSceneName },
                    set: { sync.updateWakeScene($0) }
                )) {
                    Text("None").tag(nil as String?)
                    ForEach(sync.availableScenes, id: \.self) { scene in
                        Text(scene).tag(scene as String?)
                    }
                }
            }

            if let result = sync.lastActionResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Home Scenes")
        } footer: {
            Text("Choose which scenes run when sleep is detected and when you wake up. Changes sync to the Watch automatically.")
        }
    }

    // MARK: - Overnight Log

    private var overnightLogSection: some View {
        Section {
            ForEach(sync.overnightLog.prefix(20)) { event in
                HStack(spacing: 12) {
                    Image(systemName: ConnectivityManager.icon(for: event.to))
                        .foregroundStyle(ConnectivityManager.color(for: event.to))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(ConnectivityManager.displayName(for: event.from)) \u{2192} \(ConnectivityManager.displayName(for: event.to))")
                            .font(.subheadline)
                        HStack(spacing: 4) {
                            Text(event.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let scene = event.sceneExecuted {
                                Text("· \(scene)")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Button(role: .destructive) {
                sync.clearLog()
            } label: {
                Label("Clear Log", systemImage: "trash")
            }
        } header: {
            Text("Overnight Log")
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
            Text("Tap to verify notifications work on this device.")
        }
    }
}

#Preview {
    ContentView()
}
