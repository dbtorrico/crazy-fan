import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String, url: String }
  static targets = ["feedback"]

  async share() {
    const text = this.textValue
    const url  = this.urlValue || window.location.href

    if (navigator.share) {
      try {
        await navigator.share({ text, url })
      } catch (_e) {
        // user cancelled — no feedback needed
      }
    } else {
      try {
        await navigator.clipboard.writeText(`${text} ${url}`)
        this.showFeedback("Link copiado!")
      } catch (_e) {
        this.showFeedback("Copie o link manualmente")
      }
    }
  }

  showFeedback(message) {
    if (!this.hasFeedbackTarget) return
    this.feedbackTarget.textContent = message
    this.feedbackTarget.classList.remove("hidden")
    setTimeout(() => this.feedbackTarget.classList.add("hidden"), 2500)
  }
}
