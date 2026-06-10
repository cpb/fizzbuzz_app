import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["word"]

  connect() {
    this.wordTargets.forEach(w => { w.style.visibility = "hidden" })
    this.index = 0
    this.started = false
  }

  start() {
    if (this.started) return
    this.started = true
    this.reveal()
  }

  reveal() {
    if (this.index < this.wordTargets.length) {
      this.wordTargets[this.index].style.visibility = "visible"
      this.index++
      setTimeout(() => this.reveal(), 150)
    }
  }
}
