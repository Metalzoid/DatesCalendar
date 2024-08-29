import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="buttons"
export default class extends Controller {
  static targets = ["apikey"];

  toggleApikey() {
    const apikeyCollapse = new bootstrap.Collapse("#apiKey", {
      toggle: false,
    });
    if (apikeyCollapse._element.classList.contains("show")) {
      this.apikeyTarget.innerText = "Show your API KEY";
      apikeyCollapse.hide();
    } else {
      this.apikeyTarget.innerText = "Hide your API KEY";
      apikeyCollapse.show();
    }
  }
}
