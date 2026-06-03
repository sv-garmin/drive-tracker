import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class DriveApp extends Application.AppBase {
    private var _activity as DriveActivity?;

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
    }

    // If the app is exited while a session is still open (e.g. long-press
    // back, low battery), save it so the drive isn't lost.
    public function onStop(state as Dictionary?) as Void {
        var a = _activity;
        if (a != null && a.isActive()) {
            a.save();
        }
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        var a = new DriveActivity();
        _activity = a;
        return [ new DriveView(a), new DriveDelegate(a) ];
    }
}

function getApp() as DriveApp {
    return Application.getApp() as DriveApp;
}
