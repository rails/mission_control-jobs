import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  connect() {
    this.originalText = this.buttonTarget.textContent
  }

  copy() {
    navigator.clipboard
      .writeText(this.sourceTarget.textContent)
      .then(() => this.showMessage("Copied!"), () => this.showMessage("Copy failed!"))
  }

  showMessage(message) {
    clearTimeout(this.timeout)
    this.buttonTarget.textContent = message
    this.timeout = setTimeout(() => {
      this.buttonTarget.textContent = this.originalText
      this.timeout = null
    }, 1000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
