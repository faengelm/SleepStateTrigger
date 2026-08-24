import SwiftUI

struct WatchContentView: View {
    @ObservedObject private var monitor = WatchSleepMonitor.shared
    @ObservedObject private var homeKit = HomeKitManager.shared

    var body: some View {
        NavigationStack {
            List {
                stateSection
                scenesSection
                testSection
                diagnosticSection
                if !monitor.stateHistory.isEmpty {
                    historySection
                }
                aboutSection
            }
            .navigationTitle("Sleep")
        }
    }

    // MARK: - Current State

    private var stateSection: some View {
        Section {
            HStack {
                Image(systemName: monitor.currentState.icon)
                    .font(.title2)
                    .foregroundStyle(monitor.currentState.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(monitor.currentState.displayName)
                        .font(.headline)
                    if let time = monitor.lastTransitionTime {
                        Text("Since \(time, format: .dateTime.hour().minute())")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Circle()
                    .fill(monitor.isMonitoring ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(monitor.isMonitoring ? "Monitoring" : "Inactive")
                    .font(.caption)
            }
        }
    }

    // MARK: - Scene Configuration

    private var scenesSection: some View {
        Section {
            // HomeKit status
            HStack {
                Image(systemName: "house.fill")
                    .foregroundStyle(homeKit.isReady ? .green : .orange)
                if let name = homeKit.homeName {
                    Text(name)
                        .font(.caption)
                } else {
                    Text(homeKit.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if homeKit.availableScenes.isEmpty && homeKit.isReady {
                Text("No scenes found in your Home. Create scenes in the Home app first.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !homeKit.availableScenes.isEmpty {
                Picker("Sleep", selection: Binding(
                    get: { homeKit.sleepSceneName },
                    set: { homeKit.saveSleepScene($0) }
                )) {
                    Text("None").tag(nil as String?)
                    ForEach(homeKit.availableScenes, id: \.self) { scene in
                        Text(scene).tag(scene as String?)
                    }
                }

                Picker("Wake", selection: Binding(
                    get: { homeKit.wakeSceneName },
                    set: { homeKit.saveWakeScene($0) }
                )) {
                    Text("None").tag(nil as String?)
                    ForEach(homeKit.availableScenes, id: \.self) { scene in
                        Text(scene).tag(scene as String?)
                    }
                }
            }

            if let result = homeKit.lastActionResult {
                Text(result)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Home Scenes")
        }
    }

    // MARK: - Test

    private var testSection: some View {
        Section {
            Button {
                homeKit.executeSleepScene()
            } label: {
                Label("Test Sleep Scene", systemImage: "moon.fill")
            }
            .disabled(homeKit.sleepSceneName == nil)

            Button {
                homeKit.executeWakeScene()
            } label: {
                Label("Test Wake Scene", systemImage: "sun.max.fill")
            }
            .disabled(homeKit.wakeSceneName == nil)
        } header: {
            Text("Test")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
            Text("v\(version) (\(build))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Diagnostics

    private var diagnosticSection: some View {
        Section {
            Button {
                Task { await monitor.fetchLatestSleep() }
            } label: {
                Label("Check Now", systemImage: "arrow.clockwise")
            }

            if let state = monitor.lastSampleState {
                HStack {
                    Text("Latest Sample")
                        .font(.caption2)
                    Spacer()
                    Text(state)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let start = monitor.lastSampleStart,
               let end = monitor.lastSampleEnd {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Start")
                            .font(.caption2)
                        Spacer()
                        Text(start, format: .dateTime.hour().minute().second())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("End")
                            .font(.caption2)
                        Spacer()
                        Text(end, format: .dateTime.hour().minute().second())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let source = monitor.lastSampleSource {
                HStack {
                    Text("Source")
                        .font(.caption2)
                    Spacer()
                    Text(source)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let queryTime = monitor.lastQueryTime {
                HStack {
                    Text("Checked")
                        .font(.caption2)
                    Spacer()
                    Text(queryTime, format: .dateTime.hour().minute().second())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("Observer Fires")
                    .font(.caption2)
                Spacer()
                Text("\(monitor.observerFireCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Samples (24h)")
                    .font(.caption2)
                Spacer()
                Text("\(monitor.sampleCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("HealthKit Diagnostics")
        }
    }

    // MARK: - History

    private var historySection: some View {
        Section {
            ForEach(monitor.stateHistory.prefix(5)) { t in
                HStack {
                    Image(systemName: t.to.icon)
                        .font(.caption2)
                        .foregroundStyle(t.to.color)
                    Text(t.to.displayName)
                        .font(.caption2)
                    Spacer()
                    Text(t.timestamp, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Recent")
        }
    }
}
