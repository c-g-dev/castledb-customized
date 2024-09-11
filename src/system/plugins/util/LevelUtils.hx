package system.plugins.util;

import lvl.LayerData;
import cdb.Database;

using ludi.commons.extensions.All;

class LevelUtils {
    var lvl: Level;
    var base: Database;

    public function new(lvl: Level) {
        this.lvl = lvl;
        this.base = lvl.model.base;
    }

    public function getLayers(): Array<LayerData> {
        return lvl.layers;
    }

    public function getLevels(): Array<Dynamic> {
        for (sheet in base.sheets) {
            if(sheet.isLevel()){
                return [sheet.lines];
            }
        }
        return [];
    }

    public function getLevel(name: String) {
        return getLevels().filter(function(s) {
            return s.name == name;
        })[0];
    }

    public function getWarps(levelName: String): Array<Dynamic> {
        var level = lvl.layers.find((l) -> {
            return l.name == levelName;
        });

        var events = Reflect.field(level, "events");

        return events.filter(function(e) {
            return new EventUtils().isWarp(e);
        });

    }

    
}


class EventUtils {

    public function new() {
        
    }

    public function isWarp(e: Dynamic): Bool{
        return e.script != null && e.script[0] == 2;
    }

}