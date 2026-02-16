import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["color"];

  connect() {
    const savedColor = localStorage.getItem("brand-color");
    if (savedColor) {
      document.documentElement.style.setProperty("--brand", savedColor);
    }

    const styles = getComputedStyle(document.documentElement);
    const brandColor = styles.getPropertyValue("--brand").trim();
    
    if (this.hasColorTarget) {
      this.colorTarget.value = brandColor;
    }
  }

  changeColor(event) {
    event.preventDefault();
    const newColor = this.colorTarget.value;
    document.documentElement.style.setProperty("--brand", newColor);
    localStorage.setItem("brand-color", newColor);
  }

  flipToDarkMode() {
    document.documentElement.classList.toggle("dark");
  }
}
