import * as bootstrap from "bootstrap";
import { Application } from "@hotwired/stimulus";
import "@hotwired/turbo";
import "@rolemodel/turbo-confirm";

import ColorController from "./controllers/color_controller";

// Shared JavaScript for all widgets
window.Stimulus = Application.start();
Stimulus.register("color", ColorController);

document.addEventListener("turbo:load", () => {
  console.log("EOSC Widgets: app loaded");
});
