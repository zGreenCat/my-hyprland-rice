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

export function timeAgo(unixSeconds: number, nowMs = Date.now()): string {
  const secs = Math.max(0, Math.floor(nowMs / 1000) - unixSeconds)
  if (secs < 60) return "ahora"
  if (secs < 3600) return `${Math.floor(secs / 60)} min`
  if (secs < 86400) return `${Math.floor(secs / 3600)} h`
  return `${Math.floor(secs / 86400)} d`
}

export const LIMITS = { islandTitle: 32, islandBody: 60, listTitle: 48, listBody: 120 } as const

const ENTITIES: Record<string, string> = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " " }

/** Texto plano a partir del cuerpo de una notificación (algunas apps mandan HTML: enlaces, imágenes, <br>). */
export function plainText(markup: string): string {
  return markup
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<img\b[^>]*>/gi, "")
    .replace(/<[^>]+>/g, "")
    .replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (match, entity: string) => {
      if (entity.startsWith("#")) {
        const hex = entity[1].toLowerCase() === "x"
        const code = Number.parseInt(entity.slice(hex ? 2 : 1), hex ? 16 : 10)
        return Number.isFinite(code) && code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : match
      }
      return ENTITIES[entity.toLowerCase()] ?? match
    })
    .replace(/\s+/g, " ")
    .trim()
}

/** Corta en el último espacio antes del límite (si no queda demasiado corto) y agrega "…"; el resultado nunca pasa de `max`. */
export function truncate(text: string, max: number): string {
  const chars = [...text]
  if (chars.length <= max) return text
  const cut = chars.slice(0, max - 1).join("")
  const space = cut.lastIndexOf(" ")
  const base = space >= Math.floor(max * 0.6) ? cut.slice(0, space) : cut
  return base.replace(/[\s.,;:·\-–—]+$/u, "") + "…"
}

/** "23:52" si es de hoy, "ayer", o "13/11". */
export function timeLabel(unixSeconds: number, now = new Date()): string {
  const date = new Date(unixSeconds * 1000)
  const pad = (n: number) => String(n).padStart(2, "0")
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
  const t = date.getTime()
  if (t >= startOfToday) return `${pad(date.getHours())}:${pad(date.getMinutes())}`
  if (t >= startOfToday - 86_400_000) return "ayer"
  return `${pad(date.getDate())}/${pad(date.getMonth() + 1)}`
}

export const APP_COLOR_COUNT = 8

/** Índice estable de color por nombre de app (FNV-1a), para que cada app tenga siempre el mismo color. */
export function appColorIndex(appName: string): number {
  let hash = 0x811c9dc5
  for (const ch of appName.toLowerCase()) {
    hash ^= ch.codePointAt(0)!
    hash = Math.imul(hash, 0x01000193) >>> 0
  }
  return hash % APP_COLOR_COUNT
}

export function initial(appName: string): string {
  const first = [...appName.trim()][0]
  return first ? first.toLocaleUpperCase("es") : "?"
}
