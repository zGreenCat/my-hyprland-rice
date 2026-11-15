export interface WifiState {
  enabled: boolean
  ssid: string | null
}

export interface PlayerState {
  status: "Playing" | "Paused" | "Stopped"
  title: string
  artist: string
  player: string
}

/** `nmcli -t -f WIFI general` y `nmcli -t -f ACTIVE,SSID device wifi list --rescan no` */
export function parseWifi(general: string, networks: string): WifiState {
  const enabled = general.trim() === "enabled"
  const active = networks.split("\n").find((line) => line.startsWith("yes:"))
  const ssid = active ? active.slice(4).replace(/\\:/g, ":").trim() : ""
  return { enabled, ssid: enabled && ssid ? ssid : null }
}

/** `brightnessctl -m` → "intel_backlight,backlight,12000,50%,24000" */
export function parseBrightness(output: string): number | null {
  const match = output.match(/,(\d+)%,/)
  return match ? Number.parseInt(match[1], 10) : null
}

/** `bluetoothctl show` */
export function parseBluetoothPowered(output: string): boolean {
  return /^\s*Powered:\s*yes\s*$/m.test(output)
}

/** `bluetoothctl devices Connected` → "Device AA:BB:… Nombre" por línea */
export function parseConnectedDevice(output: string): string | null {
  const line = output.split("\n").find((l) => l.startsWith("Device "))
  if (!line) return null
  const name = line.split(" ").slice(2).join(" ").trim()
  return name || null
}

export const PLAYER_FORMAT = "{{status}}\t{{title}}\t{{artist}}\t{{playerName}}"

/** `playerctl metadata --format PLAYER_FORMAT` */
export function parsePlayer(output: string): PlayerState | null {
  const line = output.split("\n").find((l) => l.trim())
  if (!line) return null
  const [status, title = "", artist = "", player = ""] = line.split("\t")
  if (status !== "Playing" && status !== "Paused") return null
  if (!title.trim()) return null
  return { status, title: title.trim(), artist: artist.trim(), player: player.trim() }
}

export interface Grouped<T> {
  app: string
  items: T[]
}

/** Agrupa por app manteniendo el orden de la primera aparición (la lista llega de más nueva a más vieja). */
export function groupByApp<T extends { appName: string }>(items: T[], fallback = "Notificación"): Grouped<T>[] {
  const groups = new Map<string, T[]>()
  for (const item of items) {
    const app = item.appName || fallback
    const list = groups.get(app)
    if (list) list.push(item)
    else groups.set(app, [item])
  }
  return [...groups].map(([app, list]) => ({ app, items: list }))
}

export function timeAgo(unixSeconds: number, nowMs = Date.now()): string {
  const secs = Math.max(0, Math.floor(nowMs / 1000) - unixSeconds)
  if (secs < 60) return "ahora"
  if (secs < 3600) return `${Math.floor(secs / 60)} min`
  if (secs < 86400) return `${Math.floor(secs / 3600)} h`
  return `${Math.floor(secs / 86400)} d`
}
