import { Controller } from "@hotwired/stimulus"

// Auto-avanço da tela de feedback (estado "revelado") para a próxima pergunta.
// Conecta em: data-controller="advance"
// Valores:
//   data-advance-url-value    -> URL (GET) que devolve o próximo fragmento
//   data-advance-delay-value  -> ms de espera (default 1300)
export default class extends Controller {
  static values = { url: String, delay: { type: Number, default: 1300 } }

  connect() {
    this.timer = setTimeout(() => this.go(), this.delayValue)
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  go() {
    const frame = this.element.closest("turbo-frame") || document.getElementById("match")
    if (frame) frame.src = this.urlValue
  }
}
