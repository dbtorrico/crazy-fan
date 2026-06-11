import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "timeoutForm"]
  static values  = { seconds: { type: Number, default: 15 } }

  connect() {
    this.remaining = this.secondsValue
    this.updateDisplay()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    this.stop()
  }

  stop() {
    if (this.interval) {
      clearInterval(this.interval)
      this.interval = null
    }
  }

  tick() {
    this.remaining -= 1
    this.updateDisplay()
    if (this.remaining <= 0) {
      this.stop()
      this.timeoutFormTarget.requestSubmit()
    }
  }

  updateDisplay() {
    this.displayTarget.textContent = this.remaining
  }
}
