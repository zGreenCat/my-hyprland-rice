import GLib from "gi://GLib"
import { execAsync } from "ags/process"
import type { Entry, Filter } from "./search"

const HOME = GLib.getenv("HOME") ?? ""
const SCRIPTS = `${HOME}/.config/hypr/scripts`

function exec(cmd: string[]) {
  execAsync(cmd).catch((err) => console.error(err))
}

export interface Action extends Entry {
  kind: "action"
  category: Exclude<Filter, "Todo" | "Apps">
  icon: string
  run: () => void
}

export const FILTER_ICONS: Record<Filter, string> = {
  Todo: "view-grid-symbolic",
  Apps: "view-app-grid-symbolic",
  Estilo: "applications-graphics-symbolic",
  Aprender: "help-browser-symbolic",
  Sistema: "preferences-system-symbolic",
  Instalar: "system-software-install-symbolic",
}

function action(category: Action["category"], icon: string, title: string, subtitle: string, run: () => void): Action {
  return { kind: "action", category, icon, title, subtitle, run }
}

export const actions: Action[] = [
  action("Estilo", "document-new-symbolic", "Nuevo tema", "Abre el creador de temas", () =>
    exec(["python3", `${SCRIPTS}/theme-creator.py`])),
  action("Estilo", "edit-delete-symbolic", "Eliminar tema", "Elige un tema y lo borra", () =>
    exec([`${SCRIPTS}/delete-theme.sh`])),

  action("Aprender", "input-keyboard-symbolic", "Atajos de teclado", "Lista de keybindings", () =>
    exec([
      "bash",
      "-c",
      `python3 ${SCRIPTS}/keybindings-view.py | rofi -dmenu -p "󰌌  Keybindings" -theme-str 'window {width: 780px;} listview {lines: 16; fixed-height: true;}' > /dev/null 2>&1`,
    ])),
  action("Aprender", "help-browser-symbolic", "Hyprland Wiki", "wiki.hyprland.org", () =>
    exec(["xdg-open", "https://wiki.hyprland.org"])),
  action("Aprender", "help-browser-symbolic", "Arch Wiki", "wiki.archlinux.org", () =>
    exec(["xdg-open", "https://wiki.archlinux.org"])),
  action("Aprender", "help-browser-symbolic", "Neovim Docs", "neovim.io/doc", () =>
    exec(["xdg-open", "https://neovim.io/doc/"])),

  action("Sistema", "bluetooth-symbolic", "Bluetooth", "blueman-manager", () => exec(["blueman-manager"])),
  action("Sistema", "multimedia-volume-control-symbolic", "Mezclador", "pavucontrol", () => exec(["pavucontrol"])),
  action("Sistema", "audio-speakers-symbolic", "Enviar audio al PC", "audio-al-pc.sh", () =>
    exec([`${SCRIPTS}/audio-al-pc.sh`, "menu"])),
  action("Sistema", "network-wireless-symbolic", "Red", "nm-connection-editor", () => exec(["nm-connection-editor"])),
  action("Sistema", "view-refresh-symbolic", "Reiniciar Waybar", "wbrestart.sh", () => exec([`${SCRIPTS}/wbrestart.sh`])),
  action("Sistema", "system-shutdown-symbolic", "Menú de apagado", "wlogout", () => exec(["wlogout"])),

  action("Instalar", "system-software-install-symbolic", "Instalar paquete", "pkgsearch.sh en kitty", () =>
    exec(["kitty", "bash", "-c", `${SCRIPTS}/pkgsearch.sh`])),
  action("Instalar", "software-update-available-symbolic", "Actualizar sistema", "yay -Syu en kitty", () =>
    exec(["kitty", "bash", "-c", "yay -Syu; read"])),
  action("Instalar", "edit-delete-symbolic", "Remover paquete", "yay -R en kitty", () =>
    exec(["kitty", "bash", "-c", "yay -R \\$(yay -Qq | rofi -dmenu -p 'Remover paquete'); read"])),
]
