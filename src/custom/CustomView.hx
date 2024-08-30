package custom;

import js.html.Element;
import cdb.Sheet;

abstract class CustomView {
    var sheet: Sheet;
    var idx: Int;

    public function new(sheet: Sheet, idx: Int) {
        this.sheet = sheet;
        this.idx = idx;
    }
    
    public abstract function renderElement(e: Element): Element;
    public function unrenderElement(cb: () -> Void):Void {
        cb();
    }
    public abstract function setTopBar(e: Element): Void;
    public abstract function writeToLine(): Dynamic;
    public abstract function on(e: CustomViewLifecycle): Void;

    public function saveToDB() {
        var line = this.writeToLine();
        this.sheet.updateLine(this.idx, line);
    }
    
}

enum CustomViewLifecycle {
    Start;
    Close;
}