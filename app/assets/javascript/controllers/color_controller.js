import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["color"];

  connect() {
    console.log("LECIMY Z KOLORKAMI");
    const styles = getComputedStyle(document.documentElement);
    const brandColor = styles.getPropertyValue("--brand").trim();
    this.colorTarget.value = brandColor;
  }

  changeColor(event) {
    event.preventDefault();
    const newColor = this.colorTarget.value;
    document.documentElement.style.setProperty("--brand", newColor);
  }

  flipToDarkMode() {
    document.documentElement.classList.toggle("dark");
  }
}
