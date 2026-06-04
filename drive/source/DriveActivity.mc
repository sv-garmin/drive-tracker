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
// recorded continuously; each manual waypoint becomes a FIT lap so it
// shows up as a split in Garmin Connect.
class DriveActivity {
    private var _session as ActivityRecording.Session?;
    private var _state as DriveState;
    private var _waypoints as Number;

    public function initialize() {
        _session = null;
        _state = STATE_STOPPED;
        _waypoints = 0;
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
        // Continuous GPS while recording.
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
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
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
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
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        _session = null;
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
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        _session = null;
        _state = STATE_STOPPED;
    }

    // Position callback. Required by enableLocationEvents but we don't
    // need to do anything — ActivityRecording pulls fixes into the FIT
    // record stream automatically while a session is recording.
    public function onPosition(info as Position.Info) as Void {
    }

    private function vibe(intensity as Number, durationMs as Number) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate(
                [new Attention.VibeProfile(intensity, durationMs)] as Array<Attention.VibeProfile>
            );
        }
    }
}
