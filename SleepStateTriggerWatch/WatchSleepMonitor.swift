import Foundation
import HealthKit
import SwiftUI
import UserNotifications

/// Monitors sleep analysis samples directly on the Watch's local HealthKit store.
/// Because the Watch writes sleep data locally (no iPhone sync needed), background
/// delivery fires immediately — even while the phone is locked.
final class WatchSleepMonitor: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = WatchSleepMonitor()

    private let healthStore = HKHealthStore()
    private let sleepType = HKCategoryType(.sleepAnalysis)
    private var observerQuery: HKObserverQuery?
    private var started = false

    @Published var currentState: SleepState = .unknown
    @Published var lastTransitionTime: Date?
    @Published var isMonitoring = false
    @Published var stateHistory: [SleepStateTransition] = []

    // MARK: - Types

    enum SleepState: String, Codable, Equatable {
        case awake, asleep, inBed, rem, core, deep, unknown

        var displayName: String {
            switch self {
            case .awake:   return "Awake"
            case .asleep:  return "Asleep"
            case .inBed:   return "In Bed"
            case .rem:     return "REM"
            case .core:    return "Core"
            case .deep:    return "Deep"
            case .unknown: return "—"
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

    struct SleepStateTransition: Identifiable {
        let id = UUID()
        let from: SleepState
        let to: SleepState
        let timestamp: Date
    }

    // MARK: - Init

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadSavedState()
    }

    /// Call on every app activation so HealthKit auth is re-requested if it was
    /// deferred (e.g. iPhone was locked when the Watch app first launched).
    func start() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[Watch] HealthKit not available")
            return
        }

        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: [sleepType])
                print("[Watch] HealthKit authorized")
            } catch {
                print("[Watch] HealthKit auth failed: \(error)")
                return
            }

            do {
                try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                print("[Watch] Notification auth failed: \(error)")
            }

            await fetchLatestSleep()

            if !started {
                started = true
                enableBackgroundDelivery()
                startObserving()
                await MainActor.run { isMonitoring = true }
            }
        }
    }

    // MARK: - Background Delivery

    private func enableBackgroundDelivery() {
        healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { success, error in
            if let error { print("[Watch] bg delivery error: \(error)") }
            else         { print("[Watch] bg delivery enabled: \(success)") }
        }
    }

    private func startObserving() {
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completion, error in
            guard error == nil else { completion(); return }
            completion()
            Task { await self?.fetchLatestSleep() }
        }
        observerQuery = query
        healthStore.execute(query)
    }

    // MARK: - Fetch & Process

    func fetchLatestSleep() async {
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-86400),
            end: .now,
            options: .strictEndDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: 5,
                sortDescriptors: [sort]
            ) { [weak self] _, samples, _ in
                if let latest = (samples as? [HKCategorySample])?.first {
                    let newState = Self.mapSleepValue(latest.value)
                    Task { @MainActor in
                        self?.processStateChange(newState: newState, sampleDate: latest.endDate)
                    }
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
    }

    private static func mapSleepValue(_ value: Int) -> SleepState {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:            return .inBed
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: return .asleep
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:       return .core
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:       return .deep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:        return .rem
        case HKCategoryValueSleepAnalysis.awake.rawValue:            return .awake
        default:                                                      return .unknown
        }
    }

    @MainActor
    private func processStateChange(newState: SleepState, sampleDate: Date) {
        let previousState = currentState
        guard newState != previousState else { return }

        let transition = SleepStateTransition(from: previousState, to: newState, timestamp: sampleDate)
        stateHistory.insert(transition, at: 0)
        if stateHistory.count > 20 { stateHistory = Array(stateHistory.prefix(20)) }

        currentState = newState
        lastTransitionTime = sampleDate
        saveState()

        guard previousState != .unknown else { return }

        if newState.isAsleep && !previousState.isAsleep {
            sendNotification(
                title: "Sleep Detected",
                body: "You've fallen asleep. Sweet dreams!"
            )
        } else if !newState.isAsleep && previousState.isAsleep {
            sendNotification(
                title: "Good Morning!",
                body: "You're waking up."
            )
        }
    }

    // MARK: - Notifications

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Persistence

    private func loadSavedState() {
        if let raw = UserDefaults.standard.string(forKey: "watchSleepState"),
           let state = SleepState(rawValue: raw) {
            currentState = state
        }
        lastTransitionTime = UserDefaults.standard.object(forKey: "watchTransitionTime") as? Date
    }

    private func saveState() {
        UserDefaults.standard.set(currentState.rawValue, forKey: "watchSleepState")
        if let time = lastTransitionTime {
            UserDefaults.standard.set(time, forKey: "watchTransitionTime")
        }
    }
}
