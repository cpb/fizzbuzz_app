import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  addRow(event) {
    const rows = this.containerTarget.querySelectorAll("tr")
    const lastRow = rows[rows.length - 1]
    
    // If the event target is within the last row, add a new one
    if (lastRow.contains(event.target)) {
      const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
      this.containerTarget.insertAdjacentHTML('beforeend', content)
    }
  }
}
