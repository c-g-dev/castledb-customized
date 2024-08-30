package custom;

import haxe.Json;
import cdb.Sheet;
import custom.CustomView.CustomViewLifecycle;
import js.html.Element;

import js.html.CanvasElement;
import js.html.MouseEvent;
import js.html.Event;
import js.Browser;
import js.html.ImageElement;
import js.html.Element;
import js.html.InputElement;
import js.html.CanvasRenderingContext2D;
import js.html.FileReader;


class GuiBuilder extends CustomView {
    var builder: GUIBuilderObject;
    //var currentLine: Dynamic;
    var data: Dynamic;

    public function new(model: Model, sheet: Sheet, idx: Int) {
        super(sheet, idx);
        
        builder = new GUIBuilderObject(model);
        if(sheet.lines[idx].data != null && sheet.lines[idx].data != "") {
            trace("sheet.lines[idx].data: " + sheet.lines[idx].data);
            data = Json.parse(sheet.lines[idx].data);
            if(data.image != null && data.rects != null) {
                builder.loadState(data.image, data.rects);
            }
        }
    }
    
    public function renderElement(e: Element):Element {
        var ee = this.builder.baseElement;
        e.append(ee);
        return ee;
    }

    public function setTopBar(e:Element) {}

    public function writeToLine():Dynamic {
        var id = (sheet.lines[idx].id == null) ? idx : sheet.lines[idx].id;
        var line = {
            id: id,
            data: {
                @:privateAccess if(builder.image == null || builder.rectList == null){
                    null;
                }
                else {
                    Json.stringify({
                        image: builder.imagePath,
                        rects: builder.rectList
                    });
                }
            }
        }
        return line;
    }

    public function on(e:CustomViewLifecycle) {}

}


class GUIBuilderObject {
    public var baseElement: Element;
    var canvas:CanvasElement;
    var fileInput:InputElement;
    var rectList:Array<Dynamic>;
    var rectListView:Element;
    var context:CanvasRenderingContext2D;
    var image:ImageElement;
    public var imagePath: String;
    var drawing:Bool;
    var resizing:Bool;
    var moving:Bool;
    var startX:Int;
    var startY:Int;
    var offsetX:Int;
    var offsetY:Int;
    var selectedRectIndex:Int = -1;
    var cornerSize:Int = 8;
    var model: Model;

    public function new(model: Model) {
        this.model = model;
        initUI();
    }

    public function loadState(imgPath: String, rects: Array<Dynamic>){
        // load object model (i.e. change image and set rects), then rerender
        this.imagePath = model.getAbsPath(imgPath);
        loadImage(this.imagePath, function(i) {
            image = i;
            rectList = rects;
            refreshCanvas();
        }, function() {
            throw "Could not load " + imgPath;
        });
    }

    
	public static function loadImage( url : String, callb : ImageElement -> Void, ?onError : Void -> Void ) {
		var i = js.Browser.document.createImageElement();
		i.onload = function(_) {
			callb(i);
		};
		i.onerror = function(_) {
			if( onError != null ) {
				onError();
				return;
			}
			callb(i);
		};
		i.src = "file://"+url;
	}


    private function initUI() {
        this.baseElement = Browser.document.createElement("div");
        
        var container = Browser.document.createElement("div");
        container.style.display = "flex";
        container.style.flexDirection = "row";
        baseElement.appendChild(container);

        var leftPanel = Browser.document.createElement("div");
        leftPanel.style.display = "flex";
        leftPanel.style.flexDirection = "column";
        container.appendChild(leftPanel);

        initFileInput(leftPanel);
        initCanvas(leftPanel);

        rectListView = Browser.document.createElement("div");
        rectListView.style.marginLeft = "20px";
        container.appendChild(rectListView);

        rectList = [];
        addCanvasListeners();
    }

    private function initCanvas(container:Element) {
        canvas = Browser.document.createCanvasElement();
        canvas.width = 800;
        canvas.height = 600;
        container.appendChild(canvas);
        context = canvas.getContext("2d");
    }

    private function initFileInput(container:Element) {
        fileInput = Browser.document.createInputElement();
        fileInput.type = "file";
        fileInput.accept = "image/*";
        fileInput.onchange = loadNewImage;
        container.appendChild(fileInput);
    }

    private function loadNewImage(event:Event):Void {
        var file = fileInput.files[0];
        this.imagePath = file.name;
        if (file != null) {
            var reader = new FileReader();
            reader.onload = function(e) {
                image = cast js.Browser.document.createElement("img");
                image.src = e.target.result;
                image.onload = function(_) {
                    context.clearRect(0, 0, canvas.width, canvas.height);
                    context.drawImage(image, 0, 0);
                }
            }
            reader.readAsDataURL(file);
        }
    }

