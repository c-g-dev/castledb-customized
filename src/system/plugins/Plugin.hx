package system.plugins;

import system.plugins.impl.Common.ClearScript_Script_Plugin;
import system.plugins.impl.Warp.Warp_EditProps_Plugin;
import system.plugins.impl.Warp.Warp_Display_Plugin;
import system.plugins.impl.Shadow.Shadow_EditProps_Plugin;
import system.plugins.impl.Shadow.Shadow_Display_Plugin;
import system.plugins.util.ScriptUtils;
import system.plugins.kinds.Script_LevelObjectPlugin.CreateNewObjectScript;
import lvl.LayerData;
import system.plugins.impl.Textbox.CreateTextbox_Script_Plugin;
import system.plugins.impl.Textbox.Textbox_Display_Plugin;
import system.plugins.impl.Textbox.Textbox_EditProps_Plugin;
import lvl.Image3D;
import system.plugins.util.LevelUtils;
import haxe.macro.Type.Ref;
import js.html.Element;
import util.Toast;
import js.html.OptionElement;
import cdb.Sheet;
import js.jquery.JQuery;
import haxe.Json;
import haxe.io.Path;
import sys.io.File;

using StringTools;

abstract class Plugin {
	public abstract function getType():String;
}

@:forward
abstract RowObject(Dynamic) from Dynamic to Dynamic {
	public static var STATE_CACHE:Array<{layerData:LayerData, idx:Int, rowObject:RowObject}> = [];

	function new(rowObject:Dynamic) {
		this = rowObject;
	}

	public static function fromLayerData(layerData:LayerData, idx:Int):RowObject {
		@:privateAccess var obj = new RowObject(Reflect.field(layerData.level.obj, layerData.name)[idx]);
		STATE_CACHE.push({layerData: layerData, idx: idx, rowObject: new RowObject(obj)});
		return obj;
	}

	public static function fromTransient(obj:Dynamic):RowObject {
		return new RowObject(obj);
	}

	public function molt():RowObject {
		for (eachRow in STATE_CACHE) {
			if (eachRow.rowObject == this) {
				@:privateAccess eachRow.rowObject = new RowObject(Reflect.field(eachRow.layerData.level.obj, eachRow.layerData.name)[eachRow.idx]);
				return eachRow.rowObject;
			}
		}
		return this;
	}

	public function commit(?remove:Bool = true):Void {
		for (eachRow in STATE_CACHE) {
			if (eachRow.rowObject == this) {
				@:privateAccess Reflect.field(eachRow.layerData.level.obj, eachRow.layerData.name)[eachRow.idx] = this;
				if (remove) {
					STATE_CACHE.remove(eachRow);
				}
			}
		}
	}
}

class Plugins {
	public static var LOADED:Map<String, Array<Plugin>> = new Map<String, Array<Plugin>>();
	static final PLUGIN_DIRECTORY = "./plugins";
	static var GLOBAL:Dynamic = {};

	public static function loadAll(model:Model) {
		/*trace("Plugins.loadAll");
			var dir = sys.FileSystem.readDirectory(PLUGIN_DIRECTORY);
			for (file in dir) {
				trace("found file: " + file);
				if (file.endsWith(".hx")) {
					trace("loading plugin: " + file);
					try {
						load(PLUGIN_DIRECTORY + "/" + file);
						trace("Successfully loaded plugin: " + file);
					} catch (e) {
						trace("Error loading plugin: " + file + " \n" + e);
					}
				}
		}*/
		/*addGlobalVar("levelUtils", new LevelUtils(model.base));
			addGlobalVar("scriptUtils", new ScriptUtils(model.base));
			addPlugin(LevelEditPropsPlugin_FACTORY(GLOBAL)); */

			
		addPlugin(new Shadow_EditProps_Plugin());
		addPlugin(new Shadow_Display_Plugin());
		addPlugin(new CreateNewObjectScript("events", "Warp", "script", {script: new ScriptUtils(null).serializeScript(Warp("", 0, Instant))}));
		addPlugin(new CreateNewObjectScript("other", "Shadow", "kind", {kind: "shadow"}));
		addPlugin(new CreateTextbox_Script_Plugin());
		addPlugin(new Textbox_Display_Plugin());
		addPlugin(new Textbox_EditProps_Plugin());
		addPlugin(new Warp_Display_Plugin());
		addPlugin(new Warp_EditProps_Plugin());
		addPlugin(new ClearScript_Script_Plugin());
		
	}

	public static function addPlugin(plugin:Plugin) {
		if (!LOADED.exists(plugin.getType())) {
			LOADED.set(plugin.getType(), new Array<Plugin>());
		}

		LOADED.get(plugin.getType()).push(plugin);
	}

	public static function addGlobalVar(key:String, value:Dynamic) {
		Reflect.setField(GLOBAL, key, value);
	}

	public static function load(filePath:String) {
		var pluginFile = sys.io.File.getContent(filePath);

		var parser = new hscript.Parser();
		var ast = parser.parseString(pluginFile);
		var interp = new hscript.Interp();
		interp.variables.set("Global", GLOBAL);
		var ret = interp.execute(ast);
		// if ret is array
		var loadedPlugins:Array<Plugin> = [];
		if (ret is Array) {
			loadedPlugins = ret;
		} else {
			loadedPlugins = [cast ret];
		}

		for (pluginObject in loadedPlugins) {
			addPlugin(pluginObject);
		}
	}
}
