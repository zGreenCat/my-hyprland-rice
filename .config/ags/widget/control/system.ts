import GLib from "gi://GLib"
import { execAsync } from "ags/process"
import {
  PLAYER_FORMAT,
  parseBluetoothPowered,
  parseBrightness,
  parseConnectedDevice,
  parsePlayer,
  parseWifi,
  type PlayerState,
  type WifiState,
} from "./parse"

const HOME = GLib.getenv("HOME") ?? ""
const IDLE_INHIBIT = `${HOME}/.config/hypr/scripts/idle-inhibit.sh`

export interface SystemState {
  wifi: WifiState
  bluetooth: { powered: boolean; device: string | null }
  brightness: number | null
  noLock: boolean
}

async function output(cmd: string[]): Promise<string> {
  try {
    return await execAsync(cmd)
  } catch (err) {
    console.error(`[control] ${cmd.join(" ")} falló:`, err)
    return ""
  }
}

/** Para comandos que salen con error como respuesta normal (playerctl sin reproductores, is-on apagado). */
async function succeeds(cmd: string[]): Promise<{ ok: boolean; out: string }> {
  try {
    return { ok: true, out: await execAsync(cmd) }
  } catch {
    return { ok: false, out: "" }
  }
}

export async function readSystem(): Promise<SystemState> {
  const [general, networks, bt, btDevices, brightness, noLock] = await Promise.all([
    output(["nmcli", "-t", "-f", "WIFI", "general"]),
    output(["nmcli", "-t", "-f", "ACTIVE,SSID", "device", "wifi", "list", "--rescan", "no"]),
    output(["bluetoothctl", "show"]),
    succeeds(["bluetoothctl", "devices", "Connected"]),
    output(["brightnessctl", "-m"]),
    succeeds([IDLE_INHIBIT, "is-on"]),
  ])
  const powered = parseBluetoothPowered(bt)
  return {
    wifi: parseWifi(general, networks),
    bluetooth: { powered, device: powered ? parseConnectedDevice(btDevices.out) : null },
    brightness: parseBrightness(brightness),
    noLock: noLock.ok,
  }
}

export const setWifi = (on: boolean) => output(["nmcli", "radio", "wifi", on ? "on" : "off"])
export const setBluetooth = (on: boolean) => output(["bluetoothctl", "power", on ? "on" : "off"])
export const setBrightness = (percent: number) => output(["brightnessctl", "-q", "set", `${Math.round(percent)}%`])
export const toggleNoLock = () => output([IDLE_INHIBIT, "toggle"])

export async function readPlayer(): Promise<PlayerState | null> {
  const { out } = await succeeds(["playerctl", "metadata", "--format", PLAYER_FORMAT])
  return parsePlayer(out)
}

export const playerAction = (action: "previous" | "play-pause" | "next") => output(["playerctl", action])
