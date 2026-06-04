import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Dashboard layout (240x240 round, Fenix 6s):
//          DRIVING          <- status (green/yellow/gray)
//          125.4 km         <- distance + unit (hero)
//          2:34:12          <- moving time
//        break 0:18         <- break time (= elapsed - moving)
//     avg 48      max 112   <- avg / max speed (km/h or mph)
//     WP 3        14:35     <- waypoint count | time of day
class DriveView extends WatchUi.View {
    private var _activity as DriveActivity;
    private var _timer as Timer.Timer?;

    public function initialize(activity as DriveActivity) {
        View.initialize();
        _activity = activity;
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
        var lx = w * 0.28;
        var rx = w * 0.72;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var state = _activity.getState();
        var info = Activity.getActivityInfo();
        var statute = System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;

        // Status header
        var label;
        var labelColor;
        if (state == STATE_RUNNING) {
            label = "DRIVING";
            labelColor = Graphics.COLOR_GREEN;
        } else if (state == STATE_PAUSED) {
            label = "PAUSED";
            labelColor = Graphics.COLOR_YELLOW;
        } else {
            label = "READY";
            labelColor = Graphics.COLOR_LT_GRAY;
        }
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, h * 0.10, Graphics.FONT_TINY, label);

        // Distance (hero). FONT_NUMBER_* only carries digit glyphs, so the
        // unit suffix and the "Press START" prompt are drawn with a text font.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (state == STATE_STOPPED) {
            drawCentered(dc, cx, h * 0.27, Graphics.FONT_MEDIUM, "Press START");
        } else {
            drawDistanceHero(dc, cx, h * 0.27, info, statute);
        }

        // Moving time
        var movingMs = (info != null && info.timerTime != null) ? info.timerTime : 0;
        dc.setColor(
            state == STATE_PAUSED ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        drawCentered(dc, cx, h * 0.43, Graphics.FONT_SMALL, formatTime(movingMs));

        // Break time = elapsed - moving
        var elapsedMs = (info != null && info.elapsedTime != null) ? info.elapsedTime : 0;
        var breakMs = elapsedMs - movingMs;
        if (breakMs < 0) { breakMs = 0; }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, cx, h * 0.54, Graphics.FONT_XTINY, "break " + formatTime(breakMs));

        // Avg / max speed
        drawSpeedRow(dc, lx, rx, h * 0.68, info, statute);

        // Waypoint count | clock
        drawWpClockRow(dc, lx, rx, h * 0.85, info);
    }

    private function drawSpeedRow(dc as Dc, lx as Numeric, rx as Numeric, y as Numeric, info as Activity.Info?, statute as Boolean) as Void {
        var avg = (info != null && info.averageSpeed != null) ? speedText(info.averageSpeed as Float, statute) : "--";
        var mx  = (info != null && info.maxSpeed != null) ? speedText(info.maxSpeed as Float, statute) : "--";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, lx, y, Graphics.FONT_SMALL, "avg " + avg);
        drawCentered(dc, rx, y, Graphics.FONT_SMALL, "max " + mx);
    }

    private function drawWpClockRow(dc as Dc, lx as Numeric, rx as Numeric, y as Numeric, info as Activity.Info?) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, lx, y, Graphics.FONT_SMALL,
            "WP " + _activity.getWaypointCount().toString());
        drawCentered(dc, rx, y, Graphics.FONT_SMALL, formatClock());
    }

    private function drawCentered(dc as Dc, x as Numeric, y as Numeric, font as Graphics.FontType, text as String) as Void {
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Distance is drawn as `<NN.N> <unit>` with the number in the big
    // FONT_NUMBER_MEDIUM face (digits only) and the unit suffix in a
    // small text font to its right. The pair is centered around cx.
    private function drawDistanceHero(dc as Dc, cx as Number, y as Numeric, info as Activity.Info?, statute as Boolean) as Void {
        var meters = (info != null && info.elapsedDistance != null) ? info.elapsedDistance as Float : 0.0;
        var value;
        var unit;
        if (statute) {
            var miles = meters / 1609.344;
            value = miles < 100.0 ? miles.format("%.1f") : miles.format("%.0f");
            unit = "mi";
        } else {
            var km = meters / 1000.0;
            value = km < 100.0 ? km.format("%.1f") : km.format("%.0f");
            unit = "km";
        }
        var numFont = Graphics.FONT_NUMBER_MEDIUM;
        var unitFont = Graphics.FONT_TINY;
        var gap = 4;
        var numW = dc.getTextWidthInPixels(value, numFont);
        var unitW = dc.getTextWidthInPixels(unit, unitFont);
        var startX = cx - (numW + gap + unitW) / 2;
        dc.drawText(startX, y, numFont, value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(startX + numW + gap, y, unitFont, unit,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // m/s -> km/h or mph, rounded to the nearest integer.
    private function speedText(metersPerSec as Float, statute as Boolean) as String {
        var v = statute ? metersPerSec * 2.236936 : metersPerSec * 3.6;
        return v.format("%.0f");
    }

    // Format milliseconds as M:SS, or H:MM:SS once past an hour.
    private function formatTime(ms as Number) as String {
        var totalSec = ms / 1000;
        var hours = totalSec / 3600;
        var mins = (totalSec % 3600) / 60;
        var secs = totalSec % 60;
        if (hours > 0) {
            return Lang.format("$1$:$2$:$3$", [hours, mins.format("%02d"), secs.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [mins.format("%01d"), secs.format("%02d")]);
    }

    private function formatClock() as String {
        var now = System.getClockTime();
        var hour = now.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
            return Lang.format("$1$:$2$", [hour, now.min.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [hour.format("%02d"), now.min.format("%02d")]);
    }
}
