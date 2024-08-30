package util;

import js.node.Process;
import js.node.http.Server;
import js.node.Http;
import js.node.Path;
import js.node.Fs;

class LocalServer {
    private static var instance:LocalServer;
    private static var port:Int = 1337;
    private var server:js.node.http.Server;
    private static var basePath:String = Sys.getCwd();
    
    private function new() {
        server = Http.createServer(function(req, res) {
            var filepath = Path.join(basePath, req.url);
            Fs.readFile(filepath, function(err, data) {
                if (err != null) {
                    res.writeHead(404, {'Content-Type': 'text/html'});
                    res.end("404 Not Found");
                } else {
                    res.writeHead(200, {'Content-Type': 'text/html'});
                    res.end(data);
                }
            });
        });
        server.listen(port, "127.0.0.1");
    }

    public static function getInstance():LocalServer {
        if (instance == null) {
            instance = new LocalServer();
        }
        return instance;
    }

    public static function getLocalURL(filepath:String):String {
        getInstance();
        return "http://127.0.0.1:" + port + "/" + filepath;
    }
}