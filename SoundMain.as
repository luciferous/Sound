package {

import flash.display.Sprite;
import flash.events.Event;
import flash.events.SampleDataEvent;
import flash.external.ExternalInterface;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.getQualifiedClassName;
import flash.system.Security;

/**
 * Audio main.
 */
public class SoundMain extends Sprite {

    private var ns:String;
    private var debug:Boolean;

    private var sounds:Object;

    private var silence:ByteArray;

    private static const BYTES_PER_SAMPLE:int = 4 * 2; // Stereo 32-bit float
    private static const MAX_SAMPLE_SIZE:int = 4096 * BYTES_PER_SAMPLE;
    private static const MIN_SAMPLE_SIZE:int = 2048 * BYTES_PER_SAMPLE;

    /**
     * Constructor
     */
    public function SoundMain() {
        if (!ExternalInterface.available) {
            throw new Error("ExternalInterface not available");
        }

        ns = loaderInfo.parameters["namespace"] || getQualifiedClassName(this);
        debug = false;

        Security.allowDomain("*");
        Security.allowInsecureDomain("*");

        sounds = {};

        silence = new ByteArray();
        for (var n:int = 0; n < 2048; n++) {
            silence.writeFloat(0);
            silence.writeFloat(0);
        }

        /**
         * Javascript can call these
         */
        ExternalInterface.addCallback("__create", create);
        ExternalInterface.addCallback("__buffer", buffer);
        ExternalInterface.addCallback("__load", load);
        ExternalInterface.addCallback("__play", play);
        ExternalInterface.addCallback("__setDebug", setDebug);
        ExternalInterface.addCallback("__stop", stop);
        ExternalInterface.addCallback("__destroy", destroy);

        invoke("__onFlashInitialized");
    }

    private function setDebug(val:Boolean):void {
        invoke("__onLog", "setDebug");
        ExternalInterface.marshallExceptions = val;
        debug = val;
    }

    /**
     * Creates a new Audio
     */
    private function create(id:int):void {
        sounds[id] = {
            instance: new Sound(),
            buffer: [],
            channel: null
        };
        sounds[id].instance.addEventListener(SampleDataEvent.SAMPLE_DATA,
                                             handleSampleData(id));
        invoke("__onLog", "Max: " + String(MAX_SAMPLE_SIZE));
        invoke("__onLog", "Min: " + String(MIN_SAMPLE_SIZE));
    }

    /**
     * Sample data handler
     */
    private function handleSampleData(id:int):Function {
        var cursor:Number = 0;
        return function(event:SampleDataEvent):void {
            var bytesWritten:int = 0;
            while (bytesWritten < MAX_SAMPLE_SIZE
                && sounds[id].buffer.length > 0
            ) {
                var frame:ByteArray = sounds[id].buffer.shift();
                event.data.writeBytes(frame, 0, frame.length);
                bytesWritten += frame.length;
                frame.clear();
            }
            var pad:int = MIN_SAMPLE_SIZE - bytesWritten;
            var reps:int = Math.ceil(pad / silence.length);
            for (var i:int = 0; i < reps; i++) {
                event.data.writeBytes(silence, 0, silence.length);
            }
        };
    }

    /**
     * Buffers some audio
     */
    private function buffer(id:int, bytes:String):void {
        var frame:ByteArray = new ByteArray();
        for (var i:Number = 0; i < bytes.length; i++) {
            var sample:Number = (bytes.charCodeAt(i) - 32767) / 32767;
            frame.writeFloat(sample);
            frame.writeFloat(sample);
            if (frame.length >= MAX_SAMPLE_SIZE) {
                sounds[id].buffer.push(frame);
                frame = new ByteArray();
            }
        }
        sounds[id].buffer.push(frame);
    }

    /**
     * Loads audio from URL
     */
    private function load(id:int, uri:String):void {
        if (uri.substr(0, 4) == "data") {
            invoke("__onLog", "Data URI not supported");
            return;
        }
        sounds[id].instance.load(new URLRequest(uri));
    }

    /**
     * Plays audio
     */
    private function play(id:int, startTime:Number = 0, loops:int = 1):void {
        if (sounds[id].channel) {
            invoke("__onLog", "Already playing this sound");
            return;
        }
        sounds[id].channel = sounds[id].instance.play(startTime, loops);
        sounds[id].channel.addEventListener(Event.SOUND_COMPLETE, function(e:Event):void {
            sounds[id].channel = null;
        });
    }

    /**
     * Stops playing audio
     */
    private function stop(id:int):void {
        if (sounds[id].channel) {
            sounds[id].channel.stop();
            sounds[id].channel = null;
        }
    }

    /**
     * Cleans up resources
     */
    private function destroy(id:int):void {
        stop(id);
        sounds[id].buffer.clear();
        sounds[id].buffer = null;
        sounds[id].channel = null;
        sounds[id].instance = null;
        delete sounds[id];
    }

    /**
     * Conveniently invoke a function in Javascript.
     *
     * @param method String The method to call.
     */
    private function invoke(method:String, ...params):void {
        params = params || [];
        ExternalInterface.call.apply(ExternalInterface,
                [ns + "." + method].concat(params));
    }

}

}
