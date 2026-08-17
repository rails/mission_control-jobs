import { Controller } from "@hotwired/stimulus"

const MAX_SAMPLES = 24
const STATUS_COLORS = {
  pending: "#d97706",
  failed: "#dc2626",
  in_progress: "#2563eb",
  blocked: "#9333ea",
  scheduled: "#0891b2",
  finished: "#16a34a"
}

export default class extends Controller {
  static targets = [ "chart", "connection", "connectionLabel", "count", "updatedAt" ]
  static values = {
    initialSnapshot: Object,
    interval: { type: Number, default: 5000 },
    url: String
  }

  connect() {
    this.samples = []
    this.refreshing = false
    this.appendSnapshot(this.initialSnapshotValue)
    this.refreshTimer = window.setInterval(() => this.refresh(), this.intervalValue)
    this.resizeObserver = new ResizeObserver(() => this.drawChart())
    this.resizeObserver.observe(this.chartTarget)
    this.visibilityHandler = () => this.refreshWhenVisible()
    document.addEventListener("visibilitychange", this.visibilityHandler)
  }

  disconnect() {
    window.clearInterval(this.refreshTimer)
    this.resizeObserver?.disconnect()
    document.removeEventListener("visibilitychange", this.visibilityHandler)
  }

  async refresh() {
    if (document.hidden || this.refreshing) return

    this.refreshing = true

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" }
      })

      if (!response.ok) throw new Error(`Dashboard request failed with ${response.status}`)

      this.appendSnapshot(await response.json())
      this.setConnectionState(true)
    } catch (error) {
      this.setConnectionState(false)
      console.error(error)
    } finally {
      this.refreshing = false
    }
  }

  refreshWhenVisible() {
    if (!document.hidden) this.refresh()
  }

  appendSnapshot(snapshot) {
    this.samples.push(snapshot)
    this.samples = this.samples.slice(-MAX_SAMPLES)
    this.updateCounts(snapshot.counts)
    this.updatedAtTarget.textContent = `Updated ${this.formatTime(snapshot.recorded_at)}`
    this.drawChart()
  }

  updateCounts(counts) {
    this.countTargets.forEach((target) => {
      const count = counts[target.dataset.status]
      target.textContent = count.exact ? new Intl.NumberFormat().format(count.value) : "Many"
    })
  }

  setConnectionState(connected) {
    this.connectionTarget.classList.toggle("is-disconnected", !connected)
    this.connectionLabelTarget.textContent = connected ? "Live" : "Reconnecting"
  }

  drawChart() {
    if (!this.samples?.length) return

    const canvas = this.chartTarget
    const width = canvas.clientWidth
    const height = canvas.clientHeight
    const pixelRatio = window.devicePixelRatio || 1

    canvas.width = width * pixelRatio
    canvas.height = height * pixelRatio

    const context = canvas.getContext("2d")
    context.scale(pixelRatio, pixelRatio)

    const padding = { top: 16, right: 18, bottom: 30, left: 46 }
    const plotWidth = width - padding.left - padding.right
    const plotHeight = height - padding.top - padding.bottom
    const statuses = Object.keys(this.samples[0].counts)
    const values = this.samples.flatMap((sample) => statuses.map((status) => sample.counts[status].value || 0))
    const maximum = Math.max(...values, 1)
    const scaleMaximum = this.roundScale(maximum)

    context.clearRect(0, 0, width, height)
    this.drawGrid(context, width, plotWidth, plotHeight, padding, scaleMaximum)

    statuses.forEach((status) => {
      context.beginPath()
      context.strokeStyle = STATUS_COLORS[status] || "#4a4a4a"
      context.lineWidth = 2.5
      context.lineJoin = "round"
      context.lineCap = "round"

      this.samples.forEach((sample, index) => {
        const x = padding.left + (index / Math.max(this.samples.length - 1, 1)) * plotWidth
        const value = sample.counts[status].value || 0
        const y = padding.top + plotHeight - (value / scaleMaximum) * plotHeight

        if (index === 0) context.moveTo(x, y)
        else context.lineTo(x, y)
      })

      context.stroke()
    })
  }

  drawGrid(context, width, plotWidth, plotHeight, padding, scaleMaximum) {
    context.font = "12px system-ui, sans-serif"
    context.fillStyle = "#7a7a7a"
    context.strokeStyle = "#e8eaed"
    context.lineWidth = 1

    for (let step = 0; step <= 4; step++) {
      const y = padding.top + (plotHeight / 4) * step
      const value = Math.round(scaleMaximum * (1 - step / 4))

      context.beginPath()
      context.moveTo(padding.left, y)
      context.lineTo(width - padding.right, y)
      context.stroke()
      context.fillText(new Intl.NumberFormat().format(value), 4, y + 4)
    }

    const firstSample = this.samples[0]
    const lastSample = this.samples[this.samples.length - 1]
    context.fillText(this.formatTime(firstSample.recorded_at), padding.left, padding.top + plotHeight + 22)

    const lastLabel = this.formatTime(lastSample.recorded_at)
    const labelWidth = context.measureText(lastLabel).width
    context.fillText(lastLabel, padding.left + plotWidth - labelWidth, padding.top + plotHeight + 22)
  }

  roundScale(value) {
    const magnitude = 10 ** Math.floor(Math.log10(value))
    return Math.ceil(value / magnitude) * magnitude
  }

  formatTime(timestamp) {
    return new Intl.DateTimeFormat(undefined, {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit"
    }).format(new Date(timestamp))
  }
}
