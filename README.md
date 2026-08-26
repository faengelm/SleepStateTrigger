# Sleep State Trigger

An iOS + watchOS app that detects sleep/wake transitions using Apple Watch health data and automatically triggers Apple Home scenes and Shortcuts. Fall asleep and your lights turn off, thermostat adjusts, TV powers down, Focus mode activates, and fan switches on. Wake up and your coffee maker starts, lights brighten, Focus turns off, and HVAC shifts to your daytime schedule — all hands-free.

Any device or scene you can control through Apple Home — plus anything you can do with an Apple Shortcut — can be automated with Sleep State Trigger.

## Features

### Apple Watch App
- **Real-time sleep detection** — Monitors sleep analysis data directly from the Watch's local HealthKit store with immediate background delivery
- **Extended runtime session** — Keeps the app alive during sleep so HealthKit observer queries fire in real time
- **Automatic scene execution** — Runs your chosen sleep scene when you fall asleep and wake scene when you get up
- **Scene configuration** — Pick sleep and wake scenes from all available scenes in your Apple Home
- **Auto-matching** — Automatically selects scenes with common names (Goodnight, Good Morning, Sleep, Wake, etc.) on first launch
- **Watch face complication** — Shows current sleep state directly on your watch face (circular, rectangular, and inline)
- **On-watch notifications** — Displays banners when sleep/wake transitions are detected
- **Test buttons** — Manually trigger sleep or wake scenes from the Watch
- **HealthKit diagnostics** — View latest sample details, observer fire count, and session state for troubleshooting
- **Transition history** — Shows recent state changes with timestamps

### iPhone Companion App
- **Live dashboard** — Displays the current sleep state synced from the Apple Watch in real time
- **Remote scene configuration** — Choose sleep and wake scenes from the iPhone; changes sync to the Watch automatically
- **Shortcuts integration** — Run an Apple Shortcut on sleep/wake transitions to control Focus mode, send messages, adjust settings, or anything else Shortcuts can do
- **One-tap shortcut install** — Install a pre-built "Set Focus Mode" shortcut directly from the app, then configure what input to pass for sleep and wake
- **Overnight log** — Records all sleep transitions throughout the night with timestamps and which scenes were executed
- **Watch pairing status** — Shows whether the Apple Watch is paired and actively monitoring
- **About screen** — Shows both iPhone and Watch app versions to verify connectivity

### What Can You Automate?

Sleep State Trigger works with any device or scene in Apple Home. Common examples:

- **Lighting** — Dim or turn off lights at sleep, brighten them at wake
- **Thermostat / HVAC** — Lower temperature for sleeping, raise it before you get up
- **Fans** — Turn on a bedroom fan at sleep, off at wake
- **TV / Entertainment** — Power off the TV when you fall asleep
- **Coffee maker** — Start brewing when you wake up
- **Smart plugs** — Control any plugged-in device on a sleep/wake schedule
- **Window shades** — Close shades at bedtime, open them in the morning

- **Focus mode** — Switch to Sleep Focus at bedtime, switch to Work or Personal Focus at wake (via Shortcuts)
- **Messages** — Send an automated "good morning" text (via Shortcuts)

If it's in your Apple Home or Apple Shortcuts, Sleep State Trigger can control it.

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

**Apple's privacy model blocks HealthKit background delivery on a locked iPhone — which means an iPhone-only app can't detect sleep transitions overnight.** The Apple Watch writes sleep data to its local HealthKit store and delivers background updates immediately, even while the screen is off. The app uses an extended runtime session to stay active during sleep, ensuring HealthKit observer queries fire in real time. This makes the Watch the only reliable way to trigger actions based on real-time sleep state.

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

### 3. Set Up Shortcuts (Optional)

Sleep State Trigger can run an Apple Shortcut on each sleep/wake transition — for example, to change your iPhone's Focus mode.

1. In the iPhone app, tap **Install Focus Shortcut** to install the pre-built "Set Focus Mode" shortcut
2. Enter the Focus mode name to activate for each transition — for example, "Sleep" when you fall asleep and "Work" or "Personal" when you wake up (these must match Focus modes configured on your iPhone in Settings > Focus)
3. Tap the **Test** buttons to verify each one works — when prompted, tap **Always Allow** so the shortcut can run without confirmation
4. The shortcut runs automatically when a sleep/wake transition is received from the Watch

### 4. Add the Complication (Optional)

1. Long-press your watch face and tap **Edit**
2. Tap a complication slot and scroll to **Sleep State Trigger**
3. Choose **Sleep State** — it shows your current sleep state directly on the watch face

### 5. Verify Watch Connectivity

Open the **Settings** (gear icon) on the iPhone app and check the **About** screen. If the Watch App version and build number appear, the Watch is communicating successfully with the iPhone. If they show "—", open the Watch app to trigger a sync.

### 6. Wear to Bed

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
