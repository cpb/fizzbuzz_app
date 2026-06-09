import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    if (event.target.closest('input[type="radio"]')) return
    this.element.querySelector('input[type="radio"]').click()
  }
}
