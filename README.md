# Never Late

A one-tap timing game on a watch dial, from Zero Day Watches. *Never Off. Never Late.*

A seconds hand sweeps the dial and a lume marker sits on the bezel. Tap while the hand is inside the marker. Dead center scores double. Let the hand slip past and you're late.

| Phase | Starts at | What changes |
|---|---|---|
| 1 · Steady | 0 hits | Hand speeds up, marker shrinks every hit |
| 2 · Reverse | 8 hits | Hand can flip direction after a hit |
| 3 · Drift | 15 hits | Marker slides along the bezel |

Tuning lives at the top of `NeverLate/GameModel.swift`.

## Run it on your iPhone

Requirements: a Mac with Xcode 16 or newer, and an iPhone on iOS 17 or newer.

1. Clone the repo and open `NeverLate.xcodeproj`.
2. Click the **NeverLate** project in the left sidebar, then the **NeverLate** target, then **Signing & Capabilities**.
3. Pick your **Team** (your Apple ID works for testing on your own phone; the paid Apple Developer Program is needed for the App Store).
4. If Xcode complains the bundle ID is taken, change `com.zerodaywatches.neverlate` to something unique.
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
  GameCenter.swift     Sign-in, score submission, leaderboard
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
3. **Game Center leaderboard**: in the app's Services > Game Center tab, add a Classic leaderboard with ID `neverlate.highscore`, score format Integer, sort High to Low. Then add Game Center to the app version.
4. **Archive**: in Xcode, set the destination to *Any iOS Device*, then Product > Archive. In the Organizer, click **Distribute App** > App Store Connect.
5. **TestFlight**: install the build on your phone through the TestFlight app and play a few real runs.
6. **Listing**: 6.9" iPhone screenshots (take them on your phone), description, keywords, support URL, privacy policy URL. Privacy answers: the app collects no data (Game Center is handled by Apple).
7. **Submit for review**.
