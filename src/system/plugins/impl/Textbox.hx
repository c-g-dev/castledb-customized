package system.plugins.impl;

import system.plugins.util.LevelObjectPluginContext;
import system.plugins.kinds.Script_LevelObjectPlugin;
import js.html.SelectElement;
import js.html.Element;
import system.plugins.Plugin.RowObject;
import system.plugins.kinds.Display_LevelObjectPlugin;
import system.plugins.kinds.EditProps_LevelObjectPlugin;
import js.html.Element;
import js.html.TextAreaElement;
import js.jquery.Helper.*;
import js.jquery.JQuery;

class Textbox_EditProps_Plugin extends EditProps_LevelObjectPlugin {
	var html = "
        <div>
            <h3>Textbox</h3>
            <label for='eventType'>Event Type:</label>
            <select id='eventType'>
                <option value='OnInteract'>OnInteract</option>
                <option value='OnWalk'>OnWalk</option>
            </select>
            <br>
            <label for='contentText'>Content:</label>
            <textarea id='contentText'></textarea>
        </div>
    ";


	public function appliesToObject(context:LevelObjectPluginContext):Bool {
		return context.layerName == "events" && context.rowObject.script != null && context.rowObject.script[0] == 2;
	}

	public function render(context:LevelObjectPluginContext) {
		var form = J(html);
		J(context.propsContainer).append(form);

		var eventTypeElement = cast(context.propsContainer.querySelector("#eventType"), SelectElement);
		var contentTextElement = cast(context.propsContainer.querySelector("#contentText"), TextAreaElement);

		var defaultEventType = "OnInteract";
		if (context.rowObject.eventType != null && context.rowObject.eventType.length > 0 && context.rowObject.eventType[0] == 1) {
			defaultEventType = "OnWalk";
		}
		eventTypeElement.value = defaultEventType;

		var defaultContentText = "";
		if (context.rowObject.script != null && context.rowObject.script.length > 1 && context.rowObject.script[0] == 2) {
			defaultContentText = context.rowObject.script[1];
		}
		contentTextElement.value = defaultContentText;

		J(context.propsContainer).append(EditPropsUtil.createSaveButton(context, this));
		J(context.propsContainer).append(EditPropsUtil.createRenderNormalFormButton(context, this));
	}

	public function writeToSheet(context:LevelObjectPluginContext) {
		var eventTypeElement = cast(context.propsContainer.querySelector("#eventType"), SelectElement);
		var contentTextElement = cast(context.propsContainer.querySelector("#contentText"), TextAreaElement);

		switch (eventTypeElement.value) {
			case "OnInteract":
				{
					context.rowObject.eventType = [0];
				}
			case "OnWalk":
				{
					context.rowObject.eventType = [1];
				}
		}

		context.rowObject.script = [2, contentTextElement.value];
	}
}

class Textbox_Display_Plugin extends Display_LevelObjectPlugin {
	public function appliesToObject(context:LevelObjectPluginContext):Bool {
		return context.layerName == "events" && context.rowObject.script != null && context.rowObject.script[0] == 2;
	}

	public function execute(context:LevelObjectPluginContext) {
		trace("executing create textbox script");
		LevelObjectDisplayUtil.textOverlay(context, "T", 0xFFF00101, true);
	}
}

class CreateTextbox_Script_Plugin extends Script_LevelObjectPlugin {
    

    public function appliesToObject(context:LevelObjectPluginContext):Bool {
        return context.layerName == "events" && LevelObjectScriptUtil.isScriptEmpty(context);
    }

    public function getScriptName(context:LevelObjectPluginContext):String {
        return "Create Textbox";
    }

    public function execute(context:LevelObjectPluginContext) {
        context.rowObject.script = [2, ""];
			if(context.rowObject.width == 1){
				context.rowObject.width = 2;
			}
			if(context.rowObject.height == 1){
				context.rowObject.height = 2;
			}
    }
}
