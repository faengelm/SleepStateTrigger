import SwiftUI

@main
struct SleepStateTriggerWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .onAppear {
                    HomeKitManager.shared.start()
                    WatchSleepMonitor.shared.start()
                }
        }
    }
}
