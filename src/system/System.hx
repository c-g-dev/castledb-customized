package system;

import js.node.webkit.MenuItem;
import js.node.webkit.Menu;

/*
typedef LevelObjectScriptObjectRef = Dynamic;

typedef LevelObjectScript {
    var appliesToObject : (LevelObjectScriptObjectRef) -> Bool;
    var execute : (LevelObjectScriptObjectRef) -> Void;
}
*/

class System {
    public static function createMenuItem(): MenuItem {
        var mi = new MenuItem({label: "System"});
        
        var m = new Menu();
        m.append(Autosave.createMenuItem());
        m.append(Autosave.createManualBackupMenuItem());
        
        mi.submenu = m;

        /*{
            appliesToObject: function(obj) {
                return obj is LevelObject;
            },
            execute: function(obj) {
                Autosave.init(obj);
            }
        }*/

        return mi;
    }
}

