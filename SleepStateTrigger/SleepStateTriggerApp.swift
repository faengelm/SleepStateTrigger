import SwiftUI

@main
struct SleepStateTriggerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    ConnectivityManager.shared.start()
                }
        }
    }
}
