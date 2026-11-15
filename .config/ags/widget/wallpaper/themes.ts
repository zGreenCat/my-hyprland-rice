import GLib from "gi://GLib"
import Gio from "gi://Gio"

const HOME = GLib.getenv("HOME") ?? ""
const THEMES_DIR = `${HOME}/.config/hypr/themes`
const ACTIVE_FILE = `${HOME}/.config/hypr/.active-theme`

export interface ThemeInfo {
  folder: string
  name: string
  wallpaper: string
}

function parseThemeConf(path: string): Record<string, string> {
  const vars: Record<string, string> = {}
  try {
    const [ok, bytes] = GLib.file_get_contents(path)
    if (!ok) return vars
    const text = new TextDecoder().decode(bytes)
    for (const line of text.split("\n")) {
      const match = line.match(/^([A-Z_]+)="(.*)"$/)
      if (match) vars[match[1]] = match[2]
    }
  } catch {
    // ignore unreadable theme.conf
  }
  return vars
}

export function loadThemes(): ThemeInfo[] {
  const result: ThemeInfo[] = []
  const dir = Gio.File.new_for_path(THEMES_DIR)

  let enumerator: Gio.FileEnumerator
  try {
    enumerator = dir.enumerate_children("standard::name,standard::type", Gio.FileQueryInfoFlags.NONE, null)
  } catch {
    return result
  }

  let info: Gio.FileInfo | null
  while ((info = enumerator.next_file(null))) {
    if (info.get_file_type() !== Gio.FileType.DIRECTORY) continue
    const folder = info.get_name()
    const confPath = `${THEMES_DIR}/${folder}/theme.conf`
    if (!GLib.file_test(confPath, GLib.FileTest.EXISTS)) continue

    const vars = parseThemeConf(confPath)
    const wallpaper = (vars.WALLPAPER ?? "").replace("$HOME", HOME)
    if (!wallpaper || !GLib.file_test(wallpaper, GLib.FileTest.EXISTS)) continue

    result.push({ folder, name: vars.THEME_NAME ?? folder, wallpaper })
  }

  result.sort((a, b) => a.name.localeCompare(b.name))
  return result
}

export function getActiveThemeFolder(): string {
  try {
    const [ok, bytes] = GLib.file_get_contents(ACTIVE_FILE)
    return ok ? new TextDecoder().decode(bytes).trim() : ""
  } catch {
    return ""
  }
}
