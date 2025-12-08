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
    // Colors inspired by reference image
    private const SKY_DARK = 0x0D1B2A;           // Dark night sky
    private const SKY_MID = 0x1B2838;            // Mid sky
    private const MOUNTAIN_SNOW = 0x8FAEC4;     // Snow on mountains
    private const MOUNTAIN_DARK = 0x2A4A6A;     // Mountain shadow
    private const MOUNTAIN_MID = 0x3A5A7A;      // Mountain mid
    private const FOREST_DARK = 0x0A1A2A;       // Dark forest
    private const FOREST_MID = 0x1A3A4A;        // Mid forest
    private const TREE_DARK = 0x0F2030;         // Dark tree
    private const TREE_SNOW = 0xB0D0E8;         // Snow on trees
    private const SNOW_BRIGHT = 0xE8F4FF;       // Bright snow
    private const SNOW_MID = 0xA8C8E0;          // Mid snow
    private const SNOW_SHADOW = 0x6090B0;       // Snow shadow
    private const STAR_COLOR = 0xFFFFFF;        // Stars
    private const FONT_COLOR = 0xFFFFFF;        // White text

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

        // Draw sky gradient (simplified)
        drawSky(dc, width, height);

        // Draw stars
        if (!_isLowPower) {
            drawStars(dc, width, height, clockTime.sec);
        }

        // Draw mountains with snow
        drawMountains(dc, width, height);

        // Draw forest layers
        drawForest(dc, width, height);

        // Draw pine trees on sides
        drawTrees(dc, width, height);

        // Draw snow ground
        drawSnowGround(dc, width, height);

        // Draw falling snow
        if (!_isLowPower) {
            drawFallingSnow(dc, width, height, clockTime.sec);
        }

        // Draw time with pixel font
        drawFrostTime(dc, centerX, centerY - 20, clockTime);

        // Draw date
        drawFrostDate(dc, centerX, centerY + 25);
    }

    // Draw night sky
    function drawSky(dc as Dc, width as Number, height as Number) as Void {
        dc.setColor(SKY_DARK, SKY_DARK);
        dc.clear();

        // Slight gradient effect with bands
        dc.setColor(SKY_MID, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, (height * 0.15).toNumber(), width, (height * 0.15).toNumber());
    }

    // Draw twinkling stars
    function drawStars(dc as Dc, width as Number, height as Number, seconds as Number) as Void {
        dc.setColor(STAR_COLOR, Graphics.COLOR_TRANSPARENT);

        // Static star positions in sky area
        var starY = (height * 0.35).toNumber();
        for (var i = 0; i < 25; i++) {
            var x = ((i * 29 + 7) % width);
            var y = ((i * 17 + 3) % starY);
            var twinkle = ((seconds + i) % 4);
            if (twinkle > 0) {
                dc.fillRectangle(x, y, 2, 2);
            }
        }
    }

    // Draw mountains with snow caps
    function drawMountains(dc as Dc, width as Number, height as Number) as Void {
        var baseY = (height * 0.55).toNumber();

        // Back mountain (left) - darker
        dc.setColor(MOUNTAIN_DARK, Graphics.COLOR_TRANSPARENT);
        drawMountainShape(dc, (width * 0.25).toNumber(), (height * 0.25).toNumber(), baseY, (width * 0.5).toNumber());

        // Back mountain (right)
        drawMountainShape(dc, (width * 0.75).toNumber(), (height * 0.28).toNumber(), baseY, (width * 0.45).toNumber());

        // Snow caps on back mountains
        dc.setColor(MOUNTAIN_SNOW, Graphics.COLOR_TRANSPARENT);
        drawSnowCap(dc, (width * 0.25).toNumber(), (height * 0.25).toNumber(), (width * 0.15).toNumber());
        drawSnowCap(dc, (width * 0.75).toNumber(), (height * 0.28).toNumber(), (width * 0.12).toNumber());

        // Front mountain - lighter
        dc.setColor(MOUNTAIN_MID, Graphics.COLOR_TRANSPARENT);
        drawMountainShape(dc, (width * 0.5).toNumber(), (height * 0.32).toNumber(), baseY, (width * 0.4).toNumber());

        // Snow cap on front mountain
        dc.setColor(MOUNTAIN_SNOW, Graphics.COLOR_TRANSPARENT);
        drawSnowCap(dc, (width * 0.5).toNumber(), (height * 0.32).toNumber(), (width * 0.1).toNumber());
    }

    // Draw a mountain using stepped rectangles
    function drawMountainShape(dc as Dc, peakX as Number, peakY as Number, baseY as Number, baseWidth as Number) as Void {
        var mountainHeight = baseY - peakY;
        var stepHeight = 6;
        var steps = mountainHeight / stepHeight;

        for (var i = 0; i < steps; i++) {
            var y = peakY + i * stepHeight;
            var progress = i.toFloat() / steps.toFloat();
            var halfWidth = (baseWidth / 2 * progress).toNumber();
            dc.fillRectangle(peakX - halfWidth, y, halfWidth * 2, stepHeight);
        }
    }

    // Draw snow cap on mountain peak
    function drawSnowCap(dc as Dc, peakX as Number, peakY as Number, capWidth as Number) as Void {
        var stepHeight = 4;
        var steps = 5;

        for (var i = 0; i < steps; i++) {
            var y = peakY + i * stepHeight;
            var progress = i.toFloat() / steps.toFloat();
            var halfWidth = (capWidth / 2 * (1 + progress)).toNumber();
            // Jagged snow edge
            for (var x = peakX - halfWidth; x < peakX + halfWidth; x += 4) {
                var jag = ((x / 4) % 2) * 2;
                dc.fillRectangle(x, y + jag, 4, stepHeight);
            }
        }
    }

    // Draw layered forest
    function drawForest(dc as Dc, width as Number, height as Number) as Void {
        var forestTop = (height * 0.50).toNumber();
        var forestBottom = (height * 0.65).toNumber();

        // Dark forest silhouette
        dc.setColor(FOREST_DARK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, forestTop, width, forestBottom - forestTop);

        // Tree tops silhouette - jagged edge
        for (var x = 0; x < width; x += 8) {
            var treeHeight = 8 + ((x / 8) % 3) * 6;
            dc.fillRectangle(x, forestTop - treeHeight, 8, treeHeight);
        }

        // Mid forest layer
        dc.setColor(FOREST_MID, Graphics.COLOR_TRANSPARENT);
        var midTop = (height * 0.55).toNumber();
        for (var x = 4; x < width; x += 12) {
            var treeHeight = 6 + ((x / 6) % 2) * 4;
            dc.fillRectangle(x, midTop - treeHeight, 6, treeHeight + 10);
        }
    }

    // Draw detailed pine trees on sides
    function drawTrees(dc as Dc, width as Number, height as Number) as Void {
        // Left tree
        drawPineTree(dc, 0, (height * 0.20).toNumber(), height, (width * 0.18).toNumber(), true);

        // Right tree
        drawPineTree(dc, width - (width * 0.18).toNumber(), (height * 0.20).toNumber(), height, (width * 0.18).toNumber(), false);
    }

    // Draw a pine tree with snow
    function drawPineTree(dc as Dc, x as Number, topY as Number, baseY as Number, maxWidth as Number, isLeft as Boolean) as Void {
        var treeHeight = baseY - topY;
        var stepHeight = 10;
        var steps = treeHeight / stepHeight;

        // Draw tree body (dark)
        dc.setColor(TREE_DARK, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < steps; i++) {
            var y = topY + i * stepHeight;
            var progress = i.toFloat() / steps.toFloat();
            var layerWidth = (maxWidth * progress).toNumber();
            if (isLeft) {
                dc.fillRectangle(x, y, layerWidth, stepHeight);
            } else {
                dc.fillRectangle(x + maxWidth - layerWidth, y, layerWidth, stepHeight);
            }
        }

        // Draw snow on branches
        dc.setColor(TREE_SNOW, Graphics.COLOR_TRANSPARENT);
        for (var i = 1; i < steps; i += 2) {
            var y = topY + i * stepHeight;
            var progress = i.toFloat() / steps.toFloat();
            var layerWidth = (maxWidth * progress * 0.6).toNumber();
            // Snow patches
            if (isLeft) {
                dc.fillRectangle(x + 2, y, layerWidth, 3);
                dc.fillRectangle(x + layerWidth / 2, y + 4, layerWidth / 3, 2);
            } else {
                dc.fillRectangle(x + maxWidth - layerWidth - 2, y, layerWidth, 3);
                dc.fillRectangle(x + maxWidth - layerWidth / 2, y + 4, layerWidth / 3, 2);
            }
        }
    }

    // Draw snow-covered ground
    function drawSnowGround(dc as Dc, width as Number, height as Number) as Void {
        var snowTop = (height * 0.68).toNumber();

        // Main bright snow
        dc.setColor(SNOW_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, snowTop, width, height - snowTop);

        // Snow texture - mid tones
        dc.setColor(SNOW_MID, Graphics.COLOR_TRANSPARENT);
        for (var x = 0; x < width; x += 12) {
            var offset = ((x / 12) % 3) * 4;
            dc.fillRectangle(x, snowTop + offset, 8, 4);
        }

        // Shadow areas
        dc.setColor(SNOW_SHADOW, Graphics.COLOR_TRANSPARENT);
        var shadowY = (height * 0.85).toNumber();
        dc.fillRectangle((width * 0.1).toNumber(), shadowY, (width * 0.25).toNumber(), 6);
        dc.fillRectangle((width * 0.65).toNumber(), shadowY + 4, (width * 0.25).toNumber(), 6);

        // Snow edge texture
        dc.setColor(SNOW_BRIGHT, Graphics.COLOR_TRANSPARENT);
        for (var x = 0; x < width; x += 6) {
            var wave = ((x / 20) % 3) * 3;
            dc.fillRectangle(x, snowTop - 8 + wave, 6, 8 - wave);
        }
    }

    // Draw falling snowflakes
    function drawFallingSnow(dc as Dc, width as Number, height as Number, seconds as Number) as Void {
        dc.setColor(STAR_COLOR, Graphics.COLOR_TRANSPARENT);
        var snowLimit = (height * 0.65).toNumber();

        for (var i = 0; i < 20; i++) {
            var baseX = ((i * 37 + 11) % width);
            var baseY = ((i * 23 + 5) % snowLimit);
            var offset = ((seconds * 5 + i * 13) % 100);
            var animY = (baseY + offset * 2) % snowLimit;
            var animX = baseX + ((offset / 12) % 8) - 4;
            var size = 2 + (i % 2);
            dc.fillRectangle(animX, animY, size, size);
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
