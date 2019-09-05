var newFontSize;
(function () {
    function init() {
        var baseWidth = 1920;
        var baseFontSize = 16;
        var delayMS = 0/*100*/;

        var doc = document.documentElement;
        var currentFontSize = NaN;
        var timeoutId = NaN;

        function scaleFont() {
            // Calculate new font size
            newFontSize = Math.min(doc.offsetWidth/baseWidth, 1)*baseFontSize;
            if (newFontSize !== currentFontSize) {
                // Set new font size
                doc.style.fontSize = newFontSize + 'px';
				
                currentFontSize = newFontSize;
            }

            timeoutId = NaN;
        }

        // Call once to initialize
        setTimeout(scaleFont, 0);

        window.addEventListener('resize', function () {
            if (timeoutId) {
                // Cancel the currently queued re-scale
                clearTimeout(timeoutId);
            }
            // Queue size recalc
            timeoutId = setTimeout(scaleFont, delayMS);
        });
    }

    init();

    if (document.readyState === 'complete') {
        setTimeout(init);
    } else {
        window.addEventListener('load', init);
    }
})();