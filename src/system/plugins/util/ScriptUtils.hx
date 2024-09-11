package system.plugins.util;

import cdb.Database;
import util.CastleDBEnumParser;

class ScriptUtils {
    static var parser: CastleDBEnumParser = new CastleDBEnumParser([
        0 => { 
            e: ScriptCommand, 
            refs: [[1, 2, 1]] // Warp constructor's third parameter is of type WarpType, which is at index 1 in the config
        },
        1 => { 
            e: WarpType, 
            refs: [[1, 1, 2]] // Walk constructor's second parameter is of type Direction, which is at index 2 in the config
        },
        2 => { 
            e: Direction, 
            refs: [] // No references in Direction enum
        },
        3 => { 
            e: EventType, 
            refs: [[2, 0, 3]] // Warp constructor's first parameter is of type Int, but there's no further enum reference
        }
    ]);

    var lvl: Level;
    var base: Database;

    public function new(lvl: Level) {
        this.lvl = lvl;
        if(lvl != null){
            this.base = lvl.model.base;
        }
    }

    

    public function extractScript(rowObject: Dynamic): ScriptCommand {
       return cast parser.parse(rowObject.script, 0);
    }

    public function serializeScript(script: ScriptCommand): Array<Dynamic> {
        return cast parser.serialize(script, 0);
    }

    public function createWarpEventType(levelName: String): Array<Dynamic> {
        var warps = new LevelUtils(lvl).getWarps(levelName);
        return [2, warps.length];
    }
}

enum ScriptCommand {
	ScriptRef( refId : String );
	Warp( toMap : String, warpToId : Int, warpType : WarpType );
	Textbox( text : String );
}

enum WarpType {
	Instant;
	Walk( amount : Int, direction : Direction );
}

enum Direction {
	Up;
	Right;
	Down;
	Left;
}

enum EventType {
	OnStep;
	OnInteract;
	Warp( id : Int );
	OnMapEnter;
}