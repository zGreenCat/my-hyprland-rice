import Gdk from "gi://Gdk?version=4.0"
import GLib from "gi://GLib"
import Pango from "gi://Pango"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState, With } from "gnim"

const WINDOW_NAME = "clipboard"
const HOME = GLib.getenv("HOME") ?? ""
const HELPER = `${HOME}/.config/ags/widget/clipboard/cliphist.py`
const MAX_VISIBLE = 100

type ClipType = "text" | "link" | "color" | "image"

type ClipboardItem = {
  source: string
  type: ClipType
  label: string
  thumb: string | null
}

type Detail = {
  type: ClipType
  meta: string
  text: string | null
  image: string | null
}

type View = {
  items: ClipboardItem[]
  query: string
  selected: number
}

const TYPE_GLYPH: Record<ClipType, string> = { text: "T", link: "↗", color: "●", image: "▣" }
const TYPE_NAME: Record<ClipType, string> = { text: "Texto", link: "Enlace", color: "Color", image: "Imagen" }

const HEX_COLOR = /^#([0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i

function colorMarkup(text: string, color: string): string {
  const safe = GLib.markup_escape_text(text, -1)
  const value = color.trim()
  return HEX_COLOR.test(value) ? `<span foreground="${value}">${safe}</span>` : safe
}

function textureFrom(path: string): Gdk.Texture | null {
  try {
    return Gdk.Texture.new_from_filename(path)
  } catch (err) {
    console.error(err)
    return null
  }
}

