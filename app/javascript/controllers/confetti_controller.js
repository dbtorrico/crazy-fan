import { Controller } from "@hotwired/stimulus"

const COLORS = ["#FFDF00", "#009C3B", "#002776", "#ffffff", "#ff5d8f", "#3ec6ff"]

export default class extends Controller {
  connect() {
    for (let i = 0; i < 46; i++) {
      const w  = 6 + Math.random() * 6
      const el = document.createElement("span")
      el.className = "confetti-piece"
      el.style.cssText = [
        `left: ${Math.random() * 100}%`,
        `width: ${w}px`,
        `height: ${w * 1.5}px`,
        `background: ${COLORS[i % COLORS.length]}`,
        `animation-duration: ${2.6 + Math.random() * 2.4}s`,
        `animation-delay: ${-Math.random() * 4}s`,
        `transform: rotate(${Math.random() * 360}deg)`
      ].join(";")
      this.element.appendChild(el)
    }
  }
}
