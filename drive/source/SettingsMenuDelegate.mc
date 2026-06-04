import Toybox.Lang;
import Toybox.WatchUi;

// Handles selections from the Settings menu (currently just "About").
class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :about) {
            WatchUi.pushView(new AboutView(), new AboutDelegate(), WatchUi.SLIDE_LEFT);
        }
    }
}
