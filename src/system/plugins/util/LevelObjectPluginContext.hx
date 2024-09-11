package system.plugins.util;

import format.abc.Data.ABCData;
import lvl.LayerData;
import cdb.Sheet;
import lvl.Image3D;
import js.html.Element;
import system.plugins.Plugin.RowObject;
import js.jquery.Helper.*;
import js.jquery.JQuery;

class LevelObjectPluginContext {
	public var layerName: String;
    public var level: Level;
	public var appliedPlugins: Array<Plugin> = [];
	public var rowObject: RowObject;
    public var layerData: LayerData;
    public var rowIdx: Int;
	public var propsContainer: Element;
	public var defaultEditPropsElement: Element;
	public var levelObjectImage: {
		image: Image3D,
		x: Int,
		y: Int
	};
	public var levelUtils: LevelUtils;
    public var scriptUtils: ScriptUtils;

    function new() {
        
    }

    public static function createForLevelObjectProps(lvl: Level, layerData : LayerData, objectIdx : Int): LevelObjectPluginContext {
        var ctx = new LevelObjectPluginContext();
        ctx.rowObject = RowObject.fromLayerData(layerData, objectIdx);
        ctx.level = lvl;
        ctx.layerData = layerData;
        ctx.layerName = lvl.currentLayer.name;
        ctx.rowIdx = objectIdx;
        ctx.propsContainer = J("#content .level .levelSidebar").get(0);
        ctx.defaultEditPropsElement = J("#content .level .levelSidebar .popup").get(0);
        ctx.levelUtils = new LevelUtils(lvl);
        ctx.scriptUtils = new ScriptUtils(lvl);
        return ctx;
    }

    public static function createForLevelObjectDisplay(layerData : LayerData, image: Image3D, x: Int, y: Int, obj: Dynamic): LevelObjectPluginContext {
        var ctx = new LevelObjectPluginContext();
        ctx.layerName = layerData.name;
        ctx.levelObjectImage = { image: image, x: x, y: y };
        ctx.rowObject = RowObject.fromTransient(obj);
        return ctx;
    }

	public function refresh(): Void {
        this.rowObject = this.rowObject.molt();
	}

	public function cleanup(): Void {
		this.rowObject.commit();
	}
}