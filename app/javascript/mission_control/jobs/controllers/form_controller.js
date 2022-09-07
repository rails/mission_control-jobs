import { Controller } from "@hotwired/stimulus"

function debounce(fn, delay = 10) {
  let timeoutId = null

  return (...args) => {
    const callback = () => fn.apply(this, args)
    clearTimeout(timeoutId)
    timeoutId = setTimeout(callback, delay)
  }
}

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
