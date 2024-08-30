package system;

import js.node.webkit.MenuItem;
import js.node.webkit.Menu;

class System {
    public static function createMenuItem(): MenuItem {
        var mi = new MenuItem({label: "System"});
        
        var m = new Menu();
        m.append(Autosave.createMenuItem());
        m.append(Autosave.createManualBackupMenuItem());
        
        mi.submenu = m;
        return mi;
    }
}