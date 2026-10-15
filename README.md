# Never Late

A one-tap timing game on a GMT watch dial.

A seconds hand sweeps the dial and a lume marker sits on the bezel. Tap while the hand is inside the marker. Dead center scores double. Let the hand slip past and you're late.

| Phase | Starts at | What changes |
|---|---|---|
| 1 · Steady | 0 hits | Hand speeds up, marker shrinks every hit |
| 2 · Reverse | 8 hits | Hand can flip direction after a hit |
| 3 · Drift | 15 hits | Marker slides along the bezel |

**Modes:** Classic is endless random runs. Daily is the same seeded run for everyone that day; only the first try counts, and later tries are practice.

Tuning lives at the top of `NeverLate/GameModel.swift`.

## Run it on your iPhone

Requirements: a Mac with Xcode 16 or newer, and an iPhone on iOS 17 or newer.

1. Clone the repo and open `NeverLate.xcodeproj`.
2. Click the **NeverLate** project in the left sidebar, then the **NeverLate** target, then **Signing & Capabilities**.
3. Pick your **Team** (your Apple ID works for testing on your own phone; the paid Apple Developer Program is needed for the App Store).
4. If Xcode complains the bundle ID is taken, change `com.nickmellem.neverlate` to something unique.
5. Plug in your iPhone (or pick it over Wi-Fi), select it as the run destination, and press **Run** (⌘R).
6. First run only: on the phone, go to Settings > General > VPN & Device Management and trust your developer certificate. On iOS 16+ also turn on Settings > Privacy & Security > Developer Mode.

Haptics only work on a real device, not the simulator.

## Project layout

```
NeverLate/
  NeverLateApp.swift   App entry
  ContentView.swift    Screen layout, HUD, menu card, touch handling
  DialView.swift       Draws the watch dial every frame (SwiftUI Canvas)
  GameModel.swift      Game rules, state, and the 120 Hz display-link loop
  Feedback.swift       Haptics and synthesized sound effects
  GameCenter.swift     Sign-in, leaderboards, achievements
  Daily.swift          Daily Challenge seed, number, streak
  ShareCard.swift      Score image for the share sheet
  Theme.swift          Colors and fonts
  Fonts/               Chakra Petch (SIL Open Font License)
  Assets.xcassets      App icon and accent color
Support/
  Info.plist           Fonts, 120 Hz, export compliance
  NeverLate.entitlements  Game Center
```

New Swift files dropped into `NeverLate/` are picked up by Xcode automatically.

## Shipping to the App Store

1. **Join the Apple Developer Program** ($99/yr) at developer.apple.com.
2. **App Store Connect**: My Apps > + > New App. Name "Never Late" (or a variant if taken), bundle ID matching the project, SKU `neverlate`.
3. **Game Center** (1.1 and later): see the setup section below.
4. **Archive**: in Xcode, set the destination to *Any iOS Device*, then Product > Archive. In the Organizer, click **Distribute App** > App Store Connect.
5. **TestFlight**: install the build on your phone through the TestFlight app and play a few real runs.
6. **Listing**: 6.9" iPhone screenshots (take them on your phone), description, keywords, support URL, privacy policy URL. Privacy answers: the app collects no data (Game Center is handled by Apple).
7. **Submit for review**.

## Game Center setup (1.1)

Game Center needs the paid developer team selected under Signing & Capabilities.

In App Store Connect, open the app, then **Services > Game Center**, and create these. IDs must match exactly.

**Leaderboards**

| Type | Leaderboard ID | Display name | Score format | Sort |
|---|---|---|---|---|
| Classic | `neverlate.highscore` | Best Score | Integer | High to Low |
| Recurring, every 1 day | `neverlate.daily` | Daily Challenge | Integer | High to Low, best score |

**Achievements** (each: 10 points, not hidden, achievable more than once: No)

| Achievement ID | Title | Description |
|---|---|---|
| `neverlate.first_perfect` | Dead Center | Land a perfect hit. |
| `neverlate.reach_reverse` | Counter Clockwise | Reach phase 2, Reverse. |
| `neverlate.reach_drift` | Bezel Drift | Reach phase 3, Drift. |
| `neverlate.score_25` | Quarter Hour | Score 25 in one run. |
| `neverlate.score_50` | Fifty Down | Score 50 in one run. |
| `neverlate.score_100` | Centurion | Score 100 in one run. |
| `neverlate.perfect_streak_5` | Chronometer | Land 5 perfect hits in a row. |
| `neverlate.daily_streak_7` | Daily Wearer | Play the Daily Challenge 7 days in a row. |

Each achievement also needs a 512x512 image. Then add Game Center to the app version before submitting.
