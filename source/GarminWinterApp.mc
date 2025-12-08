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

        // Draw simplified winter scene using rectangles
        drawSimpleMountains(dc, width, height);
        drawSimpleSnowGround(dc, width, height);
        drawSimpleTrees(dc, width, height);

        // Draw falling snowflakes
        if (!_isLowPower) {
            drawSnowflakes(dc, width, height, clockTime.sec);
        }

        // Draw time with pixel font
        drawFrostTime(dc, centerX, centerY, clockTime);

        // Draw date
        drawFrostDate(dc, centerX, centerY);
    }

    // Draw simplified mountains using horizontal bands
    function drawSimpleMountains(dc as Dc, width as Number, height as Number) as Void {
        // Far mountain silhouettes - using stepped rectangles for a pixelated look
        dc.setColor(MOUNTAIN_FAR, Graphics.COLOR_TRANSPARENT);

        // Left mountain
        var leftPeakX = width / 4;
        var leftBase = height;
        var leftTop = (height * 0.45).toNumber();
        drawPixelMountain(dc, leftPeakX, leftTop, leftBase, width / 3);

        // Right mountain
        var rightPeakX = (width * 3 / 4);
        var rightTop = (height * 0.45).toNumber();
        drawPixelMountain(dc, rightPeakX, rightTop, leftBase, width / 3);

        // Front mountains (brighter)
        dc.setColor(MOUNTAIN_MID, Graphics.COLOR_TRANSPARENT);

        // Center-left peak
        var centerLeftX = (width * 0.35).toNumber();
        var centerTop = (height * 0.3).toNumber();
        drawPixelMountain(dc, centerLeftX, centerTop, height, width / 3);

        // Center-right peak
        var centerRightX = (width * 0.7).toNumber();
        var centerRightTop = (height * 0.35).toNumber();
        drawPixelMountain(dc, centerRightX, centerRightTop, height, width / 4);
    }

    // Draw a pixelated mountain shape using horizontal bands
    function drawPixelMountain(dc as Dc, peakX as Number, peakY as Number, baseY as Number, baseWidth as Number) as Void {
        var mountainHeight = baseY - peakY;
        var stepHeight = 8;  // Pixel step size
        var steps = mountainHeight / stepHeight;

        for (var i = 0; i < steps; i++) {
            var y = peakY + i * stepHeight;
            var progress = i.toFloat() / steps.toFloat();
            var halfWidth = (baseWidth / 2 * progress).toNumber();
            dc.fillRectangle(peakX - halfWidth, y, halfWidth * 2, stepHeight);
        }
    }

    // Draw snow on ground
    function drawSimpleSnowGround(dc as Dc, width as Number, height as Number) as Void {
        var snowTop = (height * 0.70).toNumber();

        // Main snow - simple rectangle
        dc.setColor(SNOW_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, snowTop, width, height - snowTop);

        // Snow wave at top - simple pixels
        for (var x = 0; x < width; x += 8) {
            var wave = ((x / 40) % 3) * 3;
            dc.fillRectangle(x, snowTop - 10 + wave, 8, 10 - wave);
        }

        // Snow shadow in middle
        dc.setColor(SNOW_SHADOW, Graphics.COLOR_TRANSPARENT);
        var shadowTop = (height * 0.80).toNumber();
        var shadowLeft = (width * 0.20).toNumber();
        var shadowRight = (width * 0.80).toNumber();
        dc.fillRectangle(shadowLeft, shadowTop, shadowRight - shadowLeft, height - shadowTop);
    }

    // Draw simple tree silhouettes
    function drawSimpleTrees(dc as Dc, width as Number, height as Number) as Void {
        dc.setColor(TREE_DARK, Graphics.COLOR_TRANSPARENT);

        // Left tree - stepped triangle
        var leftTreeX = 0;
        var leftTreeTop = (height * 0.15).toNumber();
        var treeWidth = (width * 0.15).toNumber();
        drawPixelTree(dc, leftTreeX, leftTreeTop, height, treeWidth);

        // Right tree
        var rightTreeX = width - treeWidth;
        drawPixelTree(dc, rightTreeX, leftTreeTop, height, treeWidth);

        // Small background trees
        dc.setColor(0x1A2A48, Graphics.COLOR_TRANSPARENT);
        var smallTreeWidth = (width * 0.12).toNumber();
        drawPixelTree(dc, (width * 0.35).toNumber(), (height * 0.55).toNumber(), height, smallTreeWidth);
        drawPixelTree(dc, (width * 0.55).toNumber(), (height * 0.55).toNumber(), height, smallTreeWidth);
    }

    // Draw a pixelated tree
    function drawPixelTree(dc as Dc, x as Number, topY as Number, baseY as Number, maxWidth as Number) as Void {
        var treeHeight = baseY - topY;
        var stepHeight = 12;
        var steps = treeHeight / stepHeight;

        for (var i = 0; i < steps; i++) {
            var y = topY + i * stepHeight;
            var progress = i.toFloat() / steps.toFloat();
            var treeWidth = (maxWidth * progress).toNumber();
            var xPos = x + (maxWidth - treeWidth) / 2;
            dc.fillRectangle(xPos, y, treeWidth, stepHeight);
        }
    }

    // Draw animated snowflakes
    function drawSnowflakes(dc as Dc, width as Number, height as Number, seconds as Number) as Void {
        dc.setColor(SNOW_WHITE, Graphics.COLOR_TRANSPARENT);
        var pixelSize = 4;
        var snowTop = (height * 0.68).toNumber();

        // Fewer snowflakes for performance
        for (var i = 0; i < 15; i++) {
            var baseX = ((i * 47) % width);
            var baseY = ((i * 31) % (snowTop - 30));

            // Animate based on seconds
            var offset = ((seconds * 4 + i * 11) % 80);
            var animY = (baseY + offset * 3) % snowTop;
            var animX = baseX + ((offset / 15) % 6) - 3;

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
