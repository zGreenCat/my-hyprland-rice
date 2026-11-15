import GLib from "gi://GLib"
import { Gtk, Gdk } from "ags/gtk4"
import { appColorIndex, initial } from "../control/parse"
import type { Notification } from "./notifd"

function themedIcon(...names: (string | null | undefined)[]): string | null {
  const display = Gdk.Display.get_default()
  if (!display) return null
  const theme = Gtk.IconTheme.get_for_display(display)
  for (const name of names) {
    if (name && !name.includes("/") && theme.has_icon(name)) return name
  }
  return null
}

function existingFile(path: string | null | undefined): string | null {
  if (!path) return null
  const file = path.startsWith("file://") ? GLib.filename_from_uri(path)[0] : path
  return file.startsWith("/") && GLib.file_test(file, GLib.FileTest.EXISTS) ? file : null
}

/** Ícono real de la app; si no hay, un círculo con la inicial en un color fijo por app. */
export default function Avatar({ n, size }: { n: Notification; size: number }) {
  const app = n.appName || "Notificación"
  const file = existingFile(n.appIcon) ?? existingFile(n.image)
  if (file) return <image class="av" file={file} pixelSize={size} />

  const icon = themedIcon(n.appIcon, n.desktopEntry, app.toLowerCase(), app.toLowerCase().replace(/\s+/g, "-"))
  if (icon) return <image class="av" iconName={icon} pixelSize={size} />

  return (
    <label
      class={`av letter c${appColorIndex(app)}`}
      label={initial(app)}
      widthRequest={size}
      heightRequest={size}
    />
  )
}

export function colorClass(n: Notification) {
  return `c${appColorIndex(n.appName || "Notificación")}`
}
