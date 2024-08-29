import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="copy-to-clipboard"
export default class extends Controller {
  static targets = ["button", "input"];

  copyToClipboard() {
    this.inputTarget.select();
    this.inputTarget.setSelectionRange(0, 99999);
    navigator.clipboard.writeText(this.inputTarget.value);
    this.buttonTarget.innerText = "Copied !";
    this.buttonTarget.disabled = true;
  }
}
