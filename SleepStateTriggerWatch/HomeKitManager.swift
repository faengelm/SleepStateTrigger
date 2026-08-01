import Foundation
import HomeKit

/// Discovers Apple Home scenes and executes them on sleep/wake transitions.
/// Requires a Home Hub (Apple TV or HomePod) on the network.
class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate {
    static let shared = HomeKitManager()

    private var homeManager: HMHomeManager?
    private var pendingAction: (() -> Void)?

    @Published var isReady = false
    @Published var availableScenes: [String] = []
    @Published var sleepSceneName: String?
    @Published var wakeSceneName: String?
    @Published var lastActionResult: String?

    override init() {
        super.init()
        loadSavedScenes()
    }

    func start() {
        guard homeManager == nil else { return }
        homeManager = HMHomeManager()
        homeManager?.delegate = self
    }

    // MARK: - HMHomeManagerDelegate

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        DispatchQueue.main.async {
            self.isReady = true
            self.refreshScenes()
            self.pendingAction?()
            self.pendingAction = nil
        }
    }

    // MARK: - Scene Discovery

    func refreshScenes() {
        guard let home = homeManager?.homes.first else {
            availableScenes = []
            return
        }

        availableScenes = home.actionSets.map(\.name).sorted()

        // Auto-match on first run if user hasn't selected yet
        if sleepSceneName == nil {
            let match = firstScene(matching: ["Goodnight", "Good Night", "Sleep", "Bedtime", "Night"])
            if match != nil { saveSleepScene(match) }
        }
        if wakeSceneName == nil {
            let match = firstScene(matching: ["Good Morning", "Morning", "Wake", "Rise", "Sunrise"])
            if match != nil { saveWakeScene(match) }
        }
    }

    private func firstScene(matching keywords: [String]) -> String? {
        for keyword in keywords {
            if let match = availableScenes.first(where: { $0.localizedCaseInsensitiveContains(keyword) }) {
                return match
            }
        }
        return nil
    }

    // MARK: - Scene Execution

    func executeSleepScene() {
        guard let name = sleepSceneName else {
            print("[HomeKit] No sleep scene configured")
            return
        }
        if isReady {
            executeScene(named: name)
        } else {
            pendingAction = { [weak self] in self?.executeScene(named: name) }
        }
    }

    func executeWakeScene() {
        guard let name = wakeSceneName else {
            print("[HomeKit] No wake scene configured")
            return
        }
        if isReady {
            executeScene(named: name)
        } else {
            pendingAction = { [weak self] in self?.executeScene(named: name) }
        }
    }

    private func executeScene(named name: String) {
        guard let home = homeManager?.homes.first,
              let actionSet = home.actionSets.first(where: { $0.name == name }) else {
            DispatchQueue.main.async {
                self.lastActionResult = "Scene '\(name)' not found"
            }
            print("[HomeKit] Scene '\(name)' not found")
            return
        }

        home.executeActionSet(actionSet) { error in
            DispatchQueue.main.async {
                if let error {
                    self.lastActionResult = "Error: \(error.localizedDescription)"
                    print("[HomeKit] Error executing '\(name)': \(error)")
                } else {
                    self.lastActionResult = "'\(name)' executed"
                    print("[HomeKit] Executed '\(name)' successfully")
                }
            }
        }
    }

    // MARK: - Persistence

    func saveSleepScene(_ name: String?) {
        sleepSceneName = name
        UserDefaults.standard.set(name, forKey: "sleepSceneName")
    }

    func saveWakeScene(_ name: String?) {
        wakeSceneName = name
        UserDefaults.standard.set(name, forKey: "wakeSceneName")
    }

    private func loadSavedScenes() {
        sleepSceneName = UserDefaults.standard.string(forKey: "sleepSceneName")
        wakeSceneName = UserDefaults.standard.string(forKey: "wakeSceneName")
    }
}
