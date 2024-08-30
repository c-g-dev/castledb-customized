package system;

import haxe.Timer;
import util.MessagingCenter;
import haxe.io.Path;
import js.node.webkit.MenuItem;
import js.jquery.Helper.*;


using StringTools;

typedef AutosaveConfig = {
    ?enabled: Bool,
    ?folder: String,
    ?interval: Float,
    ?maxNum: Int
}

class Autosave {
    static var engine: AutosaveEngine;

    public static function init(model: Model) {
        if(engine == null) engine = new AutosaveEngine(model);
    }

    public static function createMenuItem(): MenuItem {
        var mi = new MenuItem({ label : "Autosaving"});
        mi.click = () -> {
            launchAutosavePopup();
        };
        return mi;
    }

    public static function createManualBackupMenuItem(): MenuItem {
        var mi = new MenuItem({ label : "Backup"});
        mi.click = () -> {
            engine.manualBackup();
        };
        return mi;
    }

    static function launchAutosavePopup() {
        var popup = J("#autosaveconfig");
        
        // Auto-populate popup with current settings
        J("#enabled").prop("checked", engine.enabled);
        J("#folder").val(engine.folder);
        J("#interval").val(engine.interval);
        J("#max_backups").val(engine.maxNum);
    
        popup.show();
    }

    public static function updateAutosaveConfig(config: AutosaveConfig) {
        if(config.folder != null) engine.folder = config.folder;
        if(config.interval != null) engine.interval = config.interval;
        if(config.maxNum != null) engine.maxNum = config.maxNum;
        if(config.enabled != null){
            engine.enabled = config.enabled;
            if(engine.enabled){
                if(engine.running){
                    engine.pause();
                }
                engine.runInBackground();
            }
        }

        engine.syncToPrefs();
    }
    
}


class AutosaveEngine {

    /*
        folder structure looks like this:

        folder
            savedFile1
                DD-MM-YYYY
                    backup-savedFile1-HH-MM-SS
                    backup-savedFile2-HH-MM-SS
            savedFile2
                DD-MM-YYYY
                    backup-savedFile1-HH-MM-SS
                    backup-savedFile2-HH-MM-SS
                DD-MM-YYYY
                    backup-savedFile1-HH-MM-SS
                    backup-savedFile2-HH-MM-SS
    */  

    var model: Model;
    public var enabled: Bool; //Is autosave enabled
    public var interval: Float; //Autosave interval in seconds
    public var maxNum: Int; //Max number of backups per day
    public var folder: String;
    public var running: Bool;

    var timer: Timer;

    public function new(model: Model) {
        @:privateAccess var prefs = model.prefs;
        this.model = model;
        this.enabled = prefs.autosave.enabled;
        this.interval = prefs.autosave.interval;
        this.maxNum = prefs.autosave.maxNum;
        this.folder = prefs.autosave.folder;
      
        this.running = false;
        
        MessagingCenter.subscribe("fileChanged", (path: String) -> {
            @:privateAccess trace("file changed: " + model.prefs.curFile);
            updateFolder();
        });

        if(this.folder != null) runInBackground();
    }

    public function syncToPrefs() {
        @:privateAccess var prefs = model.prefs;
        prefs.autosave.enabled = enabled;
        prefs.autosave.interval = interval;
        prefs.autosave.maxNum = maxNum;
        prefs.autosave.folder = folder;
    }

    function updateFolder() {
        @:privateAccess if(model.prefs != null && model.prefs.curFile != null && this.folder == null) {
            @:privateAccess this.folder = Path.directory(model.prefs.curFile) + "/cdb_backups";
            runInBackground();
        }
    }

    public function runInBackground() {
        if (!enabled) return;
        if (folder == null) return;
        
        running = true;
        timer = new haxe.Timer(Std.int(interval * 1000));
        timer.run = function() {
            if (!running) {
                timer.stop();
                return;
            }
            @:privateAccess var currentFileName = Path.withoutExtension(Path.withoutDirectory(model.prefs.curFile));
            var path = folder + "/" + currentFileName + "/" + getTodayDate() + "/backup-" + currentFileName + "-" + getCurrentTime() + ".cdb";
            save(path);
            cleanupOldBackups(currentFileName, getTodayDate());
        }
    }

    public function manualBackup() {
        if (folder == null) return;
        @:privateAccess var currentFileName = Path.withoutExtension(Path.withoutDirectory(model.prefs.curFile));
        var path = folder + "/" + currentFileName + "/" + getTodayDate() + "/backup-" + currentFileName + "-" + getCurrentTime() + ".cdb";
        save(path);
        cleanupOldBackups(currentFileName, getTodayDate());
    }

    public function pause() {
        timer.stop();
        running = false;
    }

    public function save(path: String) {
        var dir = Path.directory(path);
        if (!sys.FileSystem.exists(dir)) {
            sys.FileSystem.createDirectory(dir);
        }
        trace("saving to: " + path);
        model.saveTo(path);
    }

    function getTodayDate(): String {
        var date = Date.now();
        return date.getDay() + "-" + date.getMonth() + "-" + date.getFullYear();
    }

    function getCurrentTime(): String {
        var date = Date.now();
        return date.getHours() + "-" + date.getMinutes() + "-" + date.getSeconds();
    }
    
    function cleanupOldBackups(fileName: String, date: String) {
        var dir = folder + "/" + fileName + "/" + date;
        var files = sys.FileSystem.readDirectory(dir);
        var backups = files.filter(function(f) return f.startsWith("backup-"));
        
        if (backups.length > maxNum) {
            backups.sort(function(a, b) return Reflect.compare(a, b));
            for (i in 0...backups.length - maxNum) {
                sys.FileSystem.deleteFile(dir + "/" + backups[i]);
            }
        }
    }
}