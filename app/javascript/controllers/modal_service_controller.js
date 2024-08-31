import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "form", "list"];

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
          this.formTarget.outerHTML = data.form;
        } else {
          this.formTarget.outerHTML = data.partial;
          const alert = document.getElementById("alert-modal");
          alert.innerText = data.error;
          alert.classList.add("show");
          setTimeout(() => {
            alert.classList.remove("show");
          }, 5000);
        }
      });
  }
}
