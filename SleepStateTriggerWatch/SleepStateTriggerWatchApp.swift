import SwiftUI

@main
struct SleepStateTriggerWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .onAppear {
                    HomeKitManager.shared.start()
                    WatchConnectivityManager.shared.start()
                    WatchSleepMonitor.shared.start()
                }
        }
    }
}
