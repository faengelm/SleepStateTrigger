# Sleep State Trigger

An iOS + watchOS app that detects sleep/wake transitions using Apple Watch health data and automatically triggers Apple Home scenes — turning off lights when you fall asleep and turning them on when you wake up.

## Features

### Apple Watch App
- **Real-time sleep detection** — Reads sleep analysis data directly from the Watch's local HealthKit store using `HKObserverQuery` with immediate background delivery
- **Automatic HomeKit scene execution** — Runs your chosen "Good Night" scene when sleep is detected and "Good Morning" scene when you wake up
- **Scene configuration** — Pick sleep and wake scenes from all available scenes in your Apple Home
- **Auto-matching** — Automatically selects scenes with common names (Goodnight, Good Morning, Sleep, Wake, etc.) on first run
- **On-watch notifications** — Displays banners when sleep/wake transitions are detected
- **Transition history** — Shows recent state changes with timestamps

### iPhone Companion App
- **Live dashboard** — Displays the current sleep state synced from the Apple Watch in real time
- **Remote scene configuration** — Choose sleep and wake scenes from the iPhone; changes sync to the Watch automatically
- **Overnight log** — Records all sleep transitions throughout the night with timestamps and which scenes were executed
- **Test notifications** — Verify notification delivery on the iPhone
- **Watch pairing status** — Shows whether the Apple Watch is paired and actively monitoring

### Sleep States Detected
| State | Description |
|-------|-------------|
| Awake | User is awake |
| In Bed | User is in bed but not yet asleep |
| Asleep | Asleep (unspecified stage) |
| REM | REM sleep stage |
| Core | Core sleep stage |
| Deep | Deep sleep stage |

## Why the Watch?

Apple's privacy model blocks HealthKit background delivery on a locked iPhone — which means an iPhone-only app can't detect sleep transitions overnight. The Apple Watch writes sleep data to its **local** HealthKit store and delivers background updates immediately, even while the screen is off. This makes the Watch the only reliable way to trigger actions based on real-time sleep state.

## Requirements

- **iPhone** running iOS 17.0 or later
- **Apple Watch** running watchOS 10.0 or later (with sleep tracking enabled)
- **Apple Home Hub** (Apple TV or HomePod) on your network for HomeKit scene execution
- **Xcode 15+** to build from source
- Apple Developer account (for on-device testing with HealthKit and HomeKit)

## Setup

### 1. Build & Install

1. Open `SleepStateTrigger.xcodeproj` in Xcode
2. Set your development team in **Signing & Capabilities** for both the iOS and watchOS targets
3. Build and run on your paired iPhone — the Watch app installs automatically

### 2. Grant Permissions

On the **Apple Watch**, the app will request:
- **HealthKit** — Read access to sleep analysis data
- **HomeKit** — Access to your Apple Home for scene discovery and execution
- **Notifications** — For sleep/wake transition alerts

On the **iPhone**, the app will request:
- **Notifications** — For test notification delivery

### 3. Configure Scenes

1. Open the **Home** app and ensure you have scenes set up (e.g., "Good Night" and "Good Morning")
2. The Watch app auto-matches common scene names on first launch
3. To change scenes, use the pickers on either the Watch or iPhone app — changes sync bidirectionally

### 4. Wear to Bed

With Apple Watch sleep tracking enabled (Settings → Sleep on your Watch), wear your Watch to bed. The app will:
- Detect when you fall asleep and run your sleep scene
- Detect when you wake up and run your wake scene
- Log all transitions to the iPhone's overnight log

## Architecture

```
┌─────────────────────┐     WatchConnectivity      ┌──────────────────────┐
│     iPhone App      │◄──────────────────────────►│    Watch App          │
│                     │  applicationContext (state)  │                     │
│  ConnectivityManager│  transferUserInfo (events)   │  WatchConnectivity  │
│  ContentView        │  applicationContext (config)  │    Manager          │
│  NotificationManager│                              │  WatchSleepMonitor  │
│  AboutView          │                              │  HomeKitManager     │
│                     │                              │  WatchContentView   │
└─────────────────────┘                              └──────────────────────┘
                                                            │
                                                     HealthKit (local)
                                                     HomeKit (scenes)
```

- **WatchSleepMonitor** — Observes HealthKit sleep data, detects state transitions, triggers scenes
- **HomeKitManager** — Discovers Apple Home scenes and executes them
- **WatchConnectivityManager** — Sends state and transition events to iPhone
- **ConnectivityManager** — Receives watch data, sends scene config changes back

## Privacy

- All health data stays on-device. The app reads sleep analysis data from HealthKit but never transmits it to any server.
- HomeKit communication happens locally through your Apple Home Hub.
- WatchConnectivity transfers stay between your paired iPhone and Apple Watch.

## License

Copyright &copy; 2026 Technology4Seniors LLC. All rights reserved.
