# Sleep State Trigger

An iOS + watchOS app that detects sleep/wake transitions using Apple Watch health data and automatically triggers Apple Home scenes. Fall asleep and your lights turn off, thermostat adjusts, TV powers down, and fan switches on. Wake up and your coffee maker starts, lights brighten, and HVAC shifts to your daytime schedule — all hands-free.

Any device or scene you can control through Apple Home can be automated with Sleep State Trigger.

## Features

### Apple Watch App
- **Real-time sleep detection** — Monitors sleep analysis data directly from the Watch's local HealthKit store with immediate background delivery
- **Automatic scene execution** — Runs your chosen sleep scene when you fall asleep and wake scene when you get up
- **Scene configuration** — Pick sleep and wake scenes from all available scenes in your Apple Home
- **Auto-matching** — Automatically selects scenes with common names (Goodnight, Good Morning, Sleep, Wake, etc.) on first launch
- **On-watch notifications** — Displays banners when sleep/wake transitions are detected
- **Transition history** — Shows recent state changes with timestamps

### iPhone Companion App
- **Live dashboard** — Displays the current sleep state synced from the Apple Watch in real time
- **Remote scene configuration** — Choose sleep and wake scenes from the iPhone; changes sync to the Watch automatically
- **Overnight log** — Records all sleep transitions throughout the night with timestamps and which scenes were executed
- **Watch pairing status** — Shows whether the Apple Watch is paired and actively monitoring

### What Can You Automate?

Sleep State Trigger works with any device or scene in Apple Home. Common examples:

- **Lighting** — Dim or turn off lights at sleep, brighten them at wake
- **Thermostat / HVAC** — Lower temperature for sleeping, raise it before you get up
- **Fans** — Turn on a bedroom fan at sleep, off at wake
- **TV / Entertainment** — Power off the TV when you fall asleep
- **Coffee maker** — Start brewing when you wake up
- **Smart plugs** — Control any plugged-in device on a sleep/wake schedule
- **Window shades** — Close shades at bedtime, open them in the morning

If it's in your Apple Home, Sleep State Trigger can control it.

### Sleep States Detected

| State | Description |
|-------|-------------|
| Awake | User is awake |
| In Bed | In bed but not yet asleep |
| Asleep | Asleep (unspecified stage) |
| REM | REM sleep stage |
| Core | Core sleep stage |
| Deep | Deep sleep stage |

## Why the Watch?

**Apple's privacy model blocks HealthKit background delivery on a locked iPhone — which means an iPhone-only app can't detect sleep transitions overnight.** The Apple Watch writes sleep data to its local HealthKit store and delivers background updates immediately, even while the screen is off. This makes the Watch the only reliable way to trigger actions based on real-time sleep state.

## Requirements

- **iPhone** running iOS 17.0 or later
- **Apple Watch** running watchOS 10.0 or later with sleep tracking enabled
- **Apple Home Hub** (Apple TV or HomePod) on your network for scene execution

## Setup

### 1. Grant Permissions

On first launch, the app will request:
- **HealthKit** — Read access to sleep analysis data (Apple Watch)
- **HomeKit** — Access to your Apple Home for scene discovery and execution (Apple Watch)
- **Notifications** — For sleep/wake transition alerts (both devices)

### 2. Configure Scenes

1. Make sure you have scenes set up in the **Home** app (e.g., "Good Night" and "Good Morning")
2. The app auto-matches common scene names on first launch
3. To change scenes, use the pickers on either the Watch or iPhone — changes sync automatically

### 3. Wear to Bed

With Apple Watch sleep tracking enabled, wear your Watch to bed. The app will:
- Detect when you fall asleep and run your sleep scene
- Detect when you wake up and run your wake scene
- Log all transitions to the iPhone's overnight log

## Privacy

- All health data stays on-device. The app reads sleep analysis data from HealthKit but never transmits it to any server.
- HomeKit communication happens locally through your Apple Home Hub.
- Data synced between your iPhone and Apple Watch stays between your paired devices.

## License

Copyright &copy; 2026 Technology4Seniors LLC. All rights reserved.
