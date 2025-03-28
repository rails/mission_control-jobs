import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['discardSelectedButton', 'retrySelectedButton', 'discardAllButton', 'retryAllButton', 'checkbox']

  initialize() {
    this.selectedJobs = []
  }

  toggleJob(event) {
    let checkbox = null
    if (event.target.tagName === 'INPUT') {
      checkbox = event.target
    } else {
      checkbox = this.checkboxTargets.find(checkboxTarget => checkboxTarget.value === event.currentTarget.dataset.jobId)
      checkbox.checked = !checkbox.checked
    }

    if (checkbox.checked) {
      this.selectedJobs.push(checkbox.value)
    } else {
      const index = this.selectedJobs.indexOf(checkbox.value)
      this.selectedJobs.splice(index, 1)
    }

    this.updateButtons()
  }

  updateButtons() {
    if (this.selectedJobs.length > 0) {
      this.discardSelectedButtonTarget.classList.remove('is-hidden')
      this.retrySelectedButtonTarget.classList.remove('is-hidden')
      this.discardAllButtonTarget.classList.add('is-hidden')
      this.retryAllButtonTarget.classList.add('is-hidden')
    } else {
      this.discardSelectedButtonTarget.classList.add('is-hidden')
      this.retrySelectedButtonTarget.classList.add('is-hidden')
      this.discardAllButtonTarget.classList.remove('is-hidden')
      this.retryAllButtonTarget.classList.remove('is-hidden')
    }
  }

}
