import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "toggleButton", "copyMessage"];

  toggle() {
    if (this.inputTarget.type === "password") {
      this.inputTarget.type = "text";
      this.toggleButtonTarget.textContent = "Hide";
    } else {
      this.inputTarget.type = "password";
      this.toggleButtonTarget.textContent = "Show";
    }
  }

  copy() {
    this.inputTarget.select();
    this.inputTarget.setSelectionRange(0, 99999); // For mobile devices
    
    navigator.clipboard.writeText(this.inputTarget.value).then(() => {
      this.showCopyMessage();
    });
  }

  showCopyMessage() {
    this.copyMessageTarget.classList.remove("d-none");
    setTimeout(() => {
      this.copyMessageTarget.classList.add("d-none");
    }, 2000);
  }
}
