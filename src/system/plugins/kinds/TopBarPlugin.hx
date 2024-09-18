package system.plugins.kinds;

import system.plugins.Plugin.Plugins;
import js.node.webkit.MenuItem;
import js.node.webkit.Menu;

abstract class TopBarPlugin extends Plugin {
	public function getType():String {
		return "TopBarPlugin";
	}

	public abstract function getMenu():TopBarPluginMenuInjection;

	public static function getAllPlugins():Array<TopBarPlugin> {
		var result = new Array<TopBarPlugin>();
		for (key => plugins in Plugins.LOADED) {
			if (key != "TopBarPlugin")
				continue;
			for (eachPlugin in (cast plugins : Array<TopBarPlugin>)) {
				result.push(eachPlugin);
			}
		}
		return result;
	}
}

enum TopBarPluginMenuInjection {
	NewMenu(menu:MenuItem);
	AddToMenu(menuTag:String, menu:MenuItem);
}
