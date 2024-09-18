package system.plugins.impl.menus;

import haxe.Json;
import util.query.SqlEngine;
import js.html.TextAreaElement;
import js.Browser;
import js.node.webkit.MenuItem;
import system.plugins.kinds.TopBarPlugin;
import js.jquery.Helper.*;


/*

	<div id="autosaveconfig" class="modal" style="display:none">
		<div class="content">
			<form id="sheet_form" onsubmit="return false">
				<h1>Autosave Configuration</h1>
				<p>
					<span>Enabled</span>
					<input type="checkbox" class="value" id="enabled"/>
				</p>
				<p>
					<span>Folder</span>
					<input type="text" class="value" id="folder"/>
				</p>
				<p>
					<span>Interval (seconds)</span>
					<input type="number" class="value" id="interval"/>
				</p>
				<p>
					<span>Max Backups</span>
					<input type="number" class="value" id="max_backups"/>
				</p>
				<p class="buttons">
					<input type="submit" value="Save" onclick="_.configureAutosaving(
						$('#enabled').is(':checked'), 
						$('#folder').val(), 
						$('#interval').val(), 
						$('#max_backups').val()
					)"/>
					<input type="submit" value="Cancel" onclick="$(this).parents('.modal').hide()"/>
				</p>
			</form>
		</div>
	</div>


*/

class SQLQueryMenu extends TopBarPlugin {
    
    var runQueryPopupHTML: String = '
        <div id="run-query-popup" class="modal" style="display:none">
            <div class="content">
                <form id="query_form" onsubmit="return false">
                    <h1>Run Query</h1>
                    <p>
                        <span>Query</span>
                        <textarea id="query_input"></textarea>
                    </p>
                    <p>
                        <span>Result</span>
                        <textarea id="result_area" readonly></textarea>
                    </p>
                    <p class="buttons">
                        <input type="submit" id="run_query_button" value="Run Query"/>
                        <input type="submit" value="Close" onclick="$(this).parents(\'.modal\').hide()"/>
                    </p>
                </form>
            </div>
        </div>';

    var model: Model;

    public function new(model: Model) {
        // Inject the popup HTML into the document body
        this.model = model;
        J("#helpers").append(J(runQueryPopupHTML));
        J("#run_query_button").click((e) -> {
            runQuery();
        });
    }

    public function getMenu():TopBarPluginMenuInjection {
        var mi = new MenuItem({label: "Run Query"});
        mi.click = () -> {
            J("#run-query-popup").show();
        };
        
        return TopBarPluginMenuInjection.AddToMenu("Database", mi);
    }

    private function runQuery():Void {
        var query:String = (cast J("#query_input").get(0): TextAreaElement).value;
        // Simulate running the query and returning a result
        var q = new SqlEngine(model.base);
        var result = q.run(query);
        (cast J("#result_area").get(0): TextAreaElement).value = Json.stringify(result);
    }
}