package com.funkypandagame.stardustair
{
import flash.filesystem.File;
import flash.net.SharedObject;

public class LocalSettings
{
    public static function saveSettings(lastFileOpened : File)
    {
        var mySO : SharedObject = SharedObject.getLocal("stardustAIRSettings");
        mySO.data.lastFileOpened = lastFileOpened.nativePath;
        mySO.data.lastFileDir = lastFileOpened.parent.nativePath;
        mySO.flush();
    }

    public static function getLastBrowsePath() : File
    {
        var mySO : SharedObject = SharedObject.getLocal("stardustAIRSettings");
        if (mySO.data.lastFileOpened)
        {
            var fi : File = new File(mySO.data.lastFileDir);
            if (fi.exists)
            {
                return fi;
            }
        }
        return File.userDirectory;
    }

    public static function getLastOpenedFile() : File
    {
        var mySO : SharedObject = SharedObject.getLocal("stardustAIRSettings");
        if (mySO.data.lastFileOpened)
        {
            var fi : File = new File(mySO.data.lastFileOpened);
            if (fi.exists)
            {
                return fi;
            }
        }
        return null;
    }
}
}
