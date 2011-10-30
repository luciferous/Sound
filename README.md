Sound

A Javascript wrapper around AS3 Sound.

## Usage

Load a sound file and play it.

    <script src="sound.js">
        Sound.initialize();
        var s = new Sound();
        s.load("testsound.mp3");
        s.play();
    </script>

Stream dynamically generated audio.

    <script src="sound.js">
        Sound.initialize();
        var s = new Sound();
        var factor = (2 * Math.PI) / 44100.0;
        var feed = function() {
            var samples = [];
            for (var i = 0; i < 2048; i++) {
                var sample = 1 + Math.sin(i * factor) * 32767;
                samples.push(String.fromCharCode(sample));
            }
            s.buffer(samples.join(""));
            setTimeout(feed, 200);
        };
        feed();
    </script>
