import * as bootstrap from "bootstrap";
import { Application } from "@hotwired/stimulus";
import "@hotwired/turbo";
import TC from "@rolemodel/turbo-confirm";

import ColorController from "./controllers/color_controller";
import ProfileController from "./controllers/profile_controller";
import FormRedirectController from "./controllers/form_redirect_controller";

// Shared JavaScript for all widgets
window.Stimulus = Application.start();
Stimulus.register("color", ColorController);
Stimulus.register("profile", ProfileController);
Stimulus.register("form-redirect", FormRedirectController);

document.addEventListener("turbo:load", () => {
  console.log("EOSC Widgets: app loaded");
});

TC.start({
  activeClass: "d-flex",
  contentSlots: {
    body: {
      contentAttribute: "confirm-details",
      slotSelector: "#confirm-body",
    },
    acceptText: {
      contentAttribute: "confirm-button",
      slotSelector: "#confirm-accept",
    },
    rejectText: {
      contentAttribute: "confirm-cancel",
      slotSelector: "#dismiss-btn",
    },
  },
});