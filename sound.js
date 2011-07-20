(function(ns) {

if (!swfobject.hasFlashPlayerVersion("10.0.0")) {
    if (window.console) {
        console.error("Flash Player >= 10.0.0 is required");
    }
}

function Sound() {
    this.id = Sound.nextId++;
}

Sound.prototype = {
    play: function(data) {
        if (data.length == 0) return;
        Sound.flash.__play(this.id, data);
    }
}

var classMethods = {
    initialize: function (options) {
        options = options || {};
        if (Sound.flash) return;
        if (!document.body) {
            console.log("document.body not ready, will retry");
            try {
                window.addEventListener("load", function() {
                    Sound.initialize(options);    
                }, false);
            } catch(e) {
                console.error(e);
                window.attachEvent("onload", function() {
                    Sound.initialize(options);
                });
            }
            return;
        }
        options["swfLocation"] = options["swfLocation"] || "SoundMain.swf";
        options["domId"] = options["domId"] || "__soundFlash__";

        var flash = document.createElement("div");
        flash.id = options["domId"];

        document.body.appendChild(flash);

        Sound.flash = flash;

        var flashVars = {
            namespace: window.NS_SOUND ? window.NS_SOUND + ".Sound" : "Sound"
        };

        swfobject.embedSWF(
            options["swfLocation"],
            options["domId"],
            "1",
            "1",
            "10.0.0",
            null,
            flashVars,
            { hasPriority: true, allowScriptAccess: "always" },
            null,
            function(e) {
                Sound.log("Embed " +
                    (e.success ? "succeeded" : "failed"));
            }
        );
    },
    log: function(msg, obj, method) {
        if (!Sound.debug || !window.console) {
            return;
        }
        method = method || "log";
        console[method]("[Sound] " + msg);
        if (typeof obj != "undefined") {
            console[method](obj);
        }
    },
    queue: function(task) {
        if (Sound.initialized) {
            task();
        } else {
            Sound.tasks.push(task);
        }
    }
};

var flashEventHandlers = {
    __onFlashInitialized: function() {
        Sound.initialized = true;
        Sound.flash = document.getElementById(Sound.flash.id);
        setTimeout(function() {
            Sound.flash.__setDebug(Sound.debug);
            Sound.log("Sound initialized and ready");
            for (var i = 0; i < Sound.tasks.length; i++) {
                Sound.tasks[i]();
            }
        }, 0);
    },
    __onLog: function(msg) {
        Sound.log(msg);
    }
};

for (var name in classMethods) {
    Sound[name] = classMethods[name];
}

for (var name in flashEventHandlers) {
    Sound[name] = flashEventHandlers[name];
}

Sound.nextId = 0;
Sound.debug = false;
Sound.tasks = [];

ns.Sound = Sound;

})(window[window.NS_SOUND] || window);
