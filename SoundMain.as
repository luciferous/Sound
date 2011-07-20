package {

import flash.display.Sprite;
import flash.events.Event;
import flash.events.SampleDataEvent;
import flash.external.ExternalInterface;
import flash.media.Sound;
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
        ExternalInterface.addCallback("__play", play);
        ExternalInterface.addCallback("__playBytes", playBytes);
        ExternalInterface.addCallback("__setDebug", setDebug);

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
    private function play(id:int, uri:String):void {
        if (uri.substr(0, 4) == "data") {
            invoke("__onLog", "Data URI not supported yet");
            return;
        }
        var sound:Sound = new Sound(new URLRequest(uri));
        sound.addEventListener(Event.COMPLETE, function(_:Event):void {
            invoke("__onLog", "Loaded " + uri);
            var bytes:ByteArray = new ByteArray();
            sound.extract(bytes, 4096);
            bytes.position = 2000;
            invoke("__onLog", "Bytes available " + bytes.bytesAvailable);
            invoke("__onLog", "Extract" + bytes.readFloat().toString());
            invoke("__onLog", "Extract" + bytes.readFloat().toString());
            invoke("__onLog", "Extract" + bytes.readFloat().toString());
            invoke("__onLog", "Extract" + bytes.readFloat().toString());
            invoke("__onLog", "Extract" + bytes.readFloat().toString());
            invoke("__onLog", "Extract" + bytes.readFloat().toString());
            invoke("__onLog", "Extract" + bytes.readFloat().toString());
            invoke("__onLog", "Extract" + bytes.readFloat().toString());
        });
        sound.play();
    }

    private function playBytes(bytes:String):void {
        invoke("__onLog", "Copying bytes " + bytes.length);
        var data:ByteArray = new ByteArray();
        for (var i:int = 0; i < bytes.length; i++) {
            var float:Number = Number(bytes.charCodeAt(i) - 32767) / 32767;
            data.writeFloat(float);
        }
        data.position = 0;
        var sound:Sound = new Sound();
        sound.addEventListener(SampleDataEvent.SAMPLE_DATA,
            function(event:SampleDataEvent):void {
                //data.position = event.position;
                invoke("__onLog", "Event position " + event.position);
                invoke("__onLog", "Data position " + data.position);
                invoke("__onLog", "Writing bytes " + data.bytesAvailable);
                for (var c:int = 0; c < 8192; c++) {
                    if (data.bytesAvailable <= 0 ) { 
                        break;
                    }
                    var f1:Number = Number(data.readFloat());
                    //var f2:Number = Math.sin((c + event.position) * Math.PI * 2 / 44100 * 440);
                    event.data.writeFloat(f1 * 0.15);
                    event.data.writeFloat(f1 * 0.15);
                    //event.data.writeFloat(f1);
                    //invoke("__onLog", "Writing float: " + f1.toString() + ":" + f2.toString());
                }
            }
        );
        sound.play();
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
