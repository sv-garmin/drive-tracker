# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[semantic versioning](https://semver.org/) — bump `version` in
`drive/manifest.xml` to match every release.

## [Unreleased]

## [1.1.0] — 2026-11-24

### Added
- Support for new Connect IQ SDK `9.3.0` devices: Fenix 9 / 9 Pro / 9 Pro
  Solar, Enduro 4, MARQ Gen 3, Approach S72, Edge 1060, and Edge Explore 3 /
  3 Plus.
- GPS lock indicator dot beside the dashboard status (filled when locked,
  hollow while acquiring); GPS starts on launch and stays warm across pauses.
- Dedicated monochrome / subscreen layout for Instinct 2/3 Solar/E and
  Descent G1, plus integer-scaled QR rendering on high-DPI displays.
- Monkey C `(:test)` unit tests (`DriveTests.mc`) and strict `-l 3` type
  checking in `build.sh` and CI.

### Changed
- Ignore screen taps (`onTap`) on touch watches so accidental touches while
  driving don't start or pause a session.
- Move UI and menu strings into `strings.xml` and cache loaded resources in
  `DriveView` and `AboutView`.
- Inset the bottom dashboard row (`WP` / clock) slightly for better bezel
  clearance on round displays.
- Remove unused `FitContributor` permission from `drive/manifest.xml`.
- CI bumped to Connect IQ SDK `9.3.0` (`2026-10-20-95888f262`).

### Fixed
- Prevent stale `Activity.Info` metrics from appearing on the idle `READY`
  screen before starting a drive.
- Reset waypoint count on `save()` and `discard()`.
- Fix `v1.0.0` release date to `2026-07-28`.

## [1.0.0] — 2026-07-28

Initial release.

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
- Targets ~100 current Connect IQ devices (Fenix, Epix, Forerunner, Venu,
  Vivoactive, Instinct, Marq, Approach, Edge, Descent and more) at
  `minApiLevel="3.4.0"`.
