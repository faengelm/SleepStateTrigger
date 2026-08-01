import Foundation
import WatchConnectivity

/// Sends sleep state and transition events to the iPhone app, and receives
/// scene configuration changes from the iPhone.
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if activationState == .activated {
            sendState()
        }
    }

    // MARK: - Send State to iPhone

    /// Sends the full current snapshot (sleep state, HomeKit info) to the iPhone.
    /// Call this whenever state changes.
    func sendState() {
        guard WCSession.default.activationState == .activated else { return }

        let monitor = WatchSleepMonitor.shared
        let homeKit = HomeKitManager.shared

        var context: [String: Any] = [
            "sleepState": monitor.currentState.rawValue,
            "isMonitoring": monitor.isMonitoring,
            "availableScenes": homeKit.availableScenes,
            "homeKitStatus": homeKit.statusMessage,
            "source": "watch",
        ]

        if let time = monitor.lastTransitionTime {
            context["lastTransitionTime"] = time.timeIntervalSince1970
        }
        if let name = homeKit.homeName { context["homeName"] = name }
        if let name = homeKit.sleepSceneName { context["sleepSceneName"] = name }
        if let name = homeKit.wakeSceneName { context["wakeSceneName"] = name }
        if let result = homeKit.lastActionResult { context["lastActionResult"] = result }

        try? WCSession.default.updateApplicationContext(context)
    }

    // MARK: - Send Transition Event to iPhone

    /// Queues a transition event for delivery to the iPhone.  Uses
    /// `transferUserInfo` so events are delivered even if the iPhone app
    /// isn't running — perfect for building the overnight log.
    func sendTransition(from: String, to: String, timestamp: Date, sceneExecuted: String?) {
        guard WCSession.default.activationState == .activated else { return }

        var userInfo: [String: Any] = [
            "type": "transition",
            "id": UUID().uuidString,
            "from": from,
            "to": to,
            "timestamp": timestamp.timeIntervalSince1970,
        ]
        if let scene = sceneExecuted { userInfo["sceneExecuted"] = scene }

        WCSession.default.transferUserInfo(userInfo)
    }

    // MARK: - Receive Scene Config from iPhone

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard applicationContext["source"] as? String == "phone" else { return }

        DispatchQueue.main.async {
            let homeKit = HomeKitManager.shared
            homeKit.saveSleepScene(applicationContext["sleepSceneName"] as? String)
            homeKit.saveWakeScene(applicationContext["wakeSceneName"] as? String)
            self.sendState()
        }
    }

    // MARK: - Receive Commands from iPhone

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleCommand(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleCommand(userInfo)
    }

    private func handleCommand(_ info: [String: Any]) {
        guard let command = info["command"] as? String else { return }
        DispatchQueue.main.async {
            switch command {
            case "testSleepScene":
                HomeKitManager.shared.executeSleepScene()
            case "testWakeScene":
                HomeKitManager.shared.executeWakeScene()
            default:
                break
            }
        }
    }
}
