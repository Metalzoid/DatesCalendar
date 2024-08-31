import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="list-updater"
export default class extends Controller {
  static targets = ["select", "list"];

  connect() {
    this.updateLinkToDestroy();
  }

  update() {
    const currentUrl = window.location.pathname;
    this.fetch(currentUrl, this.selectTarget.value);
  }

  fetch(url, id) {
    fetch(`${url}?user_id=${id}`, {
      method: "GET",
      headers: {
        Accept: "text/plain",
      },
    })
      .then((response) => response.text())
      .then((data) => {
        this.listTarget.innerHTML = data;
        this.updateLinkToDestroy();
      });
  }

  updateLinkToDestroy() {
    this.listTarget.querySelectorAll("tr > td > a").forEach((linkto) => {
      if (this.selectTarget.value !== "none") {
        linkto.href += "?listed=true";
      }
    });
  }
}
