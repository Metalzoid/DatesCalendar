import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "form", "list"];
  connect() {
    console.log(this.modalTarget);
    console.log(this.formTarget);
    console.log(this.listTarget);
  }
  submit(event) {
    event.preventDefault();
    fetch(this.formTarget.action, {
      method: "POST",
      headers: { Accept: "application/json" },
      body: new FormData(this.formTarget),
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.success) {
          const modal = bootstrap.Modal.getOrCreateInstance(this.modalTarget);
          modal.hide();
          this.listTarget.insertAdjacentHTML("beforeend", data.partial);
        } else {
          this.formTarget.outerHTML = data.partial;
        }
      });
  }
}
