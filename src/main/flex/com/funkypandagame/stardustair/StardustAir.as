package com.funkypandagame.stardustair {

import flash.desktop.NativeApplication;
import flash.display.Loader;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.InvokeEvent;
import flash.events.TextEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import mx.core.IFlexDisplayObject;
import mx.core.mx_internal;
import mx.events.FlexEvent;

[SWF(backgroundColor="0x353535")]
public class StardustAir extends Sprite {

/* TODOs:
associate with the .sde extension
add a "save" button
*/
    private var loader : Loader = new Loader();
    private var _urlLoader : URLLoader = new URLLoader;
    private var loadedBA : ByteArray;
    private var loadedFileName : String;
    private var isAppReady : Boolean = false;

    public function StardustAir()
    {
        stage.align = StageAlign.TOP_LEFT;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
        _urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
        _urlLoader.addEventListener(Event.COMPLETE, onLoad);
        _urlLoader.load(new URLRequest("http://s3.funkypandagame.com/startdust-particle-editor/stardust_editor_release.swf"));
        //_urlLoader.load(new URLRequest("stardust-editor.swf")); // for testing
    }

    private function onInvoke(event : InvokeEvent) : void
    {
        if (event.currentDirectory != null && event.arguments.length > 0)
        {
            //var directory:File = new File('C:/CODE/stardust-air/build') // for testing
            var directory : File = event.currentDirectory;
            var file : File = directory.resolvePath(event.arguments[0]);
            loadedFileName = file.name;
            var fileStream : FileStream = new FileStream();
            fileStream.open(file, FileMode.READ);
            loadedBA = new ByteArray();
            fileStream.readBytes(loadedBA);
            fileStream.close();
            if (isAppReady)
            {
                var stardustTool : Object = Object(loader.content).application;
                stardustTool.loadExternalSim(loadedBA, loadedFileName);
            }
        }
    }

    private function onLoad(e : Event) : void
    {
        var context : LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
        context.allowCodeImport = true;
        context.allowLoadBytesCodeExecution = true;
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
        loader.loadBytes(_urlLoader.data, context);
        addChild(loader);
    }

    private function onLoaded(evt : Event) : void
    {
        Object(loader.content).mx_internal::isStageRoot = true;
        stage.addEventListener(Event.RESIZE, onResize);
        onResize();
        loader.content.addEventListener(FlexEvent.APPLICATION_COMPLETE, onStardustReady);
        loader.content.addEventListener("setSimName", onSimNameChanged);
    }

    private function onStardustReady(evt : FlexEvent) : void
    {
        isAppReady = true;
        if (loadedBA)
        {
            var stardustTool : Object = Object(loader.content).application;
            stardustTool.loadExternalSim(loadedBA, loadedFileName);
        }
    }

    private function onResize(evt : Event = null) : void
    {
        IFlexDisplayObject(loader.content).setActualSize(stage.width, stage.height);
    }

    private function onSimNameChanged(evt : TextEvent) : void
    {
        NativeApplication.nativeApplication.openedWindows[0].title = evt.text;
    }
}
}
