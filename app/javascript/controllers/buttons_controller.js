import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

// Connects to data-controller="buttons"
export default class extends Controller {
  static targets = ["toggleApikey", "apikey"];

  toggleApikey() {
    const apikeyCollapse = new bootstrap.Collapse("#apiKey", {
      toggle: false,
    });
    if (apikeyCollapse._element.classList.contains("show")) {
      this.toggleApikeyTarget.innerText = "Show your configuration";
      apikeyCollapse.hide();
    } else {
      this.toggleApikeyTarget.innerText = "Hide your configuration";
      apikeyCollapse.show();
    }
  }

  resetApikey(event) {
    event.preventDefault();
    const message = event.target.dataset.turboConfirm;
    if (message) {
      if (confirm(message)) {
        this.fetchApikey(event.target.href);
      } else {
        return null;
      }
    }
  }

  fetchApikey(url) {
    fetch(url, {
      method: "GET",
      headers: {
        Accept: "application/json",
      },
    })
      .then((response) => response.json())
      .then((data) => {
        this.apikeyTarget.value = data.apikey;
      });
  }

  saveIpAddress(event) {
    console.log("coucou");
  }
}
