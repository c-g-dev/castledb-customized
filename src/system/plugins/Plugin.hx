package system.plugins;

import haxe.Json;
import haxe.io.Path;
import sys.io.File;

using StringTools;

typedef Plugin = {
    name: String,
    type: String,
    plugin: Dynamic
}

typedef LevelEditPropsPlugin_AppliesToObject = {}
typedef LevelEditPropsPlugin_Render = {}
typedef LevelEditPropsPlugin_WriteToSheet = {}

typedef LevelEditPropsPlugin = {
    appliesToObject: LevelEditPropsPlugin_AppliesToObject -> Bool,
    render: LevelEditPropsPlugin_Render -> Void,
    writeToSheet: LevelEditPropsPlugin_WriteToSheet -> Void
}

class Plugins {
    public static var LOADED: Map<String, Array<Plugin>> = new Map<String, Array<Plugin>>();
    static final PLUGIN_DIRECTORY = "plugins";

    public static function loadAll() {
        var dir = sys.FileSystem.readDirectory(PLUGIN_DIRECTORY);
        for (file in dir) {
            if (file.endsWith(".hx")) {
                load(file);
            }
        }
    }

    public static function load(filePath: String) {
        var pluginFile = File.getContent(filePath);

        var parser = new hscript.Parser();
        var ast = parser.parseString(pluginFile);
        var interp = new hscript.Interp();
        var pluginObject: Plugin = interp.execute(ast);

        var type = pluginObject.type;

        if (!LOADED.exists(type)) {
            LOADED.set(type, new Array<Plugin>());
        }

        LOADED.get(type).push(pluginObject);
        
    }

}

var testPluginLoad: LevelEditPropsPlugin = {
    appliesToObject: (args) -> { 
        return args.layerName == "events" && args.object.script.contains("Textbox");
    },
    render: (args) -> { 
        args.util.hideDefault();
        args.util.addHeader("Textbox");
        args.util.addProp("Kind", "dropdown", ["OnInteract", "OnWalk"]);
        args.util.addProp("Text", "text");
        args.util.addShowAllPropsButton();
    },
    writeToSheet: (args) -> { 
        args.util.writeDefaultProps();
        var text = args.util.getProp("Text");
        var kind = args.util.getProp("Kind");
        args.object.script = [1, text];
        if( kind == "OnInteract" ) {
            args.object.eventType = [0];
        }
        else if( kind == "OnWalk" ) {
            args.object.eventType = [1];
        }
        args.util.commitObject();
    },
}

var testPlugin: Plugin = {
    name: "Textbox",
    type: "LevelEditPropsPlugin",
    plugin: testPluginLoad
}