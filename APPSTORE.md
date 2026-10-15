# App Store listing: Never Late 1.0

Copy and paste these into App Store Connect. Character limits are Apple's.

## App information

| Field | Value |
|---|---|
| Name (30) | Never Late |
| Subtitle (30) | One-tap GMT timing game |
| Category | Games > Casual (secondary: Games > Arcade) |
| Content rights | Does not contain third-party content |
| Age rating | Answer "None" / "No" to everything (rates 4+) |
| Price | Free |
| Support URL | https://mellemnick-del.github.io/never-late/support.html |
| Marketing URL | https://mellemnick-del.github.io/never-late/ |
| Privacy Policy URL | https://mellemnick-del.github.io/never-late/privacy.html |
| App Privacy | Data Not Collected |
| Copyright | 2026 Nick Mellem |

## Promotional text (170)

A watch dial, a sweeping seconds hand, and one job: tap on time. Quick runs that fit in any line or commercial break.

## Description (4000)

Never Late is a one-tap timing game on a GMT watch dial.

The seconds hand sweeps around the dial. A glowing lume marker sits on the bezel. Tap the moment the hand is inside it. Hit dead center for double points. Let the hand slip past and you're late.

Simple to learn, hard to master:

• STEADY: every hit speeds up the hand and shrinks the marker.
• REVERSE: after 8 hits, the hand can flip direction without warning.
• DRIFT: after 15 hits, the marker slides along the bezel.

Built for real life:

• Runs take under a minute. Play in line, on hold, or during a timeout.
• Leave mid-run and it pauses. Tap to pick up where you left off.
• Crisp haptics on every hit, and a heavier thump on a perfect.
• Sound respects your silent switch and plays over your music or podcast.
• Smooth 120 Hz motion on ProMotion iPhones.

Designed for watch people: a two-tone 24-hour GMT bezel, black dial, aged cream lume, a date window that keeps your score, and real hour, minute, and GMT hands that show the actual time.

No ads. No accounts. No data collected. Just you and the seconds hand.

## Keywords (100, comma separated, no spaces)

watch,timing,reflex,tap,arcade,casual,gmt,dial,clock,bezel,quick,one tap,focus,precision,lume

## What's New (version 1.0)

First release.

## App Review notes

No login required. Tap anywhere to start. Tap when the seconds hand is inside the glowing marker on the bezel; a miss ends the run.

## Screenshots (6.9" iPhone, 1320 x 2868)

Ready to upload, in order: `appstore/screenshots/01.png` to `05.png`.

| # | Headline | Line under it |
|---|---|---|
| 1 | Tap on time. | One tap. One seconds hand. |
| 2 | Hit dead center. | Perfect hits score double. |
| 3 | It fights back. | The hand reverses. The bezel drifts. |
| 4 | Built for watch people. | 24-hour GMT bezel. Cream lume. Real time. |
| 5 | Plays in a minute. | For lines, timeouts and commercial breaks. |

They are drawn by `tools/make_screenshots.py`, which matches the app's look. To frame real screenshots from the phone instead:

```
python3 tools/make_screenshots.py appstore/screenshots --shot 1=IMG_0001.PNG --shot 2=IMG_0002.PNG
```
