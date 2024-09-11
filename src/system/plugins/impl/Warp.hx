package system.plugins.impl;

import js.html.InputElement;
import system.plugins.util.LevelObjectPluginContext;
import system.plugins.kinds.Display_LevelObjectPlugin;
import system.plugins.kinds.EditProps_LevelObjectPlugin;
import system.plugins.util.ScriptUtils;
import js.html.Element;
import js.html.OptionElement;
import format.abc.Data.ABCData;
import js.html.SelectElement;
import system.plugins.util.LevelUtils;
import js.jquery.Helper.*;
import js.jquery.JQuery;
import js.Browser;

class Warp_EditProps_Plugin extends EditProps_LevelObjectPlugin {
	var html = "
        <div>
            <h3>Warp</h3>
            <label for='warpToMap'>Warp To Map:</label>
            <select id='warpToMap'></select>
            <br>
            <label for='toWarpId'>To Warp ID:</label>
            <select id='toWarpId'></select>
            <br>
            <label for='warpType'>Warp Type:</label>
            <select id='warpType'>
                <option value='Instant'>Instant</option>
                <option value='Walk'>Walk</option>
            </select>
            <br>
            <div id='walkForm' style='display:none;'>
                <label for='direction'>Direction:</label>
                <select id='direction'>
                    <option value='Up'>Up</option>
                    <option value='Down'>Down</option>
                    <option value='Left'>Left</option>
                    <option value='Right'>Right</option>
                </select>
                <br>
                <label for='amount'>Amount:</label>
                <input type='number' id='amount' min='1'>
            </div>
        </div>
    ";

	public function appliesToObject(context:LevelObjectPluginContext):Bool {
		return context.layerName == "events" && context.rowObject.script != null && context.rowObject.script[0] == 1;
	}

	public function render(context:LevelObjectPluginContext) {
		var form = J(html);
		J(context.propsContainer).append(form);

		var warpToMapElement = cast(context.propsContainer.querySelector("#warpToMap"), SelectElement);
		var toWarpIdElement = cast(context.propsContainer.querySelector("#toWarpId"), SelectElement);
		var warpTypeElement = cast(context.propsContainer.querySelector("#warpType"), SelectElement);
		var walkFormElement = cast(context.propsContainer.querySelector("#walkForm"), Element);
		var directionElement = cast(context.propsContainer.querySelector("#direction"), SelectElement);
		var amountElement = cast(context.propsContainer.querySelector("#amount"), InputElement);

		var maps = context.levelUtils.getLevels();
		for (map in maps) {
			var option = (cast Browser.document.createElement('option'): SelectElement);
			option.value = map.id;
			option.innerText = map.name;
			warpToMapElement.appendChild(option);
		}

		warpToMapElement.addEventListener('change', function(e) {
			toWarpIdElement.innerHTML = ""; // Clear previous options
			var chosenMap = warpToMapElement.value;
			var warps = context.levelUtils.getWarps(chosenMap);
			for (warp in warps) {
				var option = (cast Browser.document.createElement('option'): SelectElement);
				option.value = warp.id;
				option.innerText = warp.name;
				toWarpIdElement.appendChild(option);
			}
		});

		warpTypeElement.addEventListener('change', function(e) {
			if (warpTypeElement.value == 'Walk') {
				walkFormElement.style.display = 'block';
			} else {
				walkFormElement.style.display = 'none';
			}
		});

		var defaultWarpType = "Instant";
		if (context.rowObject.script != null && context.rowObject.script[2] != null && context.rowObject.script[2][0] ==1) {
			defaultWarpType = "Walk";
		}
		warpTypeElement.value = defaultWarpType;

		var defaultDirection = "Up";
		if (context.rowObject.direction != null) {
			defaultDirection = context.rowObject.direction;
		}
		directionElement.value = defaultDirection;

		var defaultAmount = 1;
		if (context.rowObject.amount != null) {
			defaultAmount = context.rowObject.amount;
		}
		amountElement.value = Std.string(defaultAmount);

		J(context.propsContainer).append(EditPropsUtil.createSaveButton(context, this));
		J(context.propsContainer).append(EditPropsUtil.createRenderNormalFormButton(context, this));
	}

	public function writeToSheet(context:LevelObjectPluginContext) {
		var object = context.rowObject;

		var warpToMapElement = cast(context.propsContainer.querySelector("#warpToMap"), SelectElement);
		var toWarpIdElement = cast(context.propsContainer.querySelector("#toWarpId"), SelectElement);
		var warpTypeElement = cast(context.propsContainer.querySelector("#warpType"), SelectElement);
		var directionElement = cast(context.propsContainer.querySelector("#direction"), SelectElement);
		var amountElement = cast(context.propsContainer.querySelector("#amount"), InputElement);

		var map = warpToMapElement.value;
		var toWarpId = toWarpIdElement.value;
		var warpType = warpTypeElement.value;

		var script = [];
		switch (warpType) {
			case "Instant":
				{
					script = context.scriptUtils.serializeScript(Warp(map, Std.parseInt(toWarpId), Instant));
				}
			case "Walk":
				{
					var direction = directionElement.value;
					var amount = Std.parseInt(amountElement.value);
					script = context.scriptUtils.serializeScript(Warp(map, Std.parseInt(toWarpId), Walk(amount,Direction.createByName(direction))));
				}
		}

		object.script = script;
		object.eventType = context.scriptUtils.createWarpEventType(context.level.getName());
	}
}

class Warp_Display_Plugin extends Display_LevelObjectPlugin {
	public function appliesToObject(context:LevelObjectPluginContext):Bool {
		return context.layerName == "events" && context.rowObject.script != null && context.rowObject.script[0] == 1;
	}

	public function execute(context:LevelObjectPluginContext) {
		LevelObjectDisplayUtil.textOverlay(context, "W", 0xFFF00101, true);
	}
}
