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
    // Colors from SVG reference
    private const SKY_COLOR = 0x192138;          // Dark night sky
    private const MOUNTAIN_FAR = 0x2E3C5C;       // Far mountains
    private const MOUNTAIN_FRONT = 0x3C4F78;     // Front mountain
    private const SNOW_WHITE = 0xFFFFFF;         // Pure white snow
    private const SNOW_SHADOW = 0xD0E0F0;        // Snow shadow/texture
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

        // Draw sky background
        dc.setColor(SKY_COLOR, SKY_COLOR);
        dc.clear();

        // Draw stars
        drawStars(dc, width, height);

        // Draw mountains (back to front)
        drawMountains(dc, width, height);

        // Draw snow ground
        drawSnowGround(dc, width, height);

        // Draw trees on sides
        drawTrees(dc, width, height);

        // Draw falling snow animation
        if (!_isLowPower) {
            drawFallingSnow(dc, width, height, clockTime.sec);
        }

        // Draw time with pixel font
        drawFrostTime(dc, centerX, centerY - 15, clockTime);

        // Draw date
        drawFrostDate(dc, centerX, centerY + 30);
    }

    // Draw stars in sky
    function drawStars(dc as Dc, width as Number, height as Number) as Void {
        dc.setColor(SNOW_WHITE, Graphics.COLOR_TRANSPARENT);
        // Fixed star positions from SVG
        dc.fillRectangle((width * 0.08).toNumber(), (height * 0.08).toNumber(), 3, 3);
        dc.fillRectangle((width * 0.23).toNumber(), (height * 0.12).toNumber(), 3, 3);
        dc.fillRectangle((width * 0.39).toNumber(), (height * 0.05).toNumber(), 3, 3);
        dc.fillRectangle((width * 0.55).toNumber(), (height * 0.15).toNumber(), 3, 3);
        dc.fillRectangle((width * 0.70).toNumber(), (height * 0.09).toNumber(), 3, 3);
        dc.fillRectangle((width * 0.86).toNumber(), (height * 0.18).toNumber(), 3, 3);
        dc.fillRectangle((width * 0.03).toNumber(), (height * 0.28).toNumber(), 3, 3);
        dc.fillRectangle((width * 0.94).toNumber(), (height * 0.31).toNumber(), 3, 3);
    }

    // Draw layered mountains
    function drawMountains(dc as Dc, width as Number, height as Number) as Void {
        // Far mountains layer 1 (back, semi-transparent effect via darker color)
        var farColor1 = 0x252F4A; // Darker version for opacity effect
        dc.setColor(farColor1, Graphics.COLOR_TRANSPARENT);
        drawMountainRange(dc, width, height, 0.70, 0.47, 0.70, 0.47);

        // Far mountains layer 2
        dc.setColor(MOUNTAIN_FAR, Graphics.COLOR_TRANSPARENT);
        drawMountainRange(dc, width, height, 0.63, 0.39, 0.63, 0.39);

        // Front mountain (brightest)
        dc.setColor(MOUNTAIN_FRONT, Graphics.COLOR_TRANSPARENT);
        drawFrontMountain(dc, width, height);
    }

    // Draw a mountain range with peaks
    function drawMountainRange(dc as Dc, width as Number, height as Number,
                                baseY as Float, peak1Y as Float, peak2Y as Float, peak3Y as Float) as Void {
        var base = (height * baseY).toNumber();
        var step = 8;

        // Draw mountains as series of triangular shapes using rectangles
        // Peak 1 - left side
        var peak1X = (width * 0.23).toNumber();
        var peak1Top = (height * peak1Y).toNumber();
        drawTriangleMountain(dc, peak1X, peak1Top, base, (width * 0.35).toNumber(), step);

        // Peak 2 - center-right
        var peak2X = (width * 0.62).toNumber();
        var peak2Top = (height * peak2Y).toNumber();
        drawTriangleMountain(dc, peak2X, peak2Top, base, (width * 0.35).toNumber(), step);
    }

    // Draw front mountain
    function drawFrontMountain(dc as Dc, width as Number, height as Number) as Void {
        var base = (height * 0.55).toNumber();
        var peakX = (width * 0.47).toNumber();
        var peakTop = (height * 0.31).toNumber();
        var step = 6;

        drawTriangleMountain(dc, peakX, peakTop, base, (width * 0.50).toNumber(), step);
    }

    // Draw a triangle mountain using horizontal rectangles
    function drawTriangleMountain(dc as Dc, peakX as Number, peakY as Number, baseY as Number, baseWidth as Number, step as Number) as Void {
        var mountainHeight = baseY - peakY;
        var steps = mountainHeight / step;

        for (var i = 0; i < steps; i++) {
            var y = peakY + i * step;
            var progress = i.toFloat() / steps.toFloat();
            var halfWidth = (baseWidth / 2 * progress).toNumber();
            dc.fillRectangle(peakX - halfWidth, y, halfWidth * 2, step);
        }
    }

    // Draw snow ground
    function drawSnowGround(dc as Dc, width as Number, height as Number) as Void {
        var snowTop = (height * 0.70).toNumber();

        // Main white snow
        dc.setColor(SNOW_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, snowTop, width, height - snowTop);

        // Wave edge at top of snow
        for (var x = 0; x < width; x += 10) {
            var wave = ((x / 30) % 3) * 4;
            dc.fillRectangle(x, snowTop - 10 + wave, 10, 10 - wave);
        }

        // Snow shadow/texture
        dc.setColor(SNOW_SHADOW, Graphics.COLOR_TRANSPARENT);
        var shadowTop = (height * 0.78).toNumber();
        // Central shadow area
        dc.fillRectangle((width * 0.15).toNumber(), shadowTop, (width * 0.35).toNumber(), (height * 0.08).toNumber());
        dc.fillRectangle((width * 0.55).toNumber(), shadowTop + 8, (width * 0.30).toNumber(), (height * 0.06).toNumber());
    }

    // Draw trees on both sides
    function drawTrees(dc as Dc, width as Number, height as Number) as Void {
        // Left tree - dark base
        dc.setColor(TREE_DARK, Graphics.COLOR_TRANSPARENT);
        drawPineTree(dc, 0, (height * 0.31).toNumber(), (height * 0.15).toNumber(), (width * 0.15).toNumber(), true);

        // Left tree - lighter layer
        dc.setColor(TREE_LIGHT, Graphics.COLOR_TRANSPARENT);
        drawPineTree(dc, 0, (height * 0.39).toNumber(), (height * 0.28).toNumber(), (width * 0.15).toNumber(), true);

        // Right tree - dark base
        dc.setColor(TREE_DARK, Graphics.COLOR_TRANSPARENT);
        drawPineTree(dc, width - (width * 0.15).toNumber(), (height * 0.31).toNumber(), (height * 0.15).toNumber(), (width * 0.15).toNumber(), false);

        // Right tree - lighter layer
        dc.setColor(TREE_LIGHT, Graphics.COLOR_TRANSPARENT);
        drawPineTree(dc, width - (width * 0.15).toNumber(), (height * 0.39).toNumber(), (height * 0.28).toNumber(), (width * 0.15).toNumber(), false);

        // Small middle trees (silhouettes)
        dc.setColor(TREE_DARK, Graphics.COLOR_TRANSPARENT);
        drawSmallTree(dc, (width * 0.39).toNumber(), (height * 0.63).toNumber(), (height * 0.55).toNumber(), (width * 0.08).toNumber());
        drawSmallTree(dc, (width * 0.55).toNumber(), (height * 0.63).toNumber(), (height * 0.55).toNumber(), (width * 0.08).toNumber());
    }

    // Draw a pine tree shape
    function drawPineTree(dc as Dc, x as Number, baseY as Number, peakY as Number, treeWidth as Number, isLeft as Boolean) as Void {
        var treeHeight = baseY - peakY;
        var step = 8;
        var steps = treeHeight / step;

        for (var i = 0; i < steps; i++) {
            var y = peakY + i * step;
            var progress = i.toFloat() / steps.toFloat();
            var layerWidth = (treeWidth * progress).toNumber();
            if (isLeft) {
                dc.fillRectangle(x, y, layerWidth, step);
            } else {
                dc.fillRectangle(x + treeWidth - layerWidth, y, layerWidth, step);
            }
        }
        // Fill to bottom
        if (isLeft) {
            dc.fillRectangle(x, baseY, treeWidth, (dc.getHeight() - baseY));
        } else {
            dc.fillRectangle(x, baseY, treeWidth, (dc.getHeight() - baseY));
        }
    }

    // Draw small tree silhouette
    function drawSmallTree(dc as Dc, centerX as Number, baseY as Number, peakY as Number, treeWidth as Number) as Void {
        var treeHeight = baseY - peakY;
        var step = 6;
        var steps = treeHeight / step;

        for (var i = 0; i < steps; i++) {
            var y = peakY + i * step;
            var progress = i.toFloat() / steps.toFloat();
            var halfWidth = (treeWidth / 2 * progress).toNumber();
            dc.fillRectangle(centerX - halfWidth, y, halfWidth * 2, step);
        }
        // Fill to snow line
        dc.fillRectangle(centerX - treeWidth / 2, baseY, treeWidth, (dc.getHeight() * 0.07).toNumber());
    }

    // Draw falling snowflakes
    function drawFallingSnow(dc as Dc, width as Number, height as Number, seconds as Number) as Void {
        dc.setColor(SNOW_WHITE, Graphics.COLOR_TRANSPARENT);
        var snowLimit = (height * 0.68).toNumber();

        for (var i = 0; i < 15; i++) {
            var baseX = ((i * 37 + 11) % width);
            var baseY = ((i * 23 + 5) % snowLimit);
            var offset = ((seconds * 4 + i * 17) % 80);
            var animY = (baseY + offset * 2) % snowLimit;
            var animX = baseX + ((offset / 10) % 6) - 3;
            dc.fillRectangle(animX, animY, 3, 3);
        }
    }

    // Draw pixel digit
    function drawPixelDigit(dc as Dc, digit as Number, x as Number, y as Number, pixelSize as Number) as Void {
        var patterns = [
            [[1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1]],
            [[0,0,1,0,0], [0,1,1,0,0], [0,0,1,0,0], [0,0,1,0,0], [0,0,1,0,0], [0,0,1,0,0], [0,1,1,1,0]],
            [[1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1], [1,0,0,0,0], [1,0,0,0,0], [1,1,1,1,1]],
            [[1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1]],
            [[1,0,0,0,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [0,0,0,0,1]],
            [[1,1,1,1,1], [1,0,0,0,0], [1,0,0,0,0], [1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [1,1,1,1,1]],
            [[1,1,1,1,1], [1,0,0,0,0], [1,0,0,0,0], [1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1]],
            [[1,1,1,1,1], [0,0,0,0,1], [0,0,0,0,1], [0,0,0,1,0], [0,0,1,0,0], [0,0,1,0,0], [0,0,1,0,0]],
            [[1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1], [1,0,0,0,1], [1,0,0,0,1], [1,1,1,1,1]],
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

    function drawColon(dc as Dc, x as Number, y as Number, pixelSize as Number) as Void {
        dc.fillRectangle(x, y + pixelSize * 2, pixelSize - 1, pixelSize - 1);
        dc.fillRectangle(x, y + pixelSize * 4, pixelSize - 1, pixelSize - 1);
    }

    function drawFrostTime(dc as Dc, centerX as Number, centerY as Number, clockTime as System.ClockTime) as Void {
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

        var pixelSize = 5;
        var digitWidth = 5 * pixelSize;
        var colonWidth = pixelSize;
        var spacing = pixelSize;
        var totalWidth = digitWidth * 4 + colonWidth + spacing * 4;
        var startX = centerX - totalWidth / 2;
        var startY = centerY - 17;

        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);

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

    function drawFrostDate(dc as Dc, centerX as Number, centerY as Number) as Void {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var dateStr = info.day_of_week + " " + info.day;

        dc.setColor(FONT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, Graphics.FONT_SMALL, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
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
