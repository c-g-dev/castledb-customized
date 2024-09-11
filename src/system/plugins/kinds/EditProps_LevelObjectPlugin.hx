package system.plugins.kinds;

import haxe.Timer;
import system.plugins.util.LevelObjectPluginContext;
import format.abc.Context;
import system.plugins.Plugin.Plugins;
import system.plugins.Plugin.RowObject;
import js.html.OptionElement;
import util.Toast;
import js.html.Element;
import js.jquery.Helper.*;
import js.jquery.JQuery;

abstract class EditProps_LevelObjectPlugin extends Plugin {

    public function new() {
		
	}
	
    public function getType(): String {
        return "EditProps_LevelObjectPlugin";
    }
    
    public abstract function appliesToObject(context: LevelObjectPluginContext): Bool;
    public abstract function render(context: LevelObjectPluginContext): Void;
    public abstract function writeToSheet(context: LevelObjectPluginContext): Void;
}


class EditPropsUtil {

    public static function renderPlugin(context: LevelObjectPluginContext): Void {
        for (key => plugins in Plugins.LOADED) {
            if (key != "EditProps_LevelObjectPlugin") continue;
            for (eachPlugin in (cast plugins: Array<EditProps_LevelObjectPlugin>)) {
                if (eachPlugin.appliesToObject(context)) {
                    J(context.defaultEditPropsElement).hide();
                    eachPlugin.render(context);
                    context.appliedPlugins.push(eachPlugin);
                }
            }
        }
    }

    public static function createSaveButton(context: LevelObjectPluginContext, plugin: EditProps_LevelObjectPlugin): Element {
        var button = J("<input class='button' type='submit' value='Save'/>");
        button.click((e) -> {
            plugin.writeToSheet(context);
            context.level.save();
            Toast.show("Saved");
        });
        return button.get(0);
    }

    public static function createRenderNormalFormButton(context: LevelObjectPluginContext, plugin: EditProps_LevelObjectPlugin): Element {
        var button = J("<input class='button' type='submit' value='Edit All Props'/>");
        button.click((e) -> {
            J(context.defaultEditPropsElement).show();
        });
        return button.get(0);
    }
}