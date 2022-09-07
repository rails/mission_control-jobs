import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers"

export default class extends Controller {
  static values = {
    debounceTimeout: { type: Number, default: 300 }
  }

  initialize() {
    this.debouncedSubmit = debounce(this.debouncedSubmit.bind(this), this.debounceTimeoutValue)
  }

  submit(event) {
    const form = event.target.form || event.target.closest("form")
    if (form) form.requestSubmit()
  }

  debouncedSubmit(event) {
    this.submit(event)
  }
}
