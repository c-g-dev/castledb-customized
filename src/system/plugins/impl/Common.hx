package system.plugins.impl;

import system.plugins.util.LevelObjectPluginContext;
import system.plugins.kinds.Script_LevelObjectPlugin;
import js.html.SelectElement;
import js.html.Element;
import system.plugins.Plugin.RowObject;
import system.plugins.kinds.Display_LevelObjectPlugin;
import system.plugins.kinds.EditProps_LevelObjectPlugin;
import js.html.Element;
import js.html.TextAreaElement;
import js.jquery.Helper.*;
import js.jquery.JQuery;


class ClearScript_Script_Plugin extends Script_LevelObjectPlugin {
	public function appliesToObject(context:LevelObjectPluginContext):Bool {
		return !LevelObjectScriptUtil.isScriptEmpty(context);
	}

	public function getScriptName(context:LevelObjectPluginContext):String {
		return "Clear script";
	}

	public function execute(context:LevelObjectPluginContext) {
		Reflect.deleteField(context.rowObject, "script");
	}
}
