# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[semantic versioning](https://semver.org/) — bump `version` in
`drive/manifest.xml` to match every release.

## [Unreleased]

## [0.1.0] — 2026-06-03

Initial scaffolding.

### Added
- Records each drive as a Garmin **Driving** FIT activity with continuous
  GPS, syncing to Garmin Connect with the full track, distance, duration
  and speed stats.
- **Manual waypoints** on the BACK button — each press writes a FIT lap, so
  Garmin Connect shows a split (and a pin on the map) at every fuel stop,
  rest area or photo spot.
- Single dashboard with: status (DRIVING / PAUSED / READY), distance,
  moving time, break time, average and max speed, waypoint count, and
  time of day. No current speed (intentional — eyes on the road).
- **Finish menu** (Resume / Save / Discard) opened by pressing START
  while a drive is open.
- **Settings → About** screen (app version + QR to the source repo)
  opened by long-pressing UP.
- **Contextual BACK**: drops a waypoint while running, resumes from pause
  when paused, exits only when idle — protects against losing data by accident.
- Distance and speed honor the watch's unit settings (km/h+km or mph+mi).
- Haptic feedback on start, pause, waypoint and save.
- Auto-save fallback in `App.onStop` if the app is force-closed while a
  session is open.
- Steering-wheel launcher icon.
- `build.sh`, `run.sh`, `install.sh` for one-step build / simulator / sideload.
- GitHub Actions CI builds the store `.iq` on every push/PR; on a `v*` tag
  push it drafts a release with `.iq` attached.
