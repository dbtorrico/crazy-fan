import { Controller } from "@hotwired/stimulus"

// Cronômetro client-side da pergunta.
// Conecta em: data-controller="countdown"
//
// Valores:
//   data-countdown-duration-value  -> segundos totais da pergunta (ex.: 15)
//   data-countdown-deadline-value  -> (opcional) epoch em ms do fim, vindo do
//                                     servidor. Se presente, é a fonte da verdade
//                                     (resiste a refresh / relógio do cliente).
//
// Targets:
//   number  -> <div> que mostra os segundos
//   ring    -> <circle> do anel de progresso (stroke-dashoffset animado)
//   form    -> <form> de resposta; é submetido automaticamente ao zerar
//   timeout -> <input hidden> setado para "1" quando o tempo acaba
export default class extends Controller {
  static values = { duration: Number, deadline: Number }
  static targets = ["number", "ring", "form", "timeout"]

  connect() {
    this.radius = 34
    this.circumference = 2 * Math.PI * this.radius
    if (this.hasRingTarget) {
      this.ringTarget.style.strokeDasharray = this.circumference
    }
    this.endAt = this.hasDeadlineValue && this.deadlineValue > 0
      ? this.deadlineValue
      : Date.now() + this.durationValue * 1000

    this.tick()
    this.interval = setInterval(() => this.tick(), 250)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  tick() {
    const msLeft  = Math.max(0, this.endAt - Date.now())
    const secLeft = Math.ceil(msLeft / 1000)
    const frac    = Math.max(0, Math.min(1, msLeft / (this.durationValue * 1000)))

    if (this.hasNumberTarget) this.numberTarget.textContent = secLeft
    if (this.hasRingTarget)   this.ringTarget.style.strokeDashoffset = this.circumference * (1 - frac)

    this.element.classList.toggle("is-low", secLeft <= 5)

    if (msLeft <= 0) {
      clearInterval(this.interval)
      this.expire()
    }
  }

  expire() {
    if (this.expired) return
    this.expired = true
    if (this.hasTimeoutTarget) this.timeoutTarget.value = "1"
    this.dispatch("expired")
    if (this.hasFormTarget) this.formTarget.requestSubmit()
  }
}
