import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Position;

enum DriveState {
    STATE_STOPPED, // no open session
    STATE_RUNNING, // timer active, recording
    STATE_PAUSED   // session open but timer stopped
}

// Wraps an ActivityRecording.Session for a driving activity. GPS is
// kept active while the app is open (including pre-start and pause) so
// lock status is visible before departure and resume is instant; each
// manual waypoint becomes a FIT lap so it shows up as a split in
// Garmin Connect.
class DriveActivity {
    private var _session as ActivityRecording.Session?;
    private var _state as DriveState;
    private var _waypoints as Number;
    private var _gpsEnabled as Boolean;
    private var _gpsAccuracy as Position.Quality;

    public function initialize() {
        _session = null;
        _state = STATE_STOPPED;
        _waypoints = 0;
        _gpsEnabled = false;
        _gpsAccuracy = Position.QUALITY_NOT_AVAILABLE;
    }

    public function getState() as DriveState {
        return _state;
    }

    public function getWaypointCount() as Number {
        return _waypoints;
    }

    public function isActive() as Boolean {
        return _state != STATE_STOPPED;
    }

    public function getGpsAccuracy() as Position.Quality {
        return _gpsAccuracy;
    }

    public function hasGpsFix() as Boolean {
        return _gpsAccuracy == Position.QUALITY_USABLE
            || _gpsAccuracy == Position.QUALITY_GOOD;
    }

    public function startGps() as Void {
        if (!_gpsEnabled) {
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
            _gpsEnabled = true;
        }
    }

    public function stopGps() as Void {
        if (_gpsEnabled) {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
            _gpsEnabled = false;
        }
        _gpsAccuracy = Position.QUALITY_NOT_AVAILABLE;
    }

    public function startOrResume() as Void {
        var s = _session;
        if (s == null) {
            s = ActivityRecording.createSession({
                :name => "Drive",
                :sport => Activity.SPORT_DRIVING,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            _session = s;
            _waypoints = 0;
        }
        startGps();
        if (!s.isRecording()) {
            s.start();
        }
        _state = STATE_RUNNING;
        vibe(50, 200);
    }

    public function pause() as Void {
        var s = _session;
        if (s != null && s.isRecording()) {
            s.stop();
        }
        _state = STATE_PAUSED;
        vibe(50, 100);
    }

    // Drop a waypoint at the current location. Implemented as a FIT lap so
    // Garmin Connect renders it as a split with a GPS pin. Returns true if
    // the waypoint was recorded.
    public function dropWaypoint() as Boolean {
        var s = _session;
        if (s != null && s.isRecording()) {
            s.addLap();
            _waypoints += 1;
            vibe(75, 150);
            return true;
        }
        return false;
    }

    public function save() as Void {
        var s = _session;
        if (s != null) {
            if (s.isRecording()) {
                s.stop();
            }
            s.save();
        }
        stopGps();
        _session = null;
        _waypoints = 0;
        _state = STATE_STOPPED;
        vibe(100, 400);
    }

    public function discard() as Void {
        var s = _session;
        if (s != null) {
            if (s.isRecording()) {
                s.stop();
            }
            s.discard();
        }
        stopGps();
        _session = null;
        _waypoints = 0;
        _state = STATE_STOPPED;
    }

    // Position callback: tracks current GPS fix quality for the dashboard
    // indicator while ActivityRecording pulls fixes into the FIT stream.
    public function onPosition(info as Position.Info) as Void {
        _gpsAccuracy = info.accuracy;
    }

    private function vibe(intensity as Number, durationMs as Number) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate(
                [new Attention.VibeProfile(intensity, durationMs)] as Array<Attention.VibeProfile>
            );
        }
    }
}
