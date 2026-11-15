import GLib from "gi://GLib"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { createState, With } from "gnim"
import { notifd, type Notification } from "./notifd"
import { NotificationCard } from "../control/ControlCenter"

const WINDOW_NAME = "notification-popup"
const TOAST_TIMEOUT_MS = 5000
const MAX_TOASTS = 3

export default function NotificationPopup() {
  const [toasts, setToasts] = createState<Notification[]>([])

  function removeToast(id: number) {
    setToasts((list) => list.filter((n) => n.id !== id))
  }

  notifd.connect("notified", (_self: unknown, id: number) => {
    if (notifd.get_dont_disturb()) return
    const n = notifd.get_notification(id)
    if (!n) return
    setToasts((list) => [n, ...list.filter((x) => x.id !== id)].slice(0, MAX_TOASTS))
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, TOAST_TIMEOUT_MS, () => {
      removeToast(id)
      return GLib.SOURCE_REMOVE
    })
  })

  notifd.connect("resolved", (_self: unknown, id: number) => removeToast(id))
  notifd.connect("notify::dont-disturb", () => {
    if (notifd.get_dont_disturb()) setToasts([])
  })

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      class="NotificationPopup"
      visible={toasts.as((t) => t.length > 0)}
      application={app}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.NONE}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
      marginTop={8}
      marginEnd={10}
    >
      <box orientation={Gtk.Orientation.VERTICAL} widthRequest={380}>
        <With value={toasts}>
          {(items: Notification[]) => (
            <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
              {items.map((n) => (
                <box class="toast">
                  <NotificationCard n={n} />
                </box>
              ))}
            </box>
          )}
        </With>
      </box>
    </window>
  )
}
