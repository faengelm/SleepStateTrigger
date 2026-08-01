import SwiftUI

@main
struct SleepStateTriggerWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .onAppear {
                    WatchSleepMonitor.shared.start()
                }
        }
    }
}
