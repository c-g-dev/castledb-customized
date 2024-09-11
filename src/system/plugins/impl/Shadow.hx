package system.plugins.impl;

import system.plugins.kinds.Display_LevelObjectPlugin;
import js.Browser;
import js.html.SelectElement;
import system.plugins.util.LevelObjectPluginContext;
import system.plugins.kinds.EditProps_LevelObjectPlugin;
import js.jquery.Helper.*;
import js.jquery.JQuery;

class Shadow_EditProps_Plugin extends EditProps_LevelObjectPlugin {
	var html = "
        <div>
            <h3>Shadow</h3>
            <label for='fadeDirection'>Fade Direction:</label>
            <select id='fadeDirection'>
                <option value='Up'>Up</option>
                <option value='Down'>Down</option>
                <option value='Left'>Left</option>
                <option value='Right'>Right</option>
            </select>
            <br>
            <label for='layer'>Layer:</label>
            <select id='layer'></select>
        </div>
    ";

	public function appliesToObject(context:LevelObjectPluginContext):Bool {
		return context.layerName == "other" && context.rowObject.kind == "shadow";
	}

	public function render(context:LevelObjectPluginContext) {
		var form = J(html);
		J(context.propsContainer).append(form);

		var fadeDirectionElement = cast(context.propsContainer.querySelector("#fadeDirection"), SelectElement);
		var layerElement = cast(context.propsContainer.querySelector("#layer"), SelectElement);

		var layers = context.levelUtils.getLayers();
		for (layer in layers) {
			var option = (cast Browser.document.createElement('option'): SelectElement);
			option.value = layer.name;
			option.innerText = layer.name;
			layerElement.appendChild(option);

            //set intial values for fadeDirectionElement and layerElement
            if (context.rowObject.extraData != null && context.rowObject.extraData.length > 0) {
                if (context.rowObject.extraData[0].key == "fadeDirection") {
                    fadeDirectionElement.value = context.rowObject.extraData[0].value;
                }
                if (context.rowObject.extraData[1].key == "layer") {
                    layerElement.value = context.rowObject.extraData[1].value;
                }
            }

		}

		J(context.propsContainer).append(EditPropsUtil.createSaveButton(context, this));
		J(context.propsContainer).append(EditPropsUtil.createRenderNormalFormButton(context, this));
	}

    public function writeToSheet(context:LevelObjectPluginContext) {
        var fadeDirectionElement = cast(context.propsContainer.querySelector("#fadeDirection"), SelectElement);
        var layerElement = cast(context.propsContainer.querySelector("#layer"), SelectElement);
    
        context.rowObject.extraData = [
            {
                key: "fadeDirection",
                value: fadeDirectionElement.value
            },
            {
                key: "layer",
                value: layerElement.value
            }
        ];
    }
}

class Shadow_Display_Plugin extends Display_LevelObjectPlugin {
	public function appliesToObject(context:LevelObjectPluginContext):Bool {
        //trace("Shadow_Display_Plugin appliesToObject: " + context.layerName + " " + context.rowObject.kind);
		return context.layerName == "other" && context.rowObject.kind != null && context.rowObject.kind == "shadow";
	}

	public function execute(context:LevelObjectPluginContext) {
		LevelObjectDisplayUtil.textOverlay(context, "S", 0xFFF00101, true);
	}
}

