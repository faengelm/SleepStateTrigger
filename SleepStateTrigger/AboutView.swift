import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var sync = ConnectivityManager.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.indigo)

                        Text("Sleep State Trigger")
                            .font(.title2.bold())

                        Text("Smart home automation\npowered by Apple Watch sleep tracking")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                Section("iPhone App") {
                    row("Version", value: appVersion)
                    row("Build", value: buildNumber)
                }

                Section("Watch App") {
                    row("Version", value: sync.watchVersion ?? "—")
                    row("Build", value: sync.watchBuild ?? "—")
                }

                Section {
                    Text("\u{00A9} 2026 Technology4Seniors LLC.\nAll rights reserved.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AboutView()
}
