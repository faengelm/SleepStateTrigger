import SwiftUI

struct ContentView: View {
    @ObservedObject private var sync = ConnectivityManager.shared

    @State private var showingAbout = false
    @State private var sleepTestSent = false
    @State private var wakeTestSent = false
    @State private var sleepShortcutRan = false
    @State private var wakeShortcutRan = false

    var body: some View {
        NavigationStack {
            List {
                watchStateSection
                scenesSection
                testSection
                shortcutsSection
                if !sync.overnightLog.isEmpty {
                    overnightLogSection
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

    // MARK: - Shortcuts

    private var shortcutsSection: some View {
        Section {
            Button {
                if let url = URL(string: "https://www.icloud.com/shortcuts/9b849c32c61d45bca90066cd1978de56") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Install Focus Shortcut", systemImage: "square.and.arrow.down")
            }

            TextField("Sleep Input (e.g., Sleep)", text: Binding(
                get: { sync.sleepShortcutInput },
                set: { sync.updateSleepShortcutInput($0) }
            ))
            .autocorrectionDisabled()

            TextField("Wake Input (e.g., Off)", text: Binding(
                get: { sync.wakeShortcutInput },
                set: { sync.updateWakeShortcutInput($0) }
            ))
            .autocorrectionDisabled()

            Button {
                sync.runShortcut(input: sync.sleepShortcutInput)
                showSent($sleepShortcutRan)
            } label: {
                HStack {
                    Label("Run Sleep Shortcut", systemImage: "moon.fill")
                    Spacer()
                    if sleepShortcutRan {
                        Text("Ran")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }
            }
            .disabled(sync.sleepShortcutInput.isEmpty)

            Button {
                sync.runShortcut(input: sync.wakeShortcutInput)
                showSent($wakeShortcutRan)
            } label: {
                HStack {
                    Label("Run Wake Shortcut", systemImage: "sun.max.fill")
                    Spacer()
                    if wakeShortcutRan {
                        Text("Ran")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }
            }
            .disabled(sync.wakeShortcutInput.isEmpty)

            Button {
                if let url = URL(string: "shortcuts://") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Shortcuts App", systemImage: "arrow.up.forward.app")
            }
        } header: {
            Text("Shortcuts")
        } footer: {
            Text("Install the Focus shortcut, enter its name, and set the input to pass for each transition. The shortcut runs automatically when a sleep/wake transition is received from the Watch.")
        }
    }

    // MARK: - Test Scenes

    private var testSection: some View {
        Section {
            Button {
                sync.testSleepScene()
                showSent($sleepTestSent)
            } label: {
                HStack {
                    Label("Test Sleep Scene", systemImage: "moon.fill")
                    Spacer()
                    if sleepTestSent {
                        Text("Sent")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }
            }
            .disabled(sync.sleepSceneName == nil)

            Button {
                sync.testWakeScene()
                showSent($wakeTestSent)
            } label: {
                HStack {
                    Label("Test Wake Scene", systemImage: "sun.max.fill")
                    Spacer()
                    if wakeTestSent {
                        Text("Sent")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }
            }
            .disabled(sync.wakeSceneName == nil)
        } header: {
            Text("Test")
        } footer: {
            Text("Sends a command to the Watch to execute the scene immediately.")
        }
    }

    private func showSent(_ flag: Binding<Bool>) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { flag.wrappedValue = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { flag.wrappedValue = false }
        }
    }
}

#Preview {
    ContentView()
}
