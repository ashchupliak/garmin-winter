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
    // Colors from SVG
    private const BG_COLOR = 0x192138;           // Dark night blue
    private const MOUNTAIN_FAR = 0x2E3C5C;       // Far mountains
    private const MOUNTAIN_MID = 0x3C4F78;       // Mid mountains
    private const SNOW_WHITE = 0xFFFFFF;         // Pure white snow
    private const SNOW_SHADOW = 0xD0E0F0;        // Snow shadow
    private const TREE_DARK = 0x0F2040;          // Dark tree
    private const TREE_LIGHT = 0x1A3A60;         // Light tree
    private const FONT_COLOR = 0xFFFFFF;         // White text

    private var _isLowPower as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        // Clear with background color
        dc.setColor(BG_COLOR, BG_COLOR);
        dc.clear();

        // Draw the winter scene
        drawMountains(dc, width, height);
        drawSnowGround(dc, width, height);
        drawTrees(dc, width, height);

        // Draw falling snowflakes
        if (!_isLowPower) {
            drawSnowflakes(dc, width, height, clockTime.sec);
        }

        // Draw time with pixel font
        drawFrostTime(dc, centerX, centerY, clockTime);

        // Draw date
        drawFrostDate(dc, centerX, centerY);
    }

    // Fill a triangle using horizontal lines
    function fillTriangle(dc as Dc, x1 as Number, y1 as Number, x2 as Number, y2 as Number, x3 as Number, y3 as Number) as Void {
        // Sort points by Y coordinate
        var points = [[x1, y1], [x2, y2], [x3, y3]];
        for (var i = 0; i < 2; i++) {
            for (var j = i + 1; j < 3; j++) {
                if (points[j][1] < points[i][1]) {
                    var temp = points[i];
                    points[i] = points[j];
                    points[j] = temp;
                }
            }
        }

        var topX = points[0][0];
        var topY = points[0][1];
        var midX = points[1][0];
        var midY = points[1][1];
        var botX = points[2][0];
        var botY = points[2][1];

        // Fill top half
        if (midY != topY) {
            for (var y = topY; y <= midY; y++) {
                var t1 = (y - topY).toFloat() / (midY - topY).toFloat();
                var t2 = (y - topY).toFloat() / (botY - topY).toFloat();
                var xStart = (topX + t1 * (midX - topX)).toNumber();
                var xEnd = (topX + t2 * (botX - topX)).toNumber();
                if (xStart > xEnd) {
                    var tmp = xStart;
                    xStart = xEnd;
                    xEnd = tmp;
                }
                dc.drawLine(xStart, y, xEnd, y);
            }
        }

        // Fill bottom half
        if (botY != midY) {
            for (var y = midY; y <= botY; y++) {
                var t1 = (y - midY).toFloat() / (botY - midY).toFloat();
                var t2 = (y - topY).toFloat() / (botY - topY).toFloat();
                var xStart = (midX + t1 * (botX - midX)).toNumber();
                var xEnd = (topX + t2 * (botX - topX)).toNumber();
                if (xStart > xEnd) {
                    var tmp = xStart;
                    xStart = xEnd;
                    xEnd = tmp;
                }
                dc.drawLine(xStart, y, xEnd, y);
            }
        }
    }

    // Draw layered mountains
    function drawMountains(dc as Dc, width as Number, height as Number) as Void {
        var scale = width.toFloat() / 640.0;

        // Far mountain - simple triangular shapes
        dc.setColor(MOUNTAIN_FAR, Graphics.COLOR_TRANSPARENT);

        // Mountain 1 (left)
        fillTriangle(dc,
            0, height,
            (150 * scale).toNumber(), (300 * scale).toNumber(),
            (300 * scale).toNumber(), height);

        // Mountain 2 (right)
        fillTriangle(dc,
            (300 * scale).toNumber(), height,
            (450 * scale).toNumber(), (300 * scale).toNumber(),
            width, height);

        // Mid mountains
        fillTriangle(dc,
            0, height,
            (100 * scale).toNumber(), (250 * scale).toNumber(),
            (250 * scale).toNumber(), height);

        fillTriangle(dc,
            (250 * scale).toNumber(), height,
            (400 * scale).toNumber(), (250 * scale).toNumber(),
            width, height);

        // Front mountain (brighter)
        dc.setColor(MOUNTAIN_MID, Graphics.COLOR_TRANSPARENT);
        fillTriangle(dc,
            (100 * scale).toNumber(), height,
            (200 * scale).toNumber(), (100 * scale).toNumber(),
            (400 * scale).toNumber(), height);

        fillTriangle(dc,
            (350 * scale).toNumber(), height,
            (500 * scale).toNumber(), (200 * scale).toNumber(),
            width, height);
    }

    // Draw snow on ground
    function drawSnowGround(dc as Dc, width as Number, height as Number) as Void {
        var scale = width.toFloat() / 640.0;
        var snowTop = (height * 0.7).toNumber();

        // Main snow - fill rectangle at bottom
        dc.setColor(SNOW_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, snowTop, width, height - snowTop);

        // Snow curves - draw arc at top
        for (var x = 0; x < width; x++) {
            var wave = (Math.sin(x.toFloat() / 50.0) * 15).toNumber();
            dc.drawLine(x, snowTop + wave, x, snowTop + wave + 5);
        }

        // Snow shadow in middle
        dc.setColor(SNOW_SHADOW, Graphics.COLOR_TRANSPARENT);
        var shadowTop = (height * 0.78).toNumber();
        var shadowLeft = (width * 0.15).toNumber();
        var shadowRight = (width * 0.85).toNumber();
        dc.fillRectangle(shadowLeft, shadowTop, shadowRight - shadowLeft, height - shadowTop);
    }

    // Draw pine trees
    function drawTrees(dc as Dc, width as Number, height as Number) as Void {
        var scale = width.toFloat() / 640.0;

        // Left tree (dark)
        dc.setColor(TREE_DARK, Graphics.COLOR_TRANSPARENT);
        fillTriangle(dc,
            0, height,
            (50 * scale).toNumber(), (100 * scale).toNumber(),
            (100 * scale).toNumber(), height);

        // Left tree (light overlay)
        dc.setColor(TREE_LIGHT, Graphics.COLOR_TRANSPARENT);
        fillTriangle(dc,
            0, height,
            (50 * scale).toNumber(), (180 * scale).toNumber(),
            (100 * scale).toNumber(), height);

        // Right tree (dark)
        dc.setColor(TREE_DARK, Graphics.COLOR_TRANSPARENT);
        fillTriangle(dc,
            (540 * scale).toNumber(), height,
            (590 * scale).toNumber(), (100 * scale).toNumber(),
            width, height);

        // Right tree (light overlay)
        dc.setColor(TREE_LIGHT, Graphics.COLOR_TRANSPARENT);
        fillTriangle(dc,
            (540 * scale).toNumber(), height,
            (590 * scale).toNumber(), (180 * scale).toNumber(),
            width, height);

        // Small middle trees
        dc.setColor(0x1A2A48, Graphics.COLOR_TRANSPARENT);
        fillTriangle(dc,
            (250 * scale).toNumber(), height,
            (300 * scale).toNumber(), (350 * scale).toNumber(),
            (350 * scale).toNumber(), height);

        fillTriangle(dc,
            (400 * scale).toNumber(), height,
            (450 * scale).toNumber(), (350 * scale).toNumber(),
            (500 * scale).toNumber(), height);
    }

    // Draw animated snowflakes
    function drawSnowflakes(dc as Dc, width as Number, height as Number, seconds as Number) as Void {
        dc.setColor(SNOW_WHITE, Graphics.COLOR_TRANSPARENT);
        var pixelSize = 3;
        var snowTop = (height * 0.7).toNumber();

        // Static snowflake base positions (scaled from 640 space)
        var basePositions = [
            [50, 50], [150, 80], [250, 30], [350, 100],
            [450, 60], [550, 120], [20, 180], [600, 200],
            [100, 150], [200, 90], [300, 170], [400, 40],
            [500, 130], [80, 220], [180, 250], [280, 200],
            [380, 230], [480, 190], [580, 240], [30, 280]
        ];

        var scale = width.toFloat() / 640.0;

        for (var i = 0; i < basePositions.size(); i++) {
            var baseX = (basePositions[i][0] * scale).toNumber();
            var baseY = (basePositions[i][1] * scale).toNumber();

            // Animate based on seconds - gentle falling effect
            var offset = ((seconds * 3 + i * 7) % 100);
            var animY = (baseY + offset * 2) % snowTop;
            var animX = baseX + ((offset / 10) % 5) - 2;

            dc.fillRectangle(animX, animY, pixelSize, pixelSize);
        }
    }

    // Draw pixel digit
    function drawPixelDigit(dc as Dc, digit as Number, x as Number, y as Number, pixelSize as Number) as Void {
        var patterns = [
            // 0
            [[1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1]],
            // 1
            [[0,0,1,0,0], [0,1,1,0,0], [0,0,1,0,0], [0,0,1,0,0], [0,0,1,0,0], [0,0,1,0,0], [0,1,1,1,0]],
            // 2
            [[1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1], [1,0,0,0,0], [1,0,0,0,0], [1,1,1,1,1]],
            // 3
            [[1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1]],
            // 4
            [[1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [0,0,0,0,1]],
            // 5
            [[1,1,1,1,1], [1,0,0,0,0], [1,0,0,0,0], [1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1]],
            // 6
            [[1,1,1,1,1], [1,0,0,0,0], [1,0,0,0,0], [1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1]],
            // 7
            [[1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [0,0,0,1,0], [0,0,1,0,0], [0,0,1,0,0], [0,0,1,0,0]],
            // 8
            [[1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1]],
            // 9
            [[1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1]]
        ];

        var pattern = patterns[digit];
        for (var row = 0; row < 7; row++) {
            for (var col = 0; col < 5; col++) {
                if (pattern[row][col] == 1) {
                    dc.fillRectangle(x + col * pixelSize, y + row * pixelSize, pixelSize - 1, pixelSize - 1);
                }
            }
        }
    }

    // Draw colon
    function drawColon(dc as Dc, x as Number, y as Number, pixelSize as Number) as Void {
        dc.fillRectangle(x, y + pixelSize * 2, pixelSize - 1, pixelSize - 1);
        dc.fillRectangle(x, y + pixelSize * 4, pixelSize - 1, pixelSize - 1);
    }

    // Draw time display
    function drawFrostTime(dc as Dc, centerX as Number, centerY as Number, clockTime as System.ClockTime) as Void {
        var hour = clockTime.hour;
        var min = clockTime.min;

        // 12-hour format
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }

        var h1 = hour / 10;
        var h2 = hour % 10;
        var m1 = min / 10;
        var m2 = min % 10;

        var pixelSize = 6;
        var digitWidth = 5 * pixelSize;
        var colonWidth = pixelSize;
        var spacing = pixelSize;
        var totalWidth = digitWidth * 4 + colonWidth + spacing * 4;
        var startX = centerX - totalWidth / 2;
        var startY = centerY - 30;

        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);

        // Draw digits and colon
        drawPixelDigit(dc, h1, startX, startY, pixelSize);
        startX += digitWidth + spacing;
        drawPixelDigit(dc, h2, startX, startY, pixelSize);
        startX += digitWidth + spacing;
        drawColon(dc, startX, startY, pixelSize);
        startX += colonWidth + spacing;
        drawPixelDigit(dc, m1, startX, startY, pixelSize);
        startX += digitWidth + spacing;
        drawPixelDigit(dc, m2, startX, startY, pixelSize);
    }

    // Draw date
    function drawFrostDate(dc as Dc, centerX as Number, centerY as Number) as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dateStr = info.day_of_week + " " + info.day;

        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY + 30, Graphics.FONT_SMALL, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
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
