import GLib from "gi://GLib"
import Pango from "gi://Pango"
import AstalNotifd from "gi://AstalNotifd?version=0.1"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { createState, With } from "gnim"
import { notifd, type Notification } from "./notifd"
import Avatar from "./Avatar"
import { CONTROL_WINDOW, showControlCenter } from "../control/ControlCenter"
import { LIMITS, plainText, truncate } from "../control/parse"

const WINDOW_NAME = "notification-popup"
const VISIBLE_MS = 5000
const URGENT_VISIBLE_MS = 10_000

type Island = { n: Notification; extra: number }

const isUrgent = (n: Notification) => n.urgency === AstalNotifd.Urgency.CRITICAL

export default function NotificationPopup() {
  const [island, setIsland] = createState<Island | null>(null)
  let hideTimer = 0

  function clearTimer() {
    if (hideTimer) GLib.source_remove(hideTimer)
    hideTimer = 0
  }

  function hide() {
    clearTimer()
    setIsland(null)
  }

  const controlOpen = () => app.get_window(CONTROL_WINDOW)?.visible === true

  notifd.connect("notified", (_self: unknown, id: number) => {
    if (notifd.get_dont_disturb() || controlOpen()) return
    const n = notifd.get_notification(id)
    if (!n) return
    const current = island.peek()
    setIsland({ n, extra: current && current.n.id !== id ? current.extra + 1 : 0 })
    clearTimer()
    hideTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, isUrgent(n) ? URGENT_VISIBLE_MS : VISIBLE_MS, () => {
      hideTimer = 0
      setIsland(null)
      return GLib.SOURCE_REMOVE
    })
  })

  notifd.connect("resolved", (_self: unknown, id: number) => {
    if (island.peek()?.n.id === id) hide()
  })
  notifd.connect("notify::dont-disturb", () => {
    if (notifd.get_dont_disturb()) hide()
  })

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      class="NotificationPopup"
      visible={island.as((i) => i !== null)}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.NONE}
      anchor={Astal.WindowAnchor.TOP}
      marginTop={6}
      $={() => {
        app.get_window(CONTROL_WINDOW)?.connect("notify::visible", () => {
          if (controlOpen()) hide()
        })
      }}
    >
      <Gtk.GestureClick
        onPressed={() => {
          hide()
          showControlCenter(false)
        }}
      />
      <box>
        <With value={island}>
          {(i: Island | null) =>
            i ? (
              <box class={isUrgent(i.n) ? "island urgent" : "island"} spacing={12}>
                <Avatar n={i.n} size={30} />
                <label class="island-title" label={truncate(plainText(i.n.summary), LIMITS.islandTitle)} />
                <label
                  class="island-body"
                  label={truncate(plainText(i.n.body), LIMITS.islandBody)}
                  visible={i.n.body.trim() !== ""}
                  ellipsize={Pango.EllipsizeMode.END}
                />
                <label class="island-extra" label={`+${i.extra}`} visible={i.extra > 0} />
              </box>
            ) : (
              <box />
            )
          }
        </With>
      </box>
    </window>
  )
}
