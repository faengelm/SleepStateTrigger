import Foundation
import HealthKit
import SwiftUI

class SleepStateManager: ObservableObject {
    static let shared = SleepStateManager()

    private let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    @Published var currentState: SleepState = .unknown
    @Published var lastTransitionTime: Date?
    @Published var isAuthorized = false
    @Published var isMonitoring = false
    @Published var stateHistory: [SleepStateTransition] = []

    // MARK: - Sleep State

    enum SleepState: String, Codable, Equatable {
        case awake, asleep, inBed, rem, core, deep, unknown

        var displayName: String {
            switch self {
            case .awake:   return "Awake"
            case .asleep:  return "Asleep"
            case .inBed:   return "In Bed"
            case .rem:     return "REM Sleep"
            case .core:    return "Core Sleep"
            case .deep:    return "Deep Sleep"
            case .unknown: return "Unknown"
            }
        }

        var icon: String {
            switch self {
            case .awake:   return "sun.max.fill"
            case .asleep:  return "moon.fill"
            case .inBed:   return "bed.double.fill"
            case .rem:     return "moon.stars.fill"
            case .core:    return "powersleep"
            case .deep:    return "moon.zzz.fill"
            case .unknown: return "questionmark.circle"
            }
        }

        var color: Color {
            switch self {
            case .awake:   return .orange
            case .asleep:  return .indigo
            case .inBed:   return .blue
            case .rem:     return .purple
            case .core:    return .cyan
            case .deep:    return .blue
            case .unknown: return .gray
            }
        }

        var isAsleep: Bool {
            switch self {
            case .asleep, .rem, .core, .deep: return true
            default: return false
            }
        }
    }

    // MARK: - Transition Record

    struct SleepStateTransition: Identifiable, Codable {
        let id: UUID
        let from: SleepState
        let to: SleepState
        let timestamp: Date

        init(from: SleepState, to: SleepState, timestamp: Date = .now) {
            self.id = UUID()
            self.from = from
            self.to = to
            self.timestamp = timestamp
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let sleepType = HKCategoryType(.sleepAnalysis)

        do {
            try await healthStore.requestAuthorization(toShare: [], read: [sleepType])
            await MainActor.run { self.isAuthorized = true }
            startMonitoring()
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard !isMonitoring else { return }

        let sleepType = HKCategoryType(.sleepAnalysis)

        healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { success, error in
            if let error { print("Background delivery error: \(error)") }
        }

        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completionHandler, _ in
            self?.fetchLatestSleepData()
            completionHandler()
        }

        healthStore.execute(query)
        observerQuery = query

        DispatchQueue.main.async { self.isMonitoring = true }

        fetchLatestSleepData()
    }

    func stopMonitoring() {
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
        }
        DispatchQueue.main.async { self.isMonitoring = false }
    }

    // MARK: - Data Fetching

    func fetchLatestSleepData() {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-86400),
            end: .now,
            options: .strictEndDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: 5,
            sortDescriptors: [sort]
        ) { [weak self] _, samples, _ in
            guard let latest = (samples as? [HKCategorySample])?.first else { return }
            let newState = Self.mapSleepValue(latest.value)
            DispatchQueue.main.async {
                self?.processStateChange(newState: newState, sampleDate: latest.endDate)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - State Processing

    private static func mapSleepValue(_ value: Int) -> SleepState {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:              return .inBed
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:   return .asleep
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:          return .core
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:          return .deep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:           return .rem
        case HKCategoryValueSleepAnalysis.awake.rawValue:               return .awake
        default:                                                        return .unknown
        }
    }

    private func processStateChange(newState: SleepState, sampleDate: Date) {
        let previousState = currentState
        guard newState != previousState else { return }

        let transition = SleepStateTransition(from: previousState, to: newState, timestamp: sampleDate)
        stateHistory.insert(transition, at: 0)
        if stateHistory.count > 50 {
            stateHistory = Array(stateHistory.prefix(50))
        }

        currentState = newState
        lastTransitionTime = sampleDate
        saveState()

        guard previousState != .unknown else { return }

        if newState.isAsleep && !previousState.isAsleep {
            NotificationManager.shared.sendSleepNotification()
        } else if !newState.isAsleep && previousState.isAsleep {
            NotificationManager.shared.sendWakeNotification()
        }
    }

    // MARK: - Persistence

    func loadSavedState() {
        if let raw = UserDefaults.standard.string(forKey: "lastSleepState"),
           let state = SleepState(rawValue: raw) {
            currentState = state
        }
        lastTransitionTime = UserDefaults.standard.object(forKey: "lastTransitionTime") as? Date
    }

    private func saveState() {
        UserDefaults.standard.set(currentState.rawValue, forKey: "lastSleepState")
        if let time = lastTransitionTime {
            UserDefaults.standard.set(time, forKey: "lastTransitionTime")
        }
    }
}
