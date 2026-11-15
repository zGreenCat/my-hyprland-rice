import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"

/**
 * Capa transparente a pantalla completa bajo un panel: un clic afuera lo cierra.
 * Reemplaza el cierre por pérdida de foco, que fallaba cuando el panel nunca recibía el foco.
 */
export default function Scrim(panelName: string) {
  return (
    <window
      name={`${panelName}-scrim`}
      namespace={`${panelName}-scrim`}
      class="Scrim"
      visible={false}
      application={app}
      layer={Astal.Layer.TOP}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.NONE}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT}
      $={(self: Gtk.Window) => {
        const panel = app.get_window(panelName)
        if (!panel) {
          console.error(`[scrim] no existe la ventana ${panelName}; créala antes que su scrim`)
          return
        }
        panel.connect("notify::visible", () => {
          self.visible = panel.visible
        })
      }}
    >
      <Gtk.GestureClick onPressed={() => app.get_window(panelName)?.hide()} />
      <box hexpand vexpand />
    </window>
  )
}
