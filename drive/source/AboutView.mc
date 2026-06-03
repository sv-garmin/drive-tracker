import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// "About" screen: app name + version. BACK returns to the previous view.
class AboutView extends WatchUi.View {
    public function initialize() {
        View.initialize();
    }

    public function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var appName = WatchUi.loadResource(Rez.Strings.AppName) as String;
        var version = WatchUi.loadResource(Rez.Strings.AppVersion) as String;
        var qr = WatchUi.loadResource(Rez.Drawables.QrGithub);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, h * 0.18, Graphics.FONT_TINY, appName);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, h * 0.28, Graphics.FONT_XTINY, "v" + version);
        dc.drawBitmap(cx - 40, h * 0.60 - 40, qr);
        drawCentered(dc, cx, h * 0.93, Graphics.FONT_XTINY, "scan for source");
    }

    private function drawCentered(dc as Dc, x as Numeric, y as Numeric, font as Graphics.FontType, text as String) as Void {
        dc.drawText(x, y, font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// BACK pops back to the settings menu.
class AboutDelegate extends WatchUi.BehaviorDelegate {
    public function initialize() {
        BehaviorDelegate.initialize();
    }

    public function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
