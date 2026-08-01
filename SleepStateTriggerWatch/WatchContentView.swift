import SwiftUI

struct WatchContentView: View {
    @ObservedObject private var monitor = WatchSleepMonitor.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: monitor.currentState.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(monitor.currentState.color)

                Text(monitor.currentState.displayName)
                    .font(.title3.bold())

                if let time = monitor.lastTransitionTime {
                    Text("Since \(time, format: .dateTime.hour().minute())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Circle()
                        .fill(monitor.isMonitoring ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(monitor.isMonitoring ? "Monitoring" : "Inactive")
                        .font(.caption)
                }

                if !monitor.stateHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recent")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

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
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Sleep")
    }
}
