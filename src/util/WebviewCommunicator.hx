package util;

import haxe.Json;
import js.Browser;
import js.html.Element;

class WebviewCommunicator {

    public function new() {
        
    }

    public function send(webview: Element, tag: String, message: Dynamic, callback: Dynamic -> Void) {
        var callb = null;
        callb = (event: Dynamic) -> {
            if(event.data.type == 'responseData_' + tag) {
                callback(event.data.payload);
                Browser.window.removeEventListener('message', callb);
            }
        };
        
        Browser.window.addEventListener('message',callb);
        untyped webview.contentWindow.postMessage({ type: 'receiveData_' + tag, payload: message }, '*');
    }

    public function receive(tag: String, callback: Dynamic -> Dynamic) {
        var callb = (event: Dynamic) -> {
            if(event.data.type == 'receiveData_' + tag) {
                var data = callback(event.data.payload);
                event.source.postMessage({ type: 'responseData_' + tag, payload: data }, '*');
            }
        };

        Browser.window.addEventListener('message', callb);
    }
}