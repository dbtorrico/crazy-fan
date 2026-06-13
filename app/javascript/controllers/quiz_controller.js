import { Controller } from "@hotwired/stimulus"

const CIRCUMFERENCE = 2 * Math.PI * 34  // r=34 matches SVG

export default class extends Controller {
  static targets = ["ringProgress", "num", "option", "answerInput", "form"]
  static values  = { totalTime: { type: Number, default: 15 } }

  connect() {
    this.remaining = this.totalTimeValue
    this.answered  = false
    this.ringProgressTarget.style.strokeDasharray  = CIRCUMFERENCE
    this.ringProgressTarget.style.strokeDashoffset = 0
    this.updateRing()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  tick() {
    if (this.answered) return
    this.remaining -= 1
    this.updateRing()
    if (this.remaining <= 0) {
      clearInterval(this.interval)
      this.formTarget.requestSubmit()
    }
  }

  select(event) {
    if (this.answered) return
    this.answered = true
    clearInterval(this.interval)

    const btn       = event.currentTarget
    const answerId  = btn.dataset.answerId
    const isCorrect = btn.dataset.correct === "true"

    this.answerInputTarget.value = answerId
    this.optionTargets.forEach(opt => { opt.disabled = true })
    btn.classList.add("opt-chosen")

    setTimeout(() => {
      this.optionTargets.forEach(opt => {
        const correct = opt.dataset.correct === "true"
        if (correct) {
          opt.classList.remove("opt-chosen")
          opt.classList.add("opt-correct")
          opt.querySelector(".res").textContent = "✓"
        } else if (opt === btn && !isCorrect) {
          opt.classList.remove("opt-chosen")
          opt.classList.add("opt-wrong")
          opt.querySelector(".res").textContent = "✕"
        } else {
          opt.classList.add("opt-dim")
        }
      })
    }, 120)

    setTimeout(() => this.formTarget.requestSubmit(), 1300)
  }

  updateRing() {
    const frac   = Math.max(0, this.remaining) / this.totalTimeValue
    const offset = CIRCUMFERENCE * (1 - frac)
    const isLow  = this.remaining <= 5

    this.ringProgressTarget.style.strokeDashoffset = offset
    this.ringProgressTarget.style.stroke           = isLow ? "#e23636" : "#009C3B"
    this.numTarget.textContent = Math.max(0, this.remaining)
    this.numTarget.style.color = isLow ? "#e23636" : "#002776"
  }
}
