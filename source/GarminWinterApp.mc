import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class GarminWinterApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new GarminWinterView()];
    }
}

class GarminWinterView extends WatchUi.WatchFace {
    // Frost Crystal font colors
    private const FONT_COLOR = 0xFFFFFF;      // White - main text
    private const FONT_GLOW = 0x8090C0;       // Blue-purple glow/shadow
    private const SNOW_COLOR = 0xFFFFFF;      // White snowflakes

    private var _background as BitmapResource?;
    private var _isLowPower as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _background = WatchUi.loadResource(Rez.Drawables.Background) as BitmapResource;
    }

    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        // Draw background image scaled to screen size
        if (_background != null) {
            dc.drawScaledBitmap(0, 0, width, height, _background);
        }

        // Draw falling snow
        if (!_isLowPower) {
            drawFallingSnow(dc, width, height, clockTime.sec);
        }

        // Draw time with Frost Crystal font
        drawFrostCrystalTime(dc, centerX, centerY - 10, clockTime);

        // Draw date with Frost Crystal font
        drawFrostCrystalDate(dc, centerX, centerY + 28);
    }

    // Draw falling snowflakes
    function drawFallingSnow(dc as Dc, width as Number, height as Number, seconds as Number) as Void {
        dc.setColor(SNOW_COLOR, Graphics.COLOR_TRANSPARENT);
        var snowLimit = (height * 0.75).toNumber();

        for (var i = 0; i < 20; i++) {
            var baseX = ((i * 37 + 11) % width);
            var baseY = ((i * 23 + 5) % snowLimit);
            var offset = ((seconds * 4 + i * 17) % 80);
            var animY = (baseY + offset * 3) % snowLimit;
            var animX = baseX + ((offset / 10) % 8) - 4;
            var size = (i % 3) + 2;
            dc.fillRectangle(animX, animY, size, size);
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // FROST CRYSTAL FONT - Custom designed for Winter Scene watchface
    // Design: Angular ice-crystal shapes with blue glow effect
    // Grid: 7 wide x 9 tall for main digits
    // ═══════════════════════════════════════════════════════════════════

    // Draw a Frost Crystal digit with glow effect (7x9 grid)
    function drawFrostDigit(dc as Dc, digit as Number, x as Number, y as Number, pixelSize as Number) as Void {
        // Frost Crystal digit patterns (7 wide x 9 tall)
        // Design features: angular cuts, ice-crystal aesthetic, bold strokes
        var patterns = [
            // 0 - Oval with angular cuts at corners
            [[0,1,1,1,1,1,0],
             [1,1,0,0,0,1,1],
             [1,0,0,0,0,0,1],
             [1,0,0,0,0,0,1],
             [1,0,0,0,0,0,1],
             [1,0,0,0,0,0,1],
             [1,0,0,0,0,0,1],
             [1,1,0,0,0,1,1],
             [0,1,1,1,1,1,0]],
            // 1 - Crystal pillar with angular base
            [[0,0,0,1,0,0,0],
             [0,0,1,1,0,0,0],
             [0,1,0,1,0,0,0],
             [0,0,0,1,0,0,0],
             [0,0,0,1,0,0,0],
             [0,0,0,1,0,0,0],
             [0,0,0,1,0,0,0],
             [0,0,0,1,0,0,0],
             [0,1,1,1,1,1,0]],
            // 2 - Sharp angular turns
            [[0,1,1,1,1,1,0],
             [1,1,0,0,0,1,1],
             [0,0,0,0,0,0,1],
             [0,0,0,0,0,1,1],
             [0,0,1,1,1,0,0],
             [0,1,1,0,0,0,0],
             [1,0,0,0,0,0,0],
             [1,1,0,0,0,1,1],
             [0,1,1,1,1,1,0]],
            // 3 - Double crystal curves
            [[0,1,1,1,1,1,0],
             [1,1,0,0,0,1,1],
             [0,0,0,0,0,0,1],
             [0,0,0,0,0,1,1],
             [0,0,1,1,1,0,0],
             [0,0,0,0,0,1,1],
             [0,0,0,0,0,0,1],
             [1,1,0,0,0,1,1],
             [0,1,1,1,1,1,0]],
            // 4 - Angular ice shard
            [[0,0,0,0,1,0,0],
             [0,0,0,1,1,0,0],
             [0,0,1,0,1,0,0],
             [0,1,0,0,1,0,0],
             [1,0,0,0,1,0,0],
             [1,1,1,1,1,1,1],
             [0,0,0,0,1,0,0],
             [0,0,0,0,1,0,0],
             [0,0,0,0,1,0,0]],
            // 5 - Bold crystal block
            [[1,1,1,1,1,1,1],
             [1,0,0,0,0,0,0],
             [1,0,0,0,0,0,0],
             [1,1,1,1,1,0,0],
             [0,0,0,0,1,1,0],
             [0,0,0,0,0,1,1],
             [0,0,0,0,0,0,1],
             [1,1,0,0,0,1,1],
             [0,1,1,1,1,1,0]],
            // 6 - Flowing crystal
            [[0,0,1,1,1,1,0],
             [0,1,1,0,0,0,0],
             [1,0,0,0,0,0,0],
             [1,0,1,1,1,0,0],
             [1,1,0,0,0,1,0],
             [1,0,0,0,0,1,1],
             [1,0,0,0,0,0,1],
             [1,1,0,0,0,1,1],
             [0,1,1,1,1,1,0]],
            // 7 - Sharp ice angle
            [[1,1,1,1,1,1,1],
             [1,1,0,0,0,1,1],
             [0,0,0,0,0,1,0],
             [0,0,0,0,1,0,0],
             [0,0,0,1,0,0,0],
             [0,0,1,0,0,0,0],
             [0,0,1,0,0,0,0],
             [0,0,1,0,0,0,0],
             [0,0,1,0,0,0,0]],
            // 8 - Double crystal rings
            [[0,1,1,1,1,1,0],
             [1,1,0,0,0,1,1],
             [1,0,0,0,0,0,1],
             [1,1,0,0,0,1,1],
             [0,1,1,1,1,1,0],
             [1,1,0,0,0,1,1],
             [1,0,0,0,0,0,1],
             [1,1,0,0,0,1,1],
             [0,1,1,1,1,1,0]],
            // 9 - Inverted crystal 6
            [[0,1,1,1,1,1,0],
             [1,1,0,0,0,1,1],
             [1,0,0,0,0,0,1],
             [1,1,0,0,0,0,1],
             [0,1,1,1,1,0,1],
             [0,0,0,0,0,0,1],
             [0,0,0,0,0,1,1],
             [0,0,0,0,1,1,0],
             [0,1,1,1,1,0,0]]
        ];

        var pattern = patterns[digit];

        // Draw blue glow/shadow first (offset by 2 pixels)
        dc.setColor(FONT_GLOW, Graphics.COLOR_TRANSPARENT);
        for (var row = 0; row < 9; row++) {
            for (var col = 0; col < 7; col++) {
                if (pattern[row][col] == 1) {
                    dc.fillRectangle(x + col * pixelSize + 2, y + row * pixelSize + 2, pixelSize, pixelSize);
                }
            }
        }

        // Draw main white digit on top
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
        for (var row = 0; row < 9; row++) {
            for (var col = 0; col < 7; col++) {
                if (pattern[row][col] == 1) {
                    dc.fillRectangle(x + col * pixelSize, y + row * pixelSize, pixelSize, pixelSize);
                }
            }
        }
    }

    // Draw Frost Crystal colon (vertical ice crystals)
    function drawFrostColon(dc as Dc, x as Number, y as Number, pixelSize as Number) as Void {
        // Glow
        dc.setColor(FONT_GLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 2, y + pixelSize * 2 + 2, pixelSize * 2, pixelSize * 2);
        dc.fillRectangle(x + 2, y + pixelSize * 5 + 2, pixelSize * 2, pixelSize * 2);

        // Main dots
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y + pixelSize * 2, pixelSize * 2, pixelSize * 2);
        dc.fillRectangle(x, y + pixelSize * 5, pixelSize * 2, pixelSize * 2);
    }

    // Main time drawing function
    function drawFrostCrystalTime(dc as Dc, centerX as Number, centerY as Number, clockTime as System.ClockTime) as Void {
        var hour = clockTime.hour;
        var min = clockTime.min;

        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }

        var h1 = hour / 10;
        var h2 = hour % 10;
        var m1 = min / 10;
        var m2 = min % 10;

        var pixelSize = 4;  // Each "pixel" is 4x4
        var digitWidth = 7 * pixelSize;  // 7 columns
        var colonWidth = pixelSize * 3;
        var spacing = pixelSize * 2;
        var totalWidth = digitWidth * 4 + colonWidth + spacing * 4;
        var startX = centerX - totalWidth / 2;
        var startY = centerY - (9 * pixelSize) / 2;

        drawFrostDigit(dc, h1, startX, startY, pixelSize);
        startX += digitWidth + spacing;
        drawFrostDigit(dc, h2, startX, startY, pixelSize);
        startX += digitWidth + spacing;
        drawFrostColon(dc, startX, startY, pixelSize);
        startX += colonWidth + spacing;
        drawFrostDigit(dc, m1, startX, startY, pixelSize);
        startX += digitWidth + spacing;
        drawFrostDigit(dc, m2, startX, startY, pixelSize);
    }

    // ═══════════════════════════════════════════════════════════════════
    // FROST CRYSTAL LETTERS - For date display (4x6 grid)
    // ═══════════════════════════════════════════════════════════════════

    function drawFrostLetter(dc as Dc, letter as String, x as Number, y as Number, pixelSize as Number) as Number {
        var pattern = null;
        var width = 4;

        // Frost Crystal letter patterns (4 wide x 6 tall)
        if (letter.equals("S")) {
            pattern = [[0,1,1,1], [1,0,0,0], [0,1,1,0], [0,0,0,1], [0,0,0,1], [1,1,1,0]];
        } else if (letter.equals("u")) {
            pattern = [[0,0,0,0], [1,0,0,1], [1,0,0,1], [1,0,0,1], [1,0,0,1], [0,1,1,0]];
        } else if (letter.equals("n")) {
            pattern = [[0,0,0,0], [1,1,1,0], [1,0,0,1], [1,0,0,1], [1,0,0,1], [1,0,0,1]];
        } else if (letter.equals("M")) {
            pattern = [[1,0,0,1], [1,1,1,1], [1,0,0,1], [1,0,0,1], [1,0,0,1], [1,0,0,1]];
        } else if (letter.equals("o")) {
            pattern = [[0,0,0,0], [0,1,1,0], [1,0,0,1], [1,0,0,1], [1,0,0,1], [0,1,1,0]];
        } else if (letter.equals("T")) {
            pattern = [[1,1,1,1], [0,1,1,0], [0,1,1,0], [0,1,1,0], [0,1,1,0], [0,1,1,0]];
        } else if (letter.equals("e")) {
            pattern = [[0,0,0,0], [0,1,1,0], [1,0,0,1], [1,1,1,1], [1,0,0,0], [0,1,1,1]];
        } else if (letter.equals("W")) {
            pattern = [[1,0,0,1], [1,0,0,1], [1,0,0,1], [1,0,0,1], [1,1,1,1], [1,0,0,1]];
        } else if (letter.equals("d")) {
            pattern = [[0,0,0,1], [0,0,0,1], [0,1,1,1], [1,0,0,1], [1,0,0,1], [0,1,1,1]];
        } else if (letter.equals("h")) {
            pattern = [[1,0,0,0], [1,0,0,0], [1,1,1,0], [1,0,0,1], [1,0,0,1], [1,0,0,1]];
        } else if (letter.equals("F")) {
            pattern = [[1,1,1,1], [1,0,0,0], [1,1,1,0], [1,0,0,0], [1,0,0,0], [1,0,0,0]];
        } else if (letter.equals("r")) {
            pattern = [[0,0,0,0], [1,0,1,1], [1,1,0,0], [1,0,0,0], [1,0,0,0], [1,0,0,0]];
        } else if (letter.equals("i")) {
            pattern = [[0,1,0,0], [0,0,0,0], [0,1,0,0], [0,1,0,0], [0,1,0,0], [0,1,0,0]];
            width = 2;
        } else if (letter.equals("a")) {
            pattern = [[0,0,0,0], [0,1,1,1], [0,0,0,1], [0,1,1,1], [1,0,0,1], [0,1,1,1]];
        } else if (letter.equals("t")) {
            pattern = [[0,1,0,0], [1,1,1,0], [0,1,0,0], [0,1,0,0], [0,1,0,0], [0,0,1,1]];
            width = 3;
        } else if (letter.equals(" ")) {
            return x + pixelSize * 2;
        } else {
            return x + pixelSize * 4;
        }

        if (pattern != null) {
            // Glow
            dc.setColor(FONT_GLOW, Graphics.COLOR_TRANSPARENT);
            for (var row = 0; row < 6; row++) {
                for (var col = 0; col < width; col++) {
                    if (pattern[row][col] == 1) {
                        dc.fillRectangle(x + col * pixelSize + 1, y + row * pixelSize + 1, pixelSize, pixelSize);
                    }
                }
            }
            // Main
            dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
            for (var row = 0; row < 6; row++) {
                for (var col = 0; col < width; col++) {
                    if (pattern[row][col] == 1) {
                        dc.fillRectangle(x + col * pixelSize, y + row * pixelSize, pixelSize, pixelSize);
                    }
                }
            }
        }

        return x + (width + 1) * pixelSize;
    }

    // Frost Crystal small digit (4x6 grid)
    function drawFrostSmallDigit(dc as Dc, digit as Number, x as Number, y as Number, pixelSize as Number) as Void {
        var patterns = [
            [[0,1,1,0], [1,0,0,1], [1,0,0,1], [1,0,0,1], [1,0,0,1], [0,1,1,0]],  // 0
            [[0,0,1,0], [0,1,1,0], [0,0,1,0], [0,0,1,0], [0,0,1,0], [0,1,1,1]],  // 1
            [[0,1,1,0], [1,0,0,1], [0,0,1,0], [0,1,0,0], [1,0,0,0], [1,1,1,1]],  // 2
            [[1,1,1,0], [0,0,0,1], [0,1,1,0], [0,0,0,1], [0,0,0,1], [1,1,1,0]],  // 3
            [[0,0,1,0], [0,1,1,0], [1,0,1,0], [1,1,1,1], [0,0,1,0], [0,0,1,0]],  // 4
            [[1,1,1,1], [1,0,0,0], [1,1,1,0], [0,0,0,1], [0,0,0,1], [1,1,1,0]],  // 5
            [[0,1,1,0], [1,0,0,0], [1,1,1,0], [1,0,0,1], [1,0,0,1], [0,1,1,0]],  // 6
            [[1,1,1,1], [0,0,0,1], [0,0,1,0], [0,1,0,0], [0,1,0,0], [0,1,0,0]],  // 7
            [[0,1,1,0], [1,0,0,1], [0,1,1,0], [1,0,0,1], [1,0,0,1], [0,1,1,0]],  // 8
            [[0,1,1,0], [1,0,0,1], [0,1,1,1], [0,0,0,1], [0,0,1,0], [0,1,0,0]]   // 9
        ];

        var pattern = patterns[digit];

        // Glow
        dc.setColor(FONT_GLOW, Graphics.COLOR_TRANSPARENT);
        for (var row = 0; row < 6; row++) {
            for (var col = 0; col < 4; col++) {
                if (pattern[row][col] == 1) {
                    dc.fillRectangle(x + col * pixelSize + 1, y + row * pixelSize + 1, pixelSize, pixelSize);
                }
            }
        }

        // Main
        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
        for (var row = 0; row < 6; row++) {
            for (var col = 0; col < 4; col++) {
                if (pattern[row][col] == 1) {
                    dc.fillRectangle(x + col * pixelSize, y + row * pixelSize, pixelSize, pixelSize);
                }
            }
        }
    }

    // Date drawing function
    function drawFrostCrystalDate(dc as Dc, centerX as Number, centerY as Number) as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);

        var dow = info.day_of_week;
        var dayStr = "";
        if (dow == 1) { dayStr = "Sun"; }
        else if (dow == 2) { dayStr = "Mon"; }
        else if (dow == 3) { dayStr = "Tue"; }
        else if (dow == 4) { dayStr = "Wed"; }
        else if (dow == 5) { dayStr = "Thu"; }
        else if (dow == 6) { dayStr = "Fri"; }
        else if (dow == 7) { dayStr = "Sat"; }

        var day = info.day;
        var pixelSize = 3;

        // Calculate width
        var totalWidth = 3 * 5 * pixelSize + 3 * pixelSize + 2 * 5 * pixelSize;
        var startX = centerX - totalWidth / 2;

        // Draw day name
        for (var i = 0; i < dayStr.length(); i++) {
            startX = drawFrostLetter(dc, dayStr.substring(i, i + 1), startX, centerY, pixelSize);
        }

        startX += pixelSize * 2;

        // Draw day number
        var d1 = day / 10;
        var d2 = day % 10;

        if (d1 > 0) {
            drawFrostSmallDigit(dc, d1, startX, centerY, pixelSize);
            startX += 5 * pixelSize;
        }
        drawFrostSmallDigit(dc, d2, startX, centerY, pixelSize);
    }

    function onEnterSleep() as Void {
        _isLowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isLowPower = false;
        WatchUi.requestUpdate();
    }

    function onPartialUpdate(dc as Dc) as Void {
    }
}
