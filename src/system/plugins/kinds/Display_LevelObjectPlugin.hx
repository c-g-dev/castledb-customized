package system.plugins.kinds;

import system.plugins.Plugin.Plugins;
import system.plugins.util.LevelObjectPluginContext;
import lvl.Image;
import util.Caching;
import system.plugins.Plugin.RowObject;

abstract class Display_LevelObjectPlugin extends Plugin {

    public function new() {
		
	}
	
    public function getType(): String {
        return "Display_LevelObjectPlugin";
    }
    
    public abstract function appliesToObject(context: LevelObjectPluginContext): Bool;
    public abstract function execute(context: LevelObjectPluginContext): Void;
}

class LevelObjectDisplayUtil {

    public static function apply(context: LevelObjectPluginContext) {
        // Apply all Display_LevelObjectPlugin plugins
        for (eachPlugin in (cast Plugins.LOADED["Display_LevelObjectPlugin"]: Array<Display_LevelObjectPlugin>)) {
            if(!eachPlugin.appliesToObject(context)) continue;
            eachPlugin.execute(context);
        }
        
    }
    public static function textOverlay(context: LevelObjectPluginContext, text: String, color: Int, tessellate: Bool): Void {
        var img: Image = Caching.get("textOverlay_" + text + "_" + color);
        if(img == null) {
            trace("making text image in cache");
            img = new Image(32, 32);
            img.text(text, 16, 16, color);
            Caching.set("textOverlay_" + text + "_" + color, img);
        }
        if(tessellate) {
            var stride = context.rowObject.width;
            var draft = context.rowObject.height;
            for(py in 0...draft){
                for(px in 0...stride){
                    context.levelObjectImage.image.draw(img, context.levelObjectImage.x + (px*32), context.levelObjectImage.y + (py*32));
                }
            }
        }
        else{
            context.levelObjectImage.image.draw(img, context.levelObjectImage.x,context.levelObjectImage.y);
        }
    }
}