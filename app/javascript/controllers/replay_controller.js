import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["advanceForm", "replayStep"]

  // Used on the new-session page: just reveal words
  start() {
    this.startWordByWord()
  }

  // Used on the replay show page: reveal words if present, otherwise advance step
  advance() {
    const wbwEl = this.element.querySelector("[data-controller~='word-by-word']")
    if (wbwEl) {
      const wbwController = this.application.getControllerForElementAndIdentifier(wbwEl, "word-by-word")
      if (wbwController && !wbwController.started) {
        wbwController.start()
        return
      }
    }
    if (this.hasAdvanceFormTarget) {
      const step = this.element.querySelector("[data-replay-step]")?.dataset?.replayStep
      if (step && this.hasReplayStepTarget) this.replayStepTarget.value = step
      this.advanceFormTarget.requestSubmit()
    }
  }

  startWordByWord() {
    const wbwEl = this.element.querySelector("[data-controller~='word-by-word']")
    if (!wbwEl) return
    const controller = this.application.getControllerForElementAndIdentifier(wbwEl, "word-by-word")
    if (controller) controller.start()
  }
}
