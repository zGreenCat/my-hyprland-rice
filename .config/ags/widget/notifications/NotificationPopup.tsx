import GLib from "gi://GLib"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { createState, With } from "gnim"
import { notifd, type Notification } from "./notifd"

const WINDOW_NAME = "notification-popup"
const TOAST_TIMEOUT_MS = 5000

export default function NotificationPopup() {
  const [toasts, setToasts] = createState<Notification[]>([])

  function removeToast(id: number) {
    setToasts((list) => list.filter((n) => n.id !== id))
  }

  notifd.connect("notified", (_self: unknown, id: number) => {
    const n = notifd.get_notification(id)
    if (!n) return
    setToasts((list) => [...list.filter((x) => x.id !== id), n])
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, TOAST_TIMEOUT_MS, () => {
      removeToast(id)
      return GLib.SOURCE_REMOVE
    })
  })

  notifd.connect("resolved", (_self: unknown, id: number) => removeToast(id))

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
      marginTop={40}
      marginEnd={16}
    >
      <box orientation={Gtk.Orientation.VERTICAL} widthRequest={340}>
        <With value={toasts}>
          {(items) => (
            <box orientation={Gtk.Orientation.VERTICAL}>
              {items.map((n) => (
                <box class="toast-item">
                  <image iconName={n.appIcon || "dialog-information-symbolic"} pixelSize={28} />
                  <box orientation={Gtk.Orientation.VERTICAL} hexpand>
                    <label label={n.appName || "Notificación"} class="toast-app" halign={Gtk.Align.START} />
                    <label label={n.summary} class="toast-summary" halign={Gtk.Align.START} wrap />
                    {n.body ? <label label={n.body} class="toast-body" halign={Gtk.Align.START} wrap /> : ""}
                  </box>
                </box>
              ))}
            </box>
          )}
        </With>
      </box>
    </window>
  )
}
