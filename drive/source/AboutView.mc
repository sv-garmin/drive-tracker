import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// "About" screen: app name, version, and QR code linking to the source repo.
// BACK returns to the settings menu.
class AboutView extends WatchUi.View {
    private var _appName as String;
    private var _version as String;
    private var _scanHint as String;
    private var _qr as WatchUi.BitmapResource;

    public function initialize() {
        View.initialize();
        _appName = WatchUi.loadResource(Rez.Strings.AppName) as String;
        _version = "v" + (WatchUi.loadResource(Rez.Strings.AppVersion) as String);
        _scanHint = WatchUi.loadResource(Rez.Strings.ScanForSource) as String;
        _qr = WatchUi.loadResource(Rez.Drawables.QrGithub) as WatchUi.BitmapResource;
    }

    public function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        var settings = System.getDeviceSettings();
        var isMono = (System has :SCREEN_SHAPE_SEMI_OCTAGON)
            && (settings.screenShape == System.SCREEN_SHAPE_SEMI_OCTAGON);
        var subscreen = (WatchUi has :getSubscreen) ? WatchUi.getSubscreen() : null;
        var mutedColor = isMono ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var qrW = _qr.getWidth();
        var qrH = _qr.getHeight();

        if (subscreen != null) {
            var sx = subscreen.x;
            var sy = subscreen.y;
            var sh = subscreen.height;
            if (sx != null && sy != null && sh != null) {
                // Place app name and version to the left of the circular subscreen,
                // and center the QR cleanly below it.
                var headerCx = sx / 2;
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                drawCentered(dc, headerCx, sy + (sh * 0.32).toNumber(),
                    Graphics.FONT_XTINY, _appName);
                dc.setColor(mutedColor, Graphics.COLOR_TRANSPARENT);
                drawCentered(dc, headerCx, sy + (sh * 0.70).toNumber(),
                    Graphics.FONT_XTINY, _version);

                var topY = sy + sh;
                var qrY = topY + (h - topY - qrH) / 2;
                dc.drawBitmap(cx - qrW / 2, qrY, _qr);
                return;
            }
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, (h * 0.16).toNumber(), Graphics.FONT_TINY, _appName);
        dc.setColor(mutedColor, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, (h * 0.26).toNumber(), Graphics.FONT_XTINY, _version);

        // Integer-scale the QR on high-DPI devices (API 4.0+) so it stays crisp
        // and scannable while keeping 1:1 rendering on smaller/older displays.
        var minDim = (w < h) ? w : h;
        var targetSize = (minDim * 0.42).toNumber();
        var drawW = qrW;
        var drawH = qrH;
        var qrCenterY = (h * 0.58).toNumber();

        if ((dc has :drawScaledBitmap) && qrW > 0 && qrH > 0) {
            var scale = targetSize / qrW;
            if (scale > 1) {
                drawW = qrW * scale;
                drawH = qrH * scale;
            }
            if (drawW != qrW) {
                dc.drawScaledBitmap(cx - drawW / 2, qrCenterY - drawH / 2, drawW, drawH, _qr);
            } else {
                dc.drawBitmap(cx - qrW / 2, qrCenterY - qrH / 2, _qr);
            }
        } else {
            dc.drawBitmap(cx - qrW / 2, qrCenterY - qrH / 2, _qr);
        }

        var qrBottom = qrCenterY + drawH / 2;
        var hintY = (h * 0.90).toNumber();
        if (hintY > qrBottom + 8) {
            dc.setColor(mutedColor, Graphics.COLOR_TRANSPARENT);
            drawCentered(dc, cx, hintY, Graphics.FONT_XTINY, _scanHint);
        }
    }

    private function drawCentered(dc as Dc, x as Number, y as Number, font as Graphics.FontType, text as String) as Void {
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
