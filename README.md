# Drive Tracker

A Garmin Connect IQ watch app that records car drives as a regular Garmin
activity. Tracks **distance, moving time, break time, average and max speed**,
captures the **GPS track**, and lets you drop **waypoints** (lap markers) at
fuel stops, photo spots and hotels. Each drive saves to **Garmin Connect**.

Built for long-distance road trips on the **Fenix 6s**.

## On-watch controls (Fenix 6s)

| Button                | Action                                                  |
|-----------------------|---------------------------------------------------------|
| START (top-right)     | Start; press again to pause and open the finish menu    |
| BACK (bottom-right)   | Drop a waypoint while recording; resume from pause; exit when idle |
| UP (long-press)       | Open Settings (About)                                   |

A waypoint is recorded as a FIT lap split — Garmin Connect shows each one as
a pin on the map. The finish menu offers **Resume / Save / Discard**.

## Single dashboard

Everything on one screen, no paging:

```
        DRIVING          status (green = driving, yellow = paused)
        125.4 km         distance (hero)
        2:34:12          moving time
       break 0:18        break time (elapsed minus moving)
   avg 48      max 112   average / max speed
   WP 3        14:35     waypoint count | time of day
```

Speeds and distance follow your watch's unit settings (km/h + km or mph + mi).

Current speed is intentionally **not** shown — the dashboard, your dashboard
in the car, and your eyes on the road are all better places to read it.

## Settings → About

Long-press **UP** to open the **Settings** menu. Today it has one entry,
**About**, which shows the app version and a QR code linking to the
source repository.

## More

- [Changelog](CHANGELOG.md)
- [Development guide](DEVELOPING.md) — building from source, sideloading, releasing
- Licensed under the [MIT License](LICENSE)