    private function updateListView() {
        rectListView.innerHTML = '';
        if (selectedRectIndex != -1) {
            var rect = rectList[selectedRectIndex];

            var addButton = Browser.document.createElement("button");
            addButton.innerText = "[+] Add Property";
            addButton.onclick = function(e) {
                var key = "newProp";
                while (Reflect.hasField(rect, key)) {
                    key += "1";
                }
                Reflect.setField(rect, key, "");
                updateListView();
            }
            rectListView.appendChild(addButton);

            var deleteButton = Browser.document.createElement("button");
            deleteButton.innerText = "Delete Rectangle";
            deleteButton.onclick = function(e) {
                rectList.splice(selectedRectIndex, 1);
                selectedRectIndex = -1;
                updateListView();
                refreshCanvas();
            }
            rectListView.appendChild(deleteButton);

            for (key in Reflect.fields(rect)) {
                var div = Browser.document.createElement("div");

                var coreProps = ["id", "x", "y", "width", "height"];
                if(coreProps.contains(key)){
                    var label = Browser.document.createElement("span");
                    label.innerText = key;
                    div.appendChild(label);
                } else {
                    var label: InputElement = cast Browser.document.createElement("input");
                    label.type = "text";
                    label.value = key;
                    label.onblur = function(e) {
                        var field = Reflect.field(rect, key);
                        Reflect.deleteField(rect, key);
                        Reflect.setField(rect, label.value, field);
                        refreshCanvas();
                    }
                    div.appendChild(label);
                }

                var input: InputElement = cast Browser.document.createElement("input");
                input.type = "text";
                input.value = Reflect.field(rect, key);
                input.onblur = function(e) {
                    Reflect.setField(rect, key, input.value);
                    refreshCanvas();
                }
                div.appendChild(input);

                rectListView.appendChild(div);
            }

        } else {
            for (rect in rectList) {
                var div = Browser.document.createElement("div");
                div.innerText = 'Rect: ' + rect.x + ', ' + rect.y + ', ' + rect.width + ', ' + rect.height;
                div.onclick = function(e) {
                    selectedRectIndex = rectList.indexOf(rect);
                    updateListView();
                    refreshCanvas();
                }
                rectListView.appendChild(div);
            }
        }
    }

    private function addCanvasListeners() {
        canvas.onmousedown = function(event:MouseEvent) {
            startX = event.clientX - canvas.offsetLeft;
            startY = event.clientY - canvas.offsetTop;

            selectedRectIndex = -1;
            for (i in 0...rectList.length) {
                var rect = rectList[i];
                if (isOnCorner(startX, startY, rect)) {
                    selectedRectIndex = i;
                    resizing = true;
                    break;
                } else if (isWithinRectangle(startX, startY, rect)) {
                    selectedRectIndex = i;
                    moving = true;
                    offsetX = startX - rect.x;
                    offsetY = startY - rect.y;
                    break;
                }
            }
            
            if (selectedRectIndex == -1) {
                drawing = true;
            }
            refreshCanvas();
        }

        canvas.onmousemove = function(event:MouseEvent) {
            var mouseX = event.clientX - canvas.offsetLeft;
            var mouseY = event.clientY - canvas.offsetTop;
            if (drawing) {
                context.clearRect(0, 0, canvas.width, canvas.height);
                context.drawImage(image, 0, 0);
                context.strokeRect(startX, startY, mouseX - startX, mouseY - startY);
            } else if (resizing && selectedRectIndex != -1) {
                var rect = rectList[selectedRectIndex];
                rect.width = mouseX - rect.x;
                rect.height = mouseY - rect.y;
                refreshCanvas();
            } else if (moving && selectedRectIndex != -1) {
                var rect = rectList[selectedRectIndex];
                rect.x = mouseX - offsetX;
                rect.y = mouseY - offsetY;
                refreshCanvas();
            }
        }

        canvas.onmouseup = function(event:MouseEvent) {
            if (drawing) {
                drawing = false;
                var endX = event.clientX - canvas.offsetLeft;
                var endY = event.clientY - canvas.offsetTop;
                var rect = {id: rectList.length + "", x: startX, y: startY, width: endX - startX, height: endY - startY};
                rectList.push(rect);
                refreshCanvas();
                updateListView();
            }
            resizing = false;
            moving = false;
        }
    }

    private function refreshCanvas() {
        if(image != null){
            canvas.width = image.width;
            canvas.height = image.height;
        }
        
        context.clearRect(0, 0, canvas.width, canvas.height);
        context.drawImage(image, 0, 0);
        for (i in 0...rectList.length) {
            var rect = rectList[i];
            if (i == selectedRectIndex) {
                context.strokeStyle = "#00FF00";
            } else {
                context.strokeStyle = "#000000";
            }
            context.strokeRect(rect.x, rect.y, rect.width, rect.height);
            drawCorners(rect);
        }
        updateListView();
    }

    private function drawCorners(rect:Dynamic) {
        // Draw small rectangles at corners for resizing
        context.fillStyle = "#FF0000";
        context.fillRect(rect.x - cornerSize / 2, rect.y - cornerSize / 2, cornerSize, cornerSize);
        context.fillRect(rect.x + rect.width - cornerSize / 2, rect.y - cornerSize / 2, cornerSize, cornerSize);
        context.fillRect(rect.x - cornerSize / 2, rect.y + rect.height - cornerSize / 2, cornerSize, cornerSize);
        context.fillRect(rect.x + rect.width - cornerSize / 2, rect.y + rect.height - cornerSize / 2, cornerSize, cornerSize);
    }

    private function isOnCorner(x:Int, y:Int, rect:Dynamic):Bool {
        if (isWithinRegion(x, y, rect.x - cornerSize / 2, rect.y - cornerSize / 2, cornerSize, cornerSize)) return true;
        if (isWithinRegion(x, y, rect.x + rect.width - cornerSize / 2, rect.y - cornerSize / 2, cornerSize, cornerSize)) return true;
        if (isWithinRegion(x, y, rect.x - cornerSize / 2, rect.y + rect.height - cornerSize / 2, cornerSize, cornerSize)) return true;
        if (isWithinRegion(x, y, rect.x + rect.width - cornerSize / 2, rect.y + rect.height - cornerSize / 2, cornerSize, cornerSize)) return true;
        return false;
    }

    private function isWithinRectangle(x:Float, y:Float, rect:Dynamic):Bool {
        return x >= rect.x && x <= rect.x + rect.width && y >= rect.y && y <= rect.y + rect.height;
    }

    private function isWithinRegion(x:Float, y:Float, rx:Float, ry:Float, rwidth:Float, rheight:Float):Bool {
        return x >= rx && x <= rx + rwidth && y >= ry && y <= ry + rheight;
    }
}