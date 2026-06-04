import Toybox.Lang;
import Toybox.WatchUi;

// Button handling (Fenix 6s layout):
//   START (top-right)    -> start; while active, pause and open the finish menu
//   BACK  (bottom-right) -> drop a waypoint while recording; resume from pause; exit when idle
//   UP    (long-press)   -> open Settings (always)
class DriveDelegate extends WatchUi.BehaviorDelegate {
    private var _activity as DriveActivity;

    public function initialize(activity as DriveActivity) {
        BehaviorDelegate.initialize();
        _activity = activity;
    }

    public function onSelect() as Boolean {
        if (_activity.isActive()) {
            openFinishMenu();
        } else {
            _activity.startOrResume();
            WatchUi.requestUpdate();
        }
        return true;
    }

    // BACK: contextual — drop a waypoint while running, resume from pause, exit when idle.
    public function onBack() as Boolean {
        var state = _activity.getState();
        if (state == STATE_RUNNING) {
            _activity.dropWaypoint();
            WatchUi.requestUpdate();
            return true;
        }
        if (state == STATE_PAUSED) {
            _activity.startOrResume();
            WatchUi.requestUpdate();
            return true;
        }
        return false; // STOPPED -> let the system exit the app
    }

    public function onMenu() as Boolean {
        openSettingsMenu();
        return true;
    }

    private function openFinishMenu() as Void {
        if (_activity.getState() == STATE_RUNNING) {
            _activity.pause();
        }
        var menu = new WatchUi.Menu2({ :title => "Drive" });
        menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
        menu.addItem(new WatchUi.MenuItem("Save", "to Garmin Connect", :save, null));
        menu.addItem(new WatchUi.MenuItem("Discard", null, :discard, null));
        WatchUi.pushView(menu, new StopMenuDelegate(_activity), WatchUi.SLIDE_UP);
    }

    private function openSettingsMenu() as Void {
        var title = WatchUi.loadResource(Rez.Strings.SettingsTitle) as String;
        var about = WatchUi.loadResource(Rez.Strings.AboutItem) as String;
        var menu = new WatchUi.Menu2({ :title => title });
        menu.addItem(new WatchUi.MenuItem(about, null, :about, null));
        WatchUi.pushView(menu, new SettingsMenuDelegate(), WatchUi.SLIDE_UP);
    }
}