export default function Clipboard() {
  const [view, setView] = createState<View>({ items: [], query: "", selected: 0 })
  const [detail, setDetail] = createState<Detail | null>(null)
  let searchEntry: Gtk.Entry | undefined
  let detailRequest = 0

  function visibleItems(v = view.peek()) {
    const term = v.query.trim().toLocaleLowerCase()
    return v.items.filter((item) => item.label.toLocaleLowerCase().includes(term)).slice(0, MAX_VISIBLE)
  }

  function focusSearch() {
    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
      searchEntry?.grab_focus()
      return GLib.SOURCE_REMOVE
    })
  }

  function loadDetail(item: ClipboardItem | undefined) {
    const request = ++detailRequest
    if (!item) {
      setDetail(null)
      return
    }
    execAsync([HELPER, "show", item.source])
      .then((output) => {
        if (request === detailRequest) setDetail(JSON.parse(output) as Detail)
      })
      .catch((err) => {
        console.error(err)
        if (request === detailRequest)
          setDetail({ type: item.type, meta: "No se pudo leer esta entrada", text: null, image: null })
      })
  }

  function select(index: number) {
    const items = visibleItems()
    const selected = items.length ? Math.max(0, Math.min(items.length - 1, index)) : 0
    setView((v) => ({ ...v, selected }))
    loadDetail(items[selected])
  }

  function close() {
    searchEntry?.set_text("")
    setView((v) => ({ ...v, query: "", selected: 0 }))
    app.get_window(WINDOW_NAME)?.hide()
  }

  function copy(item: ClipboardItem | undefined) {
    if (!item) return
    execAsync([HELPER, "copy", item.source]).then(close).catch(console.error)
  }

  function refresh(keepIndex = 0) {
    execAsync([HELPER, "list"])
      .then((output) => {
        setView((v) => ({ ...v, items: JSON.parse(output) as ClipboardItem[] }))
        select(keepIndex)
        focusSearch()
      })
      .catch(console.error)
  }

  function remove(item: ClipboardItem | undefined) {
    if (!item) return
    const index = view.peek().selected
    execAsync([HELPER, "delete", item.source])
      .then(() => refresh(index))
      .catch(console.error)
  }

  function thumb(item: ClipboardItem) {
    if (item.thumb) return <image class="clip-thumb" file={item.thumb} pixelSize={28} />
    const glyph = TYPE_GLYPH[item.type]
    return (
      <label
        class="clip-glyph"
        useMarkup
        label={item.type === "color" ? colorMarkup(glyph, item.label) : GLib.markup_escape_text(glyph, -1)}
      />
    )
  }

  function preview(d: Detail | null) {
    if (!d) return <label class="clip-empty" label="Sin entradas" xalign={0} valign={Gtk.Align.START} />
    return (
      <box orientation={Gtk.Orientation.VERTICAL} spacing={14} vexpand hexpand>
        <label class="clip-meta" label={`${TYPE_NAME[d.type]} · ${d.meta}`} xalign={0} />
        {d.image ? (
          <Gtk.Picture
            class="clip-image"
            contentFit={Gtk.ContentFit.CONTAIN}
            canShrink
            vexpand
            hexpand
            $={(self: Gtk.Picture) => self.set_paintable(textureFrom(d.image!))}
          />
        ) : (
          <Gtk.ScrolledWindow class="clip-textbox" vexpand hexpand hscrollbarPolicy={Gtk.PolicyType.NEVER}>
            <label
              class={d.type === "color" ? "clip-text clip-color" : "clip-text"}
              useMarkup={d.type === "color"}
              label={d.type === "color" ? colorMarkup(d.text ?? "", d.text ?? "") : (d.text ?? "")}
              hexpand
              widthRequest={420}
              xalign={0}
              yalign={0}
              wrap
              wrapMode={Pango.WrapMode.WORD_CHAR}
              selectable={false}
            />
          </Gtk.ScrolledWindow>
        )}
      </box>
    )
  }

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      class="Clipboard"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={Astal.WindowAnchor.NONE}
      onNotifyVisible={(self: Gtk.Window) => {
        if (self.visible) {
          refresh()
          return
        }
        searchEntry?.set_text("")
        setView((v) => ({ ...v, query: "", selected: 0 }))
      }}
    >
      <Gtk.EventControllerKey
        propagationPhase={Gtk.PropagationPhase.CAPTURE}
        onKeyPressed={(_ctrl: unknown, keyval: number) => {
          const items = visibleItems()
          const selected = view.peek().selected
          switch (keyval) {
            case Gdk.KEY_Escape:
              close()
              return true
            case Gdk.KEY_Return:
            case Gdk.KEY_KP_Enter:
              copy(items[selected])
              return true
            case Gdk.KEY_Down:
              select(selected + 1)
              return true
            case Gdk.KEY_Up:
              select(selected - 1)
              return true
            case Gdk.KEY_Delete:
              remove(items[selected])
              return true
          }
          return false
        }}
      />
      <box orientation={Gtk.Orientation.VERTICAL} class="clip-root">
        <entry
          class="clip-search"
          placeholderText="Buscar en el historial"
          $={(self: Gtk.Entry) => {
            searchEntry = self
          }}
          onNotifyText={(self: Gtk.Entry) => {
            setView((v) => ({ ...v, query: self.text }))
            select(0)
          }}
        />
        <box class="clip-body" vexpand>
          <Gtk.ScrolledWindow class="clip-scroll" hscrollbarPolicy={Gtk.PolicyType.NEVER} widthRequest={360}>
            <With value={view}>
              {(v: View) => (
                <box orientation={Gtk.Orientation.VERTICAL} class="clip-list">
                  {visibleItems(v).map((item, index) => (
                    <button
                      class={index === v.selected ? "clip-row selected" : "clip-row"}
                      focusOnClick={false}
                      onClicked={() => (index === v.selected ? copy(item) : select(index))}
                    >
                      <box spacing={12}>
                        {thumb(item)}
                        <label class="clip-label" label={item.label} hexpand xalign={0} ellipsize={Pango.EllipsizeMode.END} />
                      </box>
                    </button>
                  ))}
                </box>
              )}
            </With>
          </Gtk.ScrolledWindow>
          <box class="clip-preview" hexpand>
            <With value={detail}>{(d: Detail | null) => preview(d)}</With>
          </box>
        </box>
        <box class="clip-foot" spacing={18}>
          <label label="↵ copiar" />
          <label label="Supr borrar" />
          <label label="Esc cerrar" />
          <label label="clic: elegir · segundo clic: copiar" hexpand xalign={1} />
        </box>
      </box>
    </window>
  )
}
