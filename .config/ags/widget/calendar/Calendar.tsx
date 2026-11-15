import GLib from "gi://GLib"
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"

const WINDOW_NAME = "calendar"

function monthLabel(dt: GLib.DateTime) {
  const months = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
  ]
  return `${months[dt.get_month() - 1]} ${dt.get_year()}`
}

export default function Calendar() {
  function close() {
    app.get_window(WINDOW_NAME)?.hide()
  }

  function monthPanel(offset: number) {
    const dt = GLib.DateTime.new_now_local().add_months(offset)!
    return (
      <box orientation={Gtk.Orientation.VERTICAL} class={offset === 0 ? "cal-panel current" : "cal-panel"}>
        <label label={monthLabel(dt)} class="cal-month-label" />
        <Gtk.Calendar
          $={(self: Gtk.Calendar) => {
            self.date = dt
          }}
          showHeading={false}
          class="cal-widget"
        />
      </box>
    )
  }

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      class="CalendarPopup"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={Astal.WindowAnchor.TOP}
      marginTop={40}
    >
      <Gtk.EventControllerKey
        propagationPhase={Gtk.PropagationPhase.CAPTURE}
        onKeyPressed={(_ctrl: unknown, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) {
            close()
            return true
          }
          return false
        }}
      />
      <box orientation={Gtk.Orientation.HORIZONTAL} class="cal-root">
        {monthPanel(-1)}
        {monthPanel(0)}
        {monthPanel(1)}
      </box>
    </window>
  )
}
