import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;

(:test)
function testFormatTime(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage("0:00", DriveFormat.formatTime(0), "zero ms");
    Test.assertEqualMessage("0:00", DriveFormat.formatTime(-5000), "negative ms clamps to 0");
    Test.assertEqualMessage("0:05", DriveFormat.formatTime(5000), "5 seconds");
    Test.assertEqualMessage("12:34", DriveFormat.formatTime((12 * 60 + 34) * 1000), "mm:ss");
    Test.assertEqualMessage("1:00:00", DriveFormat.formatTime(3600 * 1000), "exact hour");
    Test.assertEqualMessage("2:05:09", DriveFormat.formatTime((2 * 3600 + 5 * 60 + 9) * 1000), "h:mm:ss");
    return true;
}

(:test)
function testFormatDistance(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage("0.0", DriveFormat.distanceValue(0.0, false), "0 km");
    Test.assertEqualMessage("0.0", DriveFormat.distanceValue(-100.0, false), "negative meters clamps");
    Test.assertEqualMessage("12.3", DriveFormat.distanceValue(12340.0, false), "<100 km has 1 decimal");
    Test.assertEqualMessage("125", DriveFormat.distanceValue(125400.0, false), ">=100 km is whole");
    Test.assertEqualMessage("1.0", DriveFormat.distanceValue(1609.344, true), "1 mile");
    Test.assertEqualMessage("100", DriveFormat.distanceValue(160934.4, true), "100 miles is whole");
    Test.assertEqualMessage("km", DriveFormat.distanceUnit(false), "metric unit");
    Test.assertEqualMessage("mi", DriveFormat.distanceUnit(true), "statute unit");
    return true;
}

(:test)
function testFormatSpeed(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage("0", DriveFormat.speedText(0.0, false), "0 km/h");
    Test.assertEqualMessage("0", DriveFormat.speedText(-5.0, false), "negative speed clamps");
    Test.assertEqualMessage("36", DriveFormat.speedText(10.0, false), "10 m/s -> 36 km/h");
    Test.assertEqualMessage("60", DriveFormat.speedText(26.8224, true), "60 mph");
    return true;
}

(:test)
function testFormatClock(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage("00:05", DriveFormat.formatClock(0, 5, true), "24h midnight");
    Test.assertEqualMessage("14:35", DriveFormat.formatClock(14, 35, true), "24h afternoon");
    Test.assertEqualMessage("12:05", DriveFormat.formatClock(0, 5, false), "12h midnight");
    Test.assertEqualMessage("12:00", DriveFormat.formatClock(12, 0, false), "12h noon");
    Test.assertEqualMessage("2:35", DriveFormat.formatClock(14, 35, false), "12h afternoon");
    return true;
}

(:test)
function testDriveActivityInitialState(logger as Test.Logger) as Boolean {
    var a = new DriveActivity();
    Test.assertEqualMessage(STATE_STOPPED, a.getState(), "initial state is stopped");
    Test.assertMessage(!a.isActive(), "initially inactive");
    Test.assertEqualMessage(0, a.getWaypointCount(), "initial waypoints is 0");
    Test.assertEqualMessage(Position.QUALITY_NOT_AVAILABLE, a.getGpsAccuracy(), "initial gps quality");
    Test.assertMessage(!a.hasGpsFix(), "initially no gps fix");
    Test.assertMessage(!a.dropWaypoint(), "dropWaypoint returns false when stopped");
    return true;
}
