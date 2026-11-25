import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Pure formatting helpers (separated for testability).
module DriveFormat {
    // Distance numeric string (without unit): 1 decimal below 100, whole
    // number from 100 onward.
    public function distanceValue(meters as Float, statute as Boolean) as String {
        if (meters < 0.0) {
            meters = 0.0;
        }
        if (statute) {
            var miles = meters / 1609.344;
            return miles < 100.0 ? miles.format("%.1f") : miles.format("%.0f");
        }
        var km = meters / 1000.0;
        return km < 100.0 ? km.format("%.1f") : km.format("%.0f");
    }

    public function distanceUnit(statute as Boolean) as String {
        return statute ? "mi" : "km";
    }

    // m/s -> km/h or mph, rounded to the nearest integer.
    public function speedText(metersPerSec as Float, statute as Boolean) as String {
        if (metersPerSec < 0.0) {
            metersPerSec = 0.0;
        }
        var v = statute ? metersPerSec * 2.236936 : metersPerSec * 3.6;
        return v.format("%.0f");
    }

    // Format milliseconds as M:SS, or H:MM:SS once past an hour.
    public function formatTime(ms as Number) as String {
        if (ms < 0) {
            ms = 0;
        }
        var totalSec = ms / 1000;
        var hours = totalSec / 3600;
        var mins = (totalSec % 3600) / 60;
        var secs = totalSec % 60;
        if (hours > 0) {
            return Lang.format("$1$:$2$:$3$", [hours, mins.format("%02d"), secs.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [mins.format("%01d"), secs.format("%02d")]);
    }

    // Format time of day using device's 12h/24h preference.
    public function formatClock(hour as Number, min as Number, is24Hour as Boolean) as String {
        if (!is24Hour) {
            var h12 = hour % 12;
            if (h12 == 0) {
                h12 = 12;
            }
            return Lang.format("$1$:$2$", [h12, min.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [hour.format("%02d"), min.format("%02d")]);
    }
}

// Dashboard layout (round / rectangular):
//         ● DRIVING         <- GPS dot + status (green/yellow/gray)
//          125.4 km         <- distance + unit (hero)
//          2:34:12          <- moving time
//        break 0:18         <- break time (= elapsed - moving)
//     avg 48      max 112   <- avg / max speed (km/h or mph)
//      WP 3        14:35    <- waypoint count | time of day
//
// On monochrome semi-octagon watches with a hardware subscreen (Instinct 2/3
// Solar/E, Descent G1), foreground is pure white, status sits beside the
// subscreen, WP count sits inside the subscreen, and the remaining metrics
// stack cleanly below it.
class DriveView extends WatchUi.View {
    private var _activity as DriveActivity;
    private var _timer as Timer.Timer?;

    private var _strDriving as String;
    private var _strPaused as String;
    private var _strReady as String;
    private var _strPressStart as String;
    private var _strBreak as String;
    private var _strAvg as String;
    private var _strMax as String;
    private var _strWp as String;

    public function initialize(activity as DriveActivity) {
        View.initialize();
        _activity = activity;
        _strDriving = WatchUi.loadResource(Rez.Strings.StatusDriving) as String;
        _strPaused = WatchUi.loadResource(Rez.Strings.StatusPaused) as String;
        _strReady = WatchUi.loadResource(Rez.Strings.StatusReady) as String;
        _strPressStart = WatchUi.loadResource(Rez.Strings.PressStart) as String;
        _strBreak = WatchUi.loadResource(Rez.Strings.BreakLabel) as String;
        _strAvg = WatchUi.loadResource(Rez.Strings.AvgLabel) as String;
        _strMax = WatchUi.loadResource(Rez.Strings.MaxLabel) as String;
        _strWp = WatchUi.loadResource(Rez.Strings.WpLabel) as String;
    }

    public function onShow() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        (_timer as Timer.Timer).start(method(:onTick), 1000, true);
    }

    public function onHide() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
        }
    }

    public function onTick() as Void {
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var state = _activity.getState();
        // Only read ActivityInfo while a session is open so metrics from a
        // prior system activity never leak onto the READY screen.
        var info = (state != STATE_STOPPED) ? Activity.getActivityInfo() : null;

        var settings = System.getDeviceSettings();
        var statute = settings.distanceUnits == System.UNIT_STATUTE;
        var is24Hour = settings.is24Hour;
        var isMono = (System has :SCREEN_SHAPE_SEMI_OCTAGON)
            && (settings.screenShape == System.SCREEN_SHAPE_SEMI_OCTAGON);
        var subscreen = (WatchUi has :getSubscreen) ? WatchUi.getSubscreen() : null;

        var mutedColor = isMono ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;
        var pausedColor = isMono ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW;

        var movingMs = (info != null && info.timerTime != null) ? info.timerTime as Number : 0;
        var elapsedMs = (info != null && info.elapsedTime != null) ? info.elapsedTime as Number : 0;
        var breakMs = elapsedMs - movingMs;
        if (breakMs < 0) {
            breakMs = 0;
        }

        var now = System.getClockTime();
        var clockStr = DriveFormat.formatClock(now.hour, now.min, is24Hour);

        if (subscreen != null
                && subscreen.x != null && subscreen.y != null
                && subscreen.width != null && subscreen.height != null) {
            drawSubscreenLayout(dc, subscreen, state, info, statute, isMono, movingMs, breakMs, clockStr);
            return;
        }

        var lx = (w * 0.28).toNumber();
        var rx = (w * 0.72).toNumber();
        var bottomLx = (w * 0.33).toNumber();
        var bottomRx = (w * 0.67).toNumber();

        // Status header + GPS indicator dot
        drawStatusHeader(dc, cx, (h * 0.11).toNumber(), Graphics.FONT_TINY, state, isMono);

        // Distance (hero). FONT_NUMBER_* only carries digit glyphs, so the
        // unit suffix and the "Press START" prompt are drawn with a text font.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (state == STATE_STOPPED) {
            drawCentered(dc, cx, (h * 0.28).toNumber(), Graphics.FONT_MEDIUM, _strPressStart);
        } else {
            drawDistanceHero(dc, cx, (h * 0.28).toNumber(), info, statute,
                Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_TINY);
        }

        // Moving time
        dc.setColor(
            state == STATE_PAUSED ? pausedColor : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        drawCentered(dc, cx, (h * 0.44).toNumber(), Graphics.FONT_SMALL, DriveFormat.formatTime(movingMs));

        // Break time = elapsed - moving
        dc.setColor(mutedColor, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, (h * 0.55).toNumber(), Graphics.FONT_XTINY,
            _strBreak + " " + DriveFormat.formatTime(breakMs));

        // Avg / max speed
        drawSpeedRow(dc, lx, rx, (h * 0.68).toNumber(), Graphics.FONT_SMALL, info, statute, mutedColor);

        // Waypoint count | clock (inset from bezel on round displays)
        drawWpClockRow(dc, bottomLx, bottomRx, (h * 0.82).toNumber(), Graphics.FONT_TINY, clockStr, mutedColor);
    }

    // Layout for watches with a circular top-right subscreen (Instinct 2/3 Solar/E,
    // Descent G1). Keeps the top-left band clear of the cutout and places WP inside it.
    private function drawSubscreenLayout(
        dc as Dc,
        sub as Graphics.BoundingBox,
        state as DriveState,
        info as Activity.Info?,
        statute as Boolean,
        isMono as Boolean,
        movingMs as Number,
        breakMs as Number,
        clockStr as String
    ) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var mutedColor = isMono ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;
        var pausedColor = isMono ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW;

        var sx = sub.x;
        var sy = sub.y;
        var sw = sub.width;
        var sh = sub.height;
        if (sx == null || sy == null || sw == null || sh == null) {
            return;
        }

        // Status + GPS dot to the left of the subscreen
        var headerCx = sx / 2;
        var headerY = sy + sh / 2;
        drawStatusHeader(dc, headerCx, headerY, Graphics.FONT_XTINY, state, isMono);

        // Waypoint count inside the circular subscreen
        var subCx = sx + sw / 2;
        var subCy = sy + sh / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, subCx, subCy, Graphics.FONT_XTINY,
            _strWp + " " + _activity.getWaypointCount().toString());

