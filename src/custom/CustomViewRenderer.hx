package custom;

import custom.CustomView.CustomViewLifecycle;
import js.jquery.Helper.*;

class CustomViewRenderer {

    var currentView: CustomView;
    var cv: Dynamic;
    var cvh: Dynamic;
    var ctc: Dynamic;
    var model: Model;

    public function new(model: Model) {
        this.cv = J("#custom-view-container");
        this.cvh = J("#custom-view-header");
        this.ctc = J("#custom-view-content");
        this.model = model;

        this.cvh.css({
            backgroundColor: "#EEE",
            minHeight: "60px"
        });

        this.cvh.find(".options input[type='submit']").on("click", (e) -> {
            this.close();
        });

        this.ctc.css({
            padding: "15px",
            backgroundColor: "#666",
            overflow: "scroll"
        });
    }

    public function render(customView: CustomView) {
        if (this.currentView != null) {
            this.close();
        }
        this.currentView = customView;
        var element = customView.renderElement(this.ctc);
        customView.setTopBar(this.cvh);
        customView.on(CustomViewLifecycle.Start);
        this.cv.css("display", "block");
        J("#content").css("display", "none");
    }

    public function close() {
        if (this.currentView != null) {
            this.currentView.unrenderElement(() -> {
                this.ctc.empty();
                var optionsDiv = this.cvh.find(".options").detach();
                this.cvh.empty().append(optionsDiv);
                this.currentView.on(CustomViewLifecycle.Close);
                this.currentView.saveToDB();
                this.model.save();
                this.currentView = null;
                this.cv.css("display", "none");
                J("#content").css("display", "block");
                cast(this.model, Main).initContent();
            });
        }
        else{
            this.cv.css("display", "none");
            J("#content").css("display", "block");
            cast(this.model, Main).initContent();
        }
    }
}