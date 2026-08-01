import Foundation
import WatchConnectivity
import SwiftUI

/// Receives live state and transition events from the Apple Watch via
/// WatchConnectivity. Sends scene configuration changes back to the watch.
class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()

    // MARK: - Watch State (received)

    @Published var currentSleepState: String = "unknown"
    @Published var lastTransitionTime: Date?
    @Published var isMonitoring = false
    @Published var homeName: String?
    @Published var availableScenes: [String] = []
    @Published var sleepSceneName: String?
    @Published var wakeSceneName: String?
    @Published var lastActionResult: String?
    @Published var homeKitStatus: String = "Waiting for Watch"
    @Published var isWatchPaired = false
    @Published var overnightLog: [TransitionEvent] = []

    struct TransitionEvent: Identifiable, Codable {
        let id: UUID
        let from: String
        let to: String
        let timestamp: Date
        let sceneExecuted: String?
    }

    // MARK: - Display Helpers

    var stateDisplayName: String { Self.displayName(for: currentSleepState) }
    var stateIcon: String { Self.icon(for: currentSleepState) }
    var stateColor: Color { Self.color(for: currentSleepState) }

    // MARK: - Init

    override init() {
        super.init()
        loadLog()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate (required)

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
        }
        // Load any existing application context from the watch
        if activationState == .activated {
            let ctx = session.receivedApplicationContext
            if !ctx.isEmpty { applyWatchContext(ctx) }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    // MARK: - Receive State from Watch

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyWatchContext(applicationContext)
    }

    private func applyWatchContext(_ ctx: [String: Any]) {
        DispatchQueue.main.async {
            self.currentSleepState = ctx["sleepState"] as? String ?? "unknown"
            if let ts = ctx["lastTransitionTime"] as? Double {
                self.lastTransitionTime = Date(timeIntervalSince1970: ts)
            }
            self.isMonitoring = ctx["isMonitoring"] as? Bool ?? false
            self.homeName = ctx["homeName"] as? String
            self.availableScenes = ctx["availableScenes"] as? [String] ?? []
            self.sleepSceneName = ctx["sleepSceneName"] as? String
            self.wakeSceneName = ctx["wakeSceneName"] as? String
            self.lastActionResult = ctx["lastActionResult"] as? String
            self.homeKitStatus = ctx["homeKitStatus"] as? String ?? "Unknown"
        }
    }

    // MARK: - Receive Transition Events from Watch

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard userInfo["type"] as? String == "transition" else { return }

        let event = TransitionEvent(
            id: UUID(uuidString: userInfo["id"] as? String ?? "") ?? UUID(),
            from: userInfo["from"] as? String ?? "unknown",
            to: userInfo["to"] as? String ?? "unknown",
            timestamp: Date(timeIntervalSince1970: userInfo["timestamp"] as? Double ?? 0),
            sceneExecuted: userInfo["sceneExecuted"] as? String
        )

        DispatchQueue.main.async {
            self.overnightLog.insert(event, at: 0)
            if self.overnightLog.count > 100 {
                self.overnightLog = Array(self.overnightLog.prefix(100))
            }
            self.saveLog()
        }
    }

    // MARK: - Send Scene Config to Watch

    func updateSleepScene(_ name: String?) {
        sleepSceneName = name
        sendSceneConfig()
    }

    func updateWakeScene(_ name: String?) {
        wakeSceneName = name
        sendSceneConfig()
    }

    private func sendSceneConfig() {
        guard WCSession.default.activationState == .activated else { return }
        var context: [String: Any] = ["source": "phone"]
        if let sleep = sleepSceneName { context["sleepSceneName"] = sleep }
        if let wake = wakeSceneName { context["wakeSceneName"] = wake }
        try? WCSession.default.updateApplicationContext(context)
    }

    // MARK: - Log Persistence

    func clearLog() {
        overnightLog.removeAll()
        saveLog()
    }

    private func saveLog() {
        if let data = try? JSONEncoder().encode(overnightLog) {
            UserDefaults.standard.set(data, forKey: "overnightLog")
        }
    }

    private func loadLog() {
        if let data = UserDefaults.standard.data(forKey: "overnightLog"),
           let log = try? JSONDecoder().decode([TransitionEvent].self, from: data) {
            overnightLog = log
        }
    }

    // MARK: - State Mapping

    static func displayName(for state: String) -> String {
        switch state {
        case "awake":   return "Awake"
        case "asleep":  return "Asleep"
        case "inBed":   return "In Bed"
        case "rem":     return "REM Sleep"
        case "core":    return "Core Sleep"
        case "deep":    return "Deep Sleep"
        default:        return "Unknown"
        }
    }

    static func icon(for state: String) -> String {
        switch state {
        case "awake":   return "sun.max.fill"
        case "asleep":  return "moon.fill"
        case "inBed":   return "bed.double.fill"
        case "rem":     return "moon.stars.fill"
        case "core":    return "powersleep"
        case "deep":    return "moon.zzz.fill"
        default:        return "questionmark.circle"
        }
    }

    static func color(for state: String) -> Color {
        switch state {
        case "awake":   return .orange
        case "asleep":  return .indigo
        case "inBed":   return .blue
        case "rem":     return .purple
        case "core":    return .cyan
        case "deep":    return .blue
        default:        return .gray
        }
    }
}
