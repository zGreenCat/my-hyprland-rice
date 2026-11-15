import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"

const PANEL_NAME = "audiomixer"
const SCRIM_NAME = "audiomixer-scrim"

export default function AudioMixerScrim() {
  return (
    <window
      name={SCRIM_NAME}
      namespace={SCRIM_NAME}
      class="AudioMixerScrim"
      visible={false}
      application={app}
      layer={Astal.Layer.TOP}
      anchor={
        Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT
      }
      $={(self: Gtk.Window) => {
        const panel = app.get_window(PANEL_NAME)
        panel?.connect("notify::visible", () => {
          self.visible = panel.visible
        })
      }}
    >
      <Gtk.GestureClick
        onPressed={() => {
          app.get_window(PANEL_NAME)?.hide()
        }}
      />
      <box hexpand vexpand />
    </window>
  )
}
