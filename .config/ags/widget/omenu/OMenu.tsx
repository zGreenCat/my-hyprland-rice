import GLib from "gi://GLib"
import Pango from "gi://Pango"
import AstalApps from "gi://AstalApps?version=0.1"
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState, With } from "gnim"
import { actions, type Action } from "./categories"
import { FILTERS, MAX_RESULTS, clampIndex, nextFilter, visibleEntries, type Entry, type Filter } from "./search"

const WINDOW_NAME = "omenu"
const apps = new AstalApps.Apps({})

interface AppEntry extends Entry {
  kind: "app"
  icon: string
  run: () => void
}
type Item = AppEntry | Action

interface View {
  filter: Filter
  query: string
  selected: number
}

const INITIAL_VIEW: View = { filter: "Todo", query: "", selected: 0 }

function rankedApps(query: string): AppEntry[] {
  return apps
    .fuzzy_query(query || null)
    .slice(0, MAX_RESULTS)
    .map((a) => ({
      kind: "app",
      title: a.name,
      category: "Apps",
      subtitle: a.description ?? "",
      icon: a.iconName || "application-x-executable-symbolic",
      run: () => a.launch(),
    }))
}

function itemsFor(view: View): Item[] {
  return visibleEntries<Item>(rankedApps(view.query), actions, view.filter, view.query)
}

export default function OMenu() {
  const [view, setView] = createState<View>(INITIAL_VIEW)
  let searchEntry: Gtk.Entry | undefined

  function focusSearch() {
    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
      searchEntry?.grab_focus()
      return GLib.SOURCE_REMOVE
    })
  }

  function update(change: Partial<View>) {
    setView((v) => ({ ...v, ...change }))
  }

  function setFilter(filter: Filter) {
    update({ filter, selected: 0 })
    focusSearch()
  }

  function clearQuery() {
    searchEntry?.set_text("")
    update({ query: "", selected: 0 })
  }

  function close() {
    searchEntry?.set_text("")
    setView(INITIAL_VIEW)
    app.get_window(WINDOW_NAME)?.hide()
  }

  function launch(item: Item | undefined) {
    if (!item) return
    item.run()
    close()
  }

  function moveSelection(step: number) {
    const v = view.peek()
    update({ selected: clampIndex(v.selected + step, itemsFor(v).length) })
  }

  function onKey(_ctrl: unknown, keyval: number, _code: number, state: Gdk.ModifierType) {
    const v = view.peek()
    switch (keyval) {
      case Gdk.KEY_Escape:
        if (v.query) clearQuery()
        else close()
        return true
      case Gdk.KEY_Return:
      case Gdk.KEY_KP_Enter:
        launch(itemsFor(v)[v.selected])
        return true
      case Gdk.KEY_Down:
        moveSelection(1)
        return true
      case Gdk.KEY_Up:
        moveSelection(-1)
        return true
      case Gdk.KEY_Tab:
      case Gdk.KEY_ISO_Left_Tab: {
        const back = keyval === Gdk.KEY_ISO_Left_Tab || (state & Gdk.ModifierType.SHIFT_MASK) !== 0
        setFilter(nextFilter(v.filter, back ? -1 : 1))
        return true
      }
      case Gdk.KEY_Right:
      case Gdk.KEY_Left:
        if (v.query) return false
        setFilter(nextFilter(v.filter, keyval === Gdk.KEY_Right ? 1 : -1))
        return true
    }
    return false
  }

  function row(item: Item, index: number, selected: number, showCategory: boolean) {
    return (
      <button
        class={index === selected ? "omenu-row selected" : "omenu-row"}
        focusOnClick={false}
        onClicked={() => launch(item)}
      >
        <box spacing={14}>
          <image
            class={item.kind === "app" ? "omenu-appicon" : "omenu-acticon"}
            iconName={item.icon}
            pixelSize={item.kind === "app" ? 26 : 18}
          />
          <label class="omenu-title" label={item.title} hexpand xalign={0} ellipsize={Pango.EllipsizeMode.END} />
          <label class="omenu-meta" label={showCategory && item.kind === "action" ? item.category : ""} />
          <label class="omenu-key" label="↵" visible={index === selected} />
        </box>
      </button>
    )
  }

  return (
    <window
      name={WINDOW_NAME}
      namespace="omenu"
      class="OMenu"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={Astal.WindowAnchor.TOP}
      marginTop={220}
      onNotifyVisible={(self: Gtk.Window) => {
        if (self.visible) focusSearch()
      }}
    >
      <Gtk.EventControllerKey propagationPhase={Gtk.PropagationPhase.CAPTURE} onKeyPressed={onKey} />
      <box orientation={Gtk.Orientation.VERTICAL} class="omenu-root">
        <box class="omenu-search" spacing={14}>
          <label class="omenu-prompt" label="❯" />
          <entry
            class="omenu-entry"
            hexpand
            placeholderText="Buscar apps y acciones"
            $={(self: Gtk.Entry) => {
              searchEntry = self
            }}
            onNotifyText={(self: Gtk.Entry) => update({ query: self.text, selected: 0 })}
          />
        </box>
        <box>
          <With value={view}>
            {(v: View) => (
              <box class="omenu-chips" spacing={6}>
                {FILTERS.map((f) => (
                  <button
                    class={f === v.filter ? "omenu-chip on" : "omenu-chip"}
                    focusOnClick={false}
                    onClicked={() => setFilter(f)}
                  >
                    <label label={f} />
                  </button>
                ))}
              </box>
            )}
          </With>
        </box>
        <box orientation={Gtk.Orientation.VERTICAL}>
          <With value={view}>
            {(v: View) => {
              const items = itemsFor(v)
              if (items.length === 0) {
                return (
                  <box class="omenu-list">
                    <label class="omenu-empty" label="Sin resultados" xalign={0} hexpand />
                  </box>
                )
              }
              const showSections = v.filter === "Todo"
              return (
                <box class="omenu-list" orientation={Gtk.Orientation.VERTICAL}>
                  {items.flatMap((item, i) => {
                    const startsSection = showSections && (i === 0 || items[i - 1].kind !== item.kind)
                    const header = <label class="omenu-section" label={item.kind === "app" ? "Apps" : "Acciones"} xalign={0} />
                    const entry = row(item, i, v.selected, showSections)
                    return startsSection ? [header, entry] : [entry]
                  })}
                </box>
              )
            }}
          </With>
        </box>
        <box class="omenu-foot" spacing={18}>
          <label label="↑↓ moverse" />
          <label label="↵ abrir" />
          <label label="Tab filtro" />
          <label label="Esc cerrar" />
        </box>
      </box>
    </window>
  )
}
