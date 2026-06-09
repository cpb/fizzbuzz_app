import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sudsSection"]

  reveal() {
    const section = this.sudsSectionTarget
    if (!section.hasAttribute("hidden")) return
    section.removeAttribute("hidden")
    // Force animation restart
    section.style.animation = "none"
    section.offsetHeight
    section.style.animation = ""
  }
}
