package {

import flash.display.Sprite;
import flash.events.Event;
import flash.events.SampleDataEvent;
import flash.external.ExternalInterface;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.utils.getQualifiedClassName;
import flash.system.Security;

/**
 * Audio main.
 */
public class SoundMain extends Sprite {

    private var ns:String;
    private var debug:Boolean;

    private var sounds:Array;

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

        sounds = [];

        /**
         * Javascript can call these
         */
        ExternalInterface.addCallback("__create", create);
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
            channel: null
        };
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
        var channel:SoundChannel = sounds[id].instance.play(startTime, loops);
        channel.addEventListener(Event.SOUND_COMPLETE, function(_:Event):void {
            if (id in sounds) sounds[id].channel = null;
        });
        sounds[id].channel = channel;
    }

    /**
     * Stops playing audio
     */
    private function stop(id:int):void {
        sounds[id].channel.stop();
    }

    /**
     * Cleans up resources
     */
    private function destroy(id:int):void {
        sounds[id].instance = null;
        if (sounds[id].channel) {
            sounds[id].channel.stop();
        }
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
