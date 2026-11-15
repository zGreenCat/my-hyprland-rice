import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState, With } from "gnim"
import { WEEKDAYS, monthGrid, monthTitle, shiftMonth, type YearMonth } from "./month"

const WINDOW_NAME = "calendar"

function currentMonth(): YearMonth {
  const now = new Date()
  return { year: now.getFullYear(), month: now.getMonth() }
}

function longDate(date: Date) {
  return new Intl.DateTimeFormat("es-CL", { weekday: "long", day: "numeric", month: "long" }).format(date)
}

export default function Calendar() {
  const [shown, setShown] = createState<YearMonth>(currentMonth())

  function close() {
    app.get_window(WINDOW_NAME)?.hide()
  }

  function step(delta: number) {
    setShown((m) => shiftMonth(m, delta))
  }

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      class="CalendarPopup"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={Astal.WindowAnchor.TOP}
      marginTop={8}
      onNotifyVisible={(self: Gtk.Window) => {
        if (self.visible) setShown(currentMonth())
      }}
    >
      <Gtk.EventControllerKey
        propagationPhase={Gtk.PropagationPhase.CAPTURE}
        onKeyPressed={(_c: unknown, keyval: number) => {
          switch (keyval) {
            case Gdk.KEY_Escape:
              close()
              return true
            case Gdk.KEY_Left:
              step(-1)
              return true
            case Gdk.KEY_Right:
              step(1)
              return true
            case Gdk.KEY_Home:
              setShown(currentMonth())
              return true
          }
          return false
        }}
      />
      <box orientation={Gtk.Orientation.VERTICAL} class="cal-root" widthRequest={320} spacing={12}>
        <With value={shown}>
          {(m: YearMonth) => {
            const today = new Date()
            const cells = monthGrid(m, today)
            const isCurrent = m.year === today.getFullYear() && m.month === today.getMonth()
            return (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={10}>
                <box orientation={Gtk.Orientation.VERTICAL}>
                  <label class="cal-today" label={longDate(today)} xalign={0} />
                </box>
                <box spacing={4}>
                  <label class="cal-title" label={monthTitle(m)} xalign={0} hexpand />
                  <button class="cal-nav" focusOnClick={false} tooltipText="Mes anterior (←)" onClicked={() => step(-1)}>
                    <label label="󰅁" />
                  </button>
                  <button
                    class={isCurrent ? "cal-nav dim" : "cal-nav"}
                    focusOnClick={false}
                    tooltipText="Volver a hoy (Inicio)"
                    onClicked={() => setShown(currentMonth())}
                  >
                    <label label="󰧞" />
                  </button>
                  <button class="cal-nav" focusOnClick={false} tooltipText="Mes siguiente (→)" onClicked={() => step(1)}>
                    <label label="󰅂" />
                  </button>
                </box>
                <Gtk.Grid class="cal-grid" columnHomogeneous rowSpacing={2} columnSpacing={2}
                  $={(grid: Gtk.Grid) => {
                    WEEKDAYS.forEach((d, col) => {
                      const head = new Gtk.Label({ label: d })
                      head.add_css_class("cal-dow")
                      grid.attach(head, col, 0, 1, 1)
                    })
                    cells.forEach((c, i) => {
                      const cell = new Gtk.Label({ label: String(c.day) })
                      cell.add_css_class("cal-day")
                      if (!c.inMonth) cell.add_css_class("out")
                      else if (c.today) cell.add_css_class("today")
                      else if (c.weekend) cell.add_css_class("weekend")
                      grid.attach(cell, i % 7, Math.floor(i / 7) + 1, 1, 1)
                    })
                  }}
                />
              </box>
            )
          }}
        </With>
      </box>
    </window>
  )
}
