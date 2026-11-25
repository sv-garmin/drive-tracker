# Drive Tracker

A Garmin Connect IQ watch app that records car drives as a regular Garmin
activity. Tracks **distance, moving time, break time, average and max speed**,
captures the **GPS track**, and lets you drop **waypoints** (lap markers) at
fuel stops, photo spots and hotels. Each drive saves to **Garmin Connect**.

Built for long-distance road trips. Runs on most current Garmin watches —
Fenix, Epix, Forerunner, Venu, Vivoactive, Instinct, Marq, Approach and Edge
— see `drive/manifest.xml` for the full list.

## On-watch controls (Fenix / Epix / Forerunner / Instinct)

| Button                | Action                                                  |
|-----------------------|---------------------------------------------------------|
| START (top-right)     | Start; press again to pause and open the finish menu    |
| BACK (bottom-right)   | Drop a waypoint while recording; resume from pause; exit when idle |
| UP (long-press)       | Open Settings (About)                                   |

A waypoint is recorded as a FIT lap split — Garmin Connect shows each one as
a pin on the map. The finish menu offers **Resume / Save / Discard**. Screen
taps on touch watches are ignored so accidental touches while driving don't
start or pause a drive.

## Single dashboard

Everything on one screen, no paging:

```
       ● DRIVING         GPS dot + status (green = driving, yellow = paused)
        125.4 km         distance (hero)
        2:34:12          moving time
       break 0:18        break time (elapsed minus moving)
   avg 48      max 112   average / max speed
    WP 3        14:35    waypoint count | time of day
```

Speeds and distance follow your watch's unit settings (km/h + km or mph + mi).
The dot beside the status is filled once GPS has a lock and hollow while
acquiring.

Current speed is intentionally **not** shown — the car's dashboard and your
eyes on the road are better places to read it.

## Settings → About

Long-press **UP** to open the **Settings** menu. Today it has one entry,
**About**, which shows the app version and a QR code linking to the
source repository.

## More

- [Changelog](CHANGELOG.md)
- [Development guide](DEVELOPING.md) — building from source, sideloading, releasing
- Licensed under the [MIT License](LICENSE)
