import GLib from "gi://GLib"
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState, With } from "gnim"
import { notifd, type Notification } from "./notifd"

const WINDOW_NAME = "notification-center"
const REFRESH_INTERVAL_MS = 10_000

type SystemState = {
  volume: number
  muted: boolean
  brightness: number
  battery: number | null
  charging: boolean
  wifiEnabled: boolean
  wifiName: string
  bluetoothEnabled: boolean
}

const defaultSystemState: SystemState = {
  volume: 0,
  muted: false,
  brightness: 50,
  battery: null,
  charging: false,
  wifiEnabled: false,
  wifiName: "Desconectado",
  bluetoothEnabled: false,
}

function timeAgo(n: Notification) {
  const secs = Math.max(0, Math.floor(Date.now() / 1000) - n.time)
  if (secs < 60) return "ahora"
  if (secs < 3600) return `${Math.floor(secs / 60)}m`
  if (secs < 86400) return `${Math.floor(secs / 3600)}h`
  return `${Math.floor(secs / 86400)}d`
}

export default function NotificationCenter() {
  const [list, setList] = createState<Notification[]>(notifd.get_notifications())
  const [system, setSystem] = createState<SystemState>(defaultSystemState)

  async function output(command: string) {
    try {
      return await execAsync(command)
    } catch (err) {
      console.error(err)
      return ""
    }
  }

  async function refreshSystem() {
    const [volume, muted, brightness, battery, batteryStatus, wifi, wifiNetworks, bluetooth] = await Promise.all([
      output("pamixer --get-volume"),
      output("pamixer --get-mute"),
      output("brightnessctl -m"),
      output("cat /sys/class/power_supply/BAT0/capacity"),
      output("cat /sys/class/power_supply/BAT0/status"),
      output("nmcli -t -f WIFI general"),
      output("nmcli -t -f ACTIVE,SSID device wifi"),
      output("bluetoothctl show"),
    ])
    const brightnessMatch = brightness.match(/,(\d+)%/)
    const connectedWifi = wifiNetworks.split("\n").find((line) => line.startsWith("yes:"))

    setSystem({
      volume: Number.parseInt(volume, 10) || 0,
      muted: muted.trim() === "true",
      brightness: brightnessMatch ? Number.parseInt(brightnessMatch[1], 10) : 50,
      battery: /^\d+$/.test(battery.trim()) ? Number.parseInt(battery, 10) : null,
      charging: batteryStatus.trim() === "Charging",
      wifiEnabled: wifi.trim() === "enabled",
      wifiName: connectedWifi?.slice(4) || "Desconectado",
      bluetoothEnabled: bluetooth.includes("Powered: yes"),
    })
  }

  function refresh() {
    setList(notifd.get_notifications().slice().reverse())
  }

  notifd.connect("notified", () => refresh())
  notifd.connect("resolved", () => refresh())
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, REFRESH_INTERVAL_MS, () => {
    if (app.get_window(WINDOW_NAME)?.visible) refreshSystem()
    return GLib.SOURCE_CONTINUE
  })

  function close() {
    app.get_window(WINDOW_NAME)?.hide()
  }

  function clearAll() {
    for (const n of notifd.get_notifications()) n.dismiss()
  }

  function setVolume(value: number) {
    const volume = Math.round(value)
    setSystem((state) => ({ ...state, volume, muted: false }))
    execAsync(["pamixer", "--set-volume", String(volume)]).then(refreshSystem).catch(console.error)
  }

  function setBrightness(value: number) {
    const brightness = Math.round(value)
    setSystem((state) => ({ ...state, brightness }))
    execAsync(["brightnessctl", "set", `${brightness}%`]).then(refreshSystem).catch(console.error)
  }

  function toggleMute() {
    execAsync(["pamixer", "--toggle-mute"]).then(refreshSystem).catch(console.error)
  }

  function toggleWifi() {
    const enabled = !system.peek().wifiEnabled
    execAsync(["nmcli", "radio", "wifi", enabled ? "on" : "off"]).then(refreshSystem).catch(console.error)
  }

  function toggleBluetooth() {
    const enabled = !system.peek().bluetoothEnabled
    execAsync(["bluetoothctl", "power", enabled ? "on" : "off"]).then(refreshSystem).catch(console.error)
  }

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      class="NotificationCenter"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
      marginTop={40}
      marginEnd={16}
      onNotifyVisible={(self: Gtk.Window) => {
        if (self.visible) refreshSystem()
      }}
    >
      <Gtk.EventControllerKey
        propagationPhase={Gtk.PropagationPhase.CAPTURE}
        onKeyPressed={(_ctrl: unknown, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) {
            close()
            return true
          }
          return false
        }}
      />
      <Gtk.EventControllerFocus onLeave={close} />
      <box orientation={Gtk.Orientation.VERTICAL} class="notif-root" widthRequest={360}>
        <box class="notif-header">
          <label label="Notificaciones" class="notif-title" hexpand halign={Gtk.Align.START} />
          <button class="notif-clear" onClicked={clearAll}>
            <label label="Limpiar todo" />
          </button>
        </box>
        <With value={system}>
          {(status) => (
            <box orientation={Gtk.Orientation.VERTICAL} class="quick-root">
              <box class="quick-toggles">
                <button
                  class={status.wifiEnabled ? "quick-toggle active" : "quick-toggle"}
                  onClicked={toggleWifi}
                  hexpand
                >
                  <box orientation={Gtk.Orientation.VERTICAL}>
                    <label class="quick-toggle-icon" label="󰤨" />
                    <label class="quick-toggle-label" label={status.wifiEnabled ? status.wifiName : "Wi-Fi"} />
                  </box>
                </button>
                <button
                  class={status.bluetoothEnabled ? "quick-toggle active" : "quick-toggle"}
                  onClicked={toggleBluetooth}
                  hexpand
                >
                  <box orientation={Gtk.Orientation.VERTICAL}>
                    <label class="quick-toggle-icon" label="󰂯" />
                    <label class="quick-toggle-label" label="Bluetooth" />
                  </box>
                </button>
                {status.battery !== null ? (
                  <box orientation={Gtk.Orientation.VERTICAL} class="quick-battery" hexpand>
                    <label class="quick-toggle-icon" label={status.charging ? "󰂄" : "󰁹"} />
                    <label class="quick-toggle-label" label={`${status.battery}%`} />
                  </box>
                ) : ""}
              </box>
              <box class="quick-slider-row">
                <button class="quick-icon-button" onClicked={toggleMute}>
                  <label label={status.muted ? "󰖁" : "󰕾"} />
                </button>
                <Gtk.Scale
                  orientation={Gtk.Orientation.HORIZONTAL}
                  drawValue={false}
                  hexpand
                  $={(self: Gtk.Scale) => {
                    self.set_range(0, 100)
                    self.set_increments(1, 10)
                    self.set_value(status.volume)
                    self.connect("value-changed", () => setVolume(self.get_value()))
                  }}
                />
                <label class="quick-value" label={`${status.volume}%`} />
              </box>
              <box class="quick-slider-row">
                <label class="quick-slider-icon" label="󰃟" />
                <Gtk.Scale
                  orientation={Gtk.Orientation.HORIZONTAL}
                  drawValue={false}
                  hexpand
                  $={(self: Gtk.Scale) => {
                    self.set_range(0, 100)
                    self.set_increments(1, 10)
                    self.set_value(status.brightness)
                    self.connect("value-changed", () => setBrightness(self.get_value()))
                  }}
                />
                <label class="quick-value" label={`${status.brightness}%`} />
              </box>
            </box>
          )}
        </With>
        <With value={list}>
          {(items) =>
            items.length === 0 ? (
              <label label="Sin notificaciones" class="notif-empty" />
            ) : (
              <box orientation={Gtk.Orientation.VERTICAL} class="notif-list">
                {items.map((n) => (
                  <box class="notif-item">
                    <image iconName={n.appIcon || "dialog-information-symbolic"} pixelSize={28} />
                    <box orientation={Gtk.Orientation.VERTICAL} hexpand>
                      <box>
                        <label label={n.appName || "Notificación"} class="notif-app" hexpand halign={Gtk.Align.START} />
                        <label label={timeAgo(n)} class="notif-time" />
                      </box>
                      <label label={n.summary} class="notif-summary" halign={Gtk.Align.START} wrap />
                      {n.body ? <label label={n.body} class="notif-body" halign={Gtk.Align.START} wrap /> : ""}
                    </box>
                    <button class="notif-dismiss" onClicked={() => n.dismiss()}>
                      <image iconName="window-close-symbolic" pixelSize={14} />
                    </button>
                  </box>
                ))}
              </box>
            )
          }
        </With>
      </box>
    </window>
  )
}