        // Distribute remaining rows below the subscreen
        var topY = sy + sh;
        var availH = h - topY;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var heroY = topY + (availH * 0.17).toNumber();
        if (state == STATE_STOPPED) {
            drawCentered(dc, cx, heroY, Graphics.FONT_SMALL, _strPressStart);
        } else {
            drawDistanceHero(dc, cx, heroY, info, statute,
                Graphics.FONT_NUMBER_MILD, Graphics.FONT_XTINY);
        }

        dc.setColor(
            state == STATE_PAUSED ? pausedColor : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        drawCentered(dc, cx, topY + (availH * 0.42).toNumber(), Graphics.FONT_TINY,
            DriveFormat.formatTime(movingMs));

        dc.setColor(mutedColor, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, topY + (availH * 0.58).toNumber(), Graphics.FONT_XTINY,
            _strBreak + " " + DriveFormat.formatTime(breakMs));

        drawSpeedRow(dc, (w * 0.27).toNumber(), (w * 0.73).toNumber(),
            topY + (availH * 0.74).toNumber(), Graphics.FONT_XTINY, info, statute, mutedColor);

        dc.setColor(mutedColor, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, topY + (availH * 0.90).toNumber(), Graphics.FONT_XTINY, clockStr);
    }

    // Draws a small GPS indicator dot (filled = locked, hollow = searching)
    // immediately to the left of the status label, centered around cx.
    private function drawStatusHeader(
        dc as Dc,
        cx as Number,
        y as Number,
        font as Graphics.FontType,
        state as DriveState,
        isMono as Boolean
    ) as Void {
        var activeColor = isMono ? Graphics.COLOR_WHITE : Graphics.COLOR_GREEN;
        var pausedColor = isMono ? Graphics.COLOR_WHITE : Graphics.COLOR_YELLOW;
        var mutedColor = isMono ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;

        var label;
        var labelColor;
        if (state == STATE_RUNNING) {
            label = _strDriving;
            labelColor = activeColor;
        } else if (state == STATE_PAUSED) {
            label = _strPaused;
            labelColor = pausedColor;
        } else {
            label = _strReady;
            labelColor = mutedColor;
        }

        var r = (dc.getHeight() / 64).toNumber();
        if (r < 3) {
            r = 3;
        } else if (r > 6) {
            r = 6;
        }
        var gap = r + 2;
        var textW = dc.getTextWidthInPixels(label, font);
        var totalW = (r * 2) + gap + textW;
        var startX = cx - totalW / 2;
        var dotX = startX + r;
        var textX = startX + (r * 2) + gap;

        if (_activity.hasGpsFix()) {
            dc.setColor(activeColor, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(dotX, y, r);
        } else {
            dc.setColor(pausedColor, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(dotX, y, r);
        }

        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, y, font, label,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawSpeedRow(
        dc as Dc,
        lx as Number,
        rx as Number,
        y as Number,
        font as Graphics.FontType,
        info as Activity.Info?,
        statute as Boolean,
        color as Graphics.ColorValue
    ) as Void {
        var avg = (info != null && info.averageSpeed != null)
            ? DriveFormat.speedText(info.averageSpeed as Float, statute)
            : "--";
        var mx = (info != null && info.maxSpeed != null)
            ? DriveFormat.speedText(info.maxSpeed as Float, statute)
            : "--";
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, lx, y, font, _strAvg + " " + avg);
        drawCentered(dc, rx, y, font, _strMax + " " + mx);
    }

    private function drawWpClockRow(
        dc as Dc,
        lx as Number,
        rx as Number,
        y as Number,
        font as Graphics.FontType,
        clockStr as String,
        color as Graphics.ColorValue
    ) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, lx, y, font, _strWp + " " + _activity.getWaypointCount().toString());
        drawCentered(dc, rx, y, font, clockStr);
    }

    private function drawCentered(dc as Dc, x as Number, y as Number, font as Graphics.FontType, text as String) as Void {
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Distance is drawn as `<NN.N> <unit>` with the number in a big
    // FONT_NUMBER_* face (digits only) and the unit suffix in a small text
    // font to its right. The pair is centered around cx.
    private function drawDistanceHero(
        dc as Dc,
        cx as Number,
        y as Number,
        info as Activity.Info?,
        statute as Boolean,
        numFont as Graphics.FontType,
        unitFont as Graphics.FontType
    ) as Void {
        var meters = (info != null && info.elapsedDistance != null) ? info.elapsedDistance as Float : 0.0;
        var value = DriveFormat.distanceValue(meters, statute);
        var unit = DriveFormat.distanceUnit(statute);
        var gap = 4;
        var numW = dc.getTextWidthInPixels(value, numFont);
        var unitW = dc.getTextWidthInPixels(unit, unitFont);
        var startX = cx - (numW + gap + unitW) / 2;
        dc.drawText(startX, y, numFont, value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(startX + numW + gap, y, unitFont, unit,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
