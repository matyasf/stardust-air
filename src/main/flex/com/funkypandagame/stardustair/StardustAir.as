package com.funkypandagame.stardustair {

import flash.desktop.NativeApplication;
import flash.display.Loader;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.InvokeEvent;
import flash.events.SecurityErrorEvent;
import flash.events.TextEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.FileFilter;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.ByteArray;

import mx.core.IFlexDisplayObject;
import mx.core.mx_internal;
import mx.events.FlexEvent;

[SWF(backgroundColor="0x353535")]
public class StardustAir extends Sprite {

    public static const CACHED_FILENAME : String = "/stardust_editor.swf";
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
        _urlLoader.addEventListener(Event.COMPLETE, onStardustDownloaded);
        _urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        _urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
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

    private function onStardustDownloaded(e : Event) : void
    {
        loadStardustMovie(_urlLoader.data);

        var cache : File = new File(File.applicationStorageDirectory.nativePath + CACHED_FILENAME);
        var fileStream : FileStream = new FileStream();
        fileStream.open(cache, FileMode.WRITE);
        fileStream.writeBytes(_urlLoader.data);
        fileStream.close();
    }

    private function loadStardustMovie(ba : ByteArray) : void
    {
        var context : LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
        context.allowCodeImport = true;
        context.parameters = {"isRunningInAIR":"true"};
        context.allowLoadBytesCodeExecution = true;
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onStardustMovieLoaded);
        loader.loadBytes(ba, context);
        addChild(loader);
    }

    private function onStardustMovieLoaded(evt : Event) : void
    {
        Object(loader.content).mx_internal::isStageRoot = true;
        stage.addEventListener(Event.RESIZE, onResize);
        onResize();
        loader.content.addEventListener(FlexEvent.APPLICATION_COMPLETE, onStardustReady);
        loader.content.addEventListener("setSimName", onSimNameChanged);
        loader.content.addEventListener("loadFile", onSimFileLoad);
    }

    private function onLoadError(e : Event) : void
    {
        // assume that we dont have internet, try to load cached version.
        var cache : File = new File(File.applicationStorageDirectory.nativePath + CACHED_FILENAME);
        if (cache.exists)
        {
            trace("WARNING: Stardust AIR: Download error, using cached version!",e);
            var fileStream : FileStream = new FileStream();
            fileStream.open(cache, FileMode.READ);
            var ba : ByteArray = new ByteArray();
            fileStream.readBytes(ba);
            fileStream.close();
            loadStardustMovie(ba);
        }
        else
        {
            trace("Stardust AIR: Unable to start",e);
            var tf : TextField = new TextField();
            tf.x = 15;
            tf.y = 15;
            tf.width = width - 15;
            tf.height = height - 15;
            tf.defaultTextFormat = new TextFormat("_sans", 25, 0x0);
            tf.text = "Stardust AIR: Unable to start :( Do you have internet?\n" + e.toString();
            addChild(tf);
        }
    }

    private function onStardustReady(evt : FlexEvent) : void
    {
        isAppReady = true;
        var simFileToLoad : File = LocalSettings.getLastOpenedFile();
        var stardustTool : Object = Object(loader.content).application;
        if (loadedBA)
        {
            stardustTool.loadExternalSim(loadedBA, loadedFileName);
        }
        else if (simFileToLoad && simFileToLoad.exists)
        {
            var fileStream : FileStream = new FileStream();
            fileStream.open(simFileToLoad, FileMode.READ);
            var ba : ByteArray = new ByteArray();
            fileStream.readBytes(ba);
            fileStream.close();

            var fileName : String = simFileToLoad.name;
            var fileNameNoExtension : String = fileName.substr(0, fileName.lastIndexOf(".")  );

            stardustTool.loadExternalSim(ba, fileNameNoExtension);
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

    private function onSimFileLoad(event : Event) : void
    {
        var simFileToLoad : File = LocalSettings.getLastBrowsePath();
        simFileToLoad.addEventListener(Event.SELECT, selectHandler);
        simFileToLoad.browse( [new FileFilter( "Stardust editor project (*.sde)", "*.sde" )] );
    }

    private function selectHandler(e:Event):void
    {
        var simFileToLoad : File = e.target as File;
        var fileStream : FileStream = new FileStream();
        fileStream.open(simFileToLoad, FileMode.READ);
        var ba : ByteArray = new ByteArray();
        fileStream.readBytes(ba);
        fileStream.close();

        var fileName : String = simFileToLoad.name;
        var fileNameNoExtension : String = fileName.substr(0, fileName.lastIndexOf(".")  );

        LocalSettings.saveSettings(simFileToLoad);

        var stardustTool : Object = Object(loader.content).application;
        stardustTool.loadExternalSim(ba, fileNameNoExtension);
    }

}
}
