package custom.charbuilder;

import js.html.AddEventListenerOptions;
import util.WebviewCommunicator;
import util.LocalServer;
import haxe.io.Bytes;
import js.html.URL;
import js.html.Blob;
import sys.io.File;
import js.html.Attr;
import haxe.Json;
import js.Browser;
import custom.CustomView.CustomViewLifecycle;
import cdb.Sheet;
import js.html.Element;


class CharBuilderCustomView extends CustomView {
    var webview: Element;

    public function new(model: Model, sheet: Sheet, idx: Int) {
        super(sheet, idx);



    }

    public function renderElement(e: Element):Element {
        webview = Browser.document.createElement("webview");
        webview.attributes.setNamedItem(Browser.document.createAttribute("allownw"));

        trace(LocalServer.getLocalURL("charbuilder.html"));
        untyped webview.src = LocalServer.getLocalURL("charbuilder.html"); 
        
        if(sheet.lines[idx].data != null && sheet.lines[idx].data != "") {
            trace("sheet.lines[idx].data: " + sheet.lines[idx].data);
            webview.addEventListener("loadstop", function () {
                var io = new WebviewCommunicator();
                io.send(webview, "import", sheet.lines[idx].data, (data) -> {});
            }, {once: true});
        }

        e.append(webview);

        return webview;
    }

    var line: Dynamic;
    public override function unrenderElement(cb: () -> Void):Void {
        trace("await response from webview..."); 
        var io = new WebviewCommunicator();
        io.send(webview, "export", {}, (data) -> {
           trace("received data from webview: " + data); 
           line = {
             name: sheet.lines[idx].name,
             data: data
            };
           cb();
        });
    }

    public function setTopBar(e:Element) {}

    public function writeToLine():Dynamic {
        return line;
    }

    public function on(e:CustomViewLifecycle) {
        
    }
}
