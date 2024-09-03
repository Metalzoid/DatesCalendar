import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="apidocs"
export default class extends Controller {
  static values = {
    apikey: String,
  };

  connect() {
    window.setApikey = this.setApikey.bind(this);
  }

  setApikey(event) {
    event.preventDefault();
    const rapidoc = document.querySelector("rapi-doc");
    const apikey = rapidoc.getAttribute("data-valueofapikey");
    event.target.parentElement.parentElement.parentElement.parentElement.parentElement.querySelector(
      "input"
    ).value = apikey;
    rapidoc.setAttribute("api-key-name", "APIKEY");
    rapidoc.setAttribute("api-key-location", "header");
    rapidoc.setAttribute("api-key-value", apikey);
  }
}
