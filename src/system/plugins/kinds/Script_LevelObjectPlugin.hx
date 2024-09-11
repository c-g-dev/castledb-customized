package system.plugins.kinds;

import system.plugins.util.LevelObjectPluginContext;
import system.plugins.Plugin.Plugins;
import js.html.OptionElement;
import js.html.SelectElement;
import js.html.Element;
import system.plugins.Plugin.RowObject;
import js.jquery.Helper.*;
import js.jquery.JQuery;

using ludi.commons.extensions.All;

abstract class Script_LevelObjectPlugin extends Plugin {
	public function new() {
		
	}
	public function getType():String {
		return "Script_LevelObjectPlugin";
	}

	public abstract function appliesToObject(context:LevelObjectPluginContext):Bool;

	public abstract function getScriptName(context:LevelObjectPluginContext):String;

	public abstract function execute(context:LevelObjectPluginContext):Void;
}

class LevelObjectScriptUtil {
	public static function isScriptEmpty(context:LevelObjectPluginContext):Bool {
		return context.rowObject.script == null
			|| context.rowObject.script == ""
			|| ((context.rowObject.script is Array) && context.rowObject.script.length == 0);
	}

    public static function buildScriptDropdown(context:LevelObjectPluginContext):Element {
		var applicableScripts:Array<Script_LevelObjectPlugin> = new Array<Script_LevelObjectPlugin>();
		for (key => plugins in Plugins.LOADED) {
			if (key != "Script_LevelObjectPlugin")
				continue;
			for (eachPlugin in plugins) {
				if ((cast eachPlugin: Script_LevelObjectPlugin).appliesToObject(context)) {
					applicableScripts.push(cast eachPlugin);
				}
			}
		}

		var container = js.Browser.document.createElement("div");

		var dropdown:SelectElement = cast js.Browser.document.createElement("select");
		for (script in applicableScripts) {
			var option:OptionElement = cast js.Browser.document.createElement("option");
			option.text = script.getScriptName(context);
			option.value = script.getScriptName(context);
			dropdown.appendChild(option);
		}

		var runButton = js.Browser.document.createElement("button");
		runButton.textContent = "Run";
		runButton.addEventListener("click", function(e) {
			context.refresh();
			var selectedOption = dropdown.value;
			var chosenPlugin = applicableScripts.find(function(script) {
				return script.getScriptName(context) == selectedOption;
			});
			if (chosenPlugin != null) {
				chosenPlugin.execute(context);
				@:privateAccess context.level.editProps(context.layerData, context.rowIdx);
			}
		});

		container.appendChild(dropdown);
		container.appendChild(runButton);

		return container;
	}
}


class CreateNewObjectScript extends Script_LevelObjectPlugin {
	var layerName: String;
	var objectName: String;
	var checkForEmptyField: String;
	var initValue: Dynamic;

	public function new(layerName: String, objectName: String, checkForEmptyField: String, initValue: Dynamic) {
		super();
		this.layerName = layerName;
		this.objectName = objectName;
		this.checkForEmptyField = checkForEmptyField;
		this.initValue = initValue;
	}

	public function appliesToObject(context:LevelObjectPluginContext):Bool {
		var field: Dynamic =  Reflect.field(context.rowObject, this.checkForEmptyField);
		return context.layerName == this.layerName && ((field == null) || (field == "") || ((field is Array) && (field.length == 0)));
	}

	public function getScriptName(context:LevelObjectPluginContext):String {
		return "Create " + this.objectName;
	}

	public function execute(context:LevelObjectPluginContext):Void {
		for (field in Reflect.fields(this.initValue)) {
			Reflect.setField(context.rowObject, field, Reflect.field(this.initValue, field));
		}
	}
}