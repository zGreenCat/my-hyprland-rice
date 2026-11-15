import GLib from "gi://GLib"
import Gdk from "gi://Gdk?version=4.0"
import GdkPixbuf from "gi://GdkPixbuf?version=2.0"
import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState } from "gnim"
import { loadThemes, getActiveThemeFolder } from "./themes"

const WINDOW_NAME = "wallpaper-picker"
const HOME = GLib.getenv("HOME") ?? ""
const SCRIPTS = `${HOME}/.config/hypr/scripts`

const CARD_W = 110
const CARD_H = 480
const SQUARE_SIZE = 400
const CARD_GAP = 24
const CURVE_K = 6
const CONTAINER_W = 1850
const CONTAINER_H = 760

const themes = loadThemes()

function scaleAt(dist: number) {
  return Math.max(0.35, 1 - dist * 0.18)
}

function widthAt(k: number, s: number) {
  return k === s ? SQUARE_SIZE : CARD_W * scaleAt(Math.abs(k - s))
}

// Cumulative offset from the selected card, packing each card edge-to-edge
// (plus a fixed gap) against its actual scaled width, so distant (smaller)
// cards don't drift apart just because their center-to-center step stayed fixed.
function offsetOf(i: number, s: number) {
  if (i === s) return 0
  const dir = i > s ? 1 : -1
  let pos = 0
  for (let k = s; k !== i; k += dir) {
    pos += dir * (widthAt(k, s) / 2 + CARD_GAP + widthAt(k + dir, s) / 2)
  }
  return pos
}

function indexOfActive() {
  const folder = getActiveThemeFolder()
  const i = themes.findIndex((t) => t.folder === folder)
  return i >= 0 ? i : 0
}

function loadCoverThumbnail(path: string, targetW: number, targetH: number): GdkPixbuf.Pixbuf {
  const original = GdkPixbuf.Pixbuf.new_from_file(path)
  const scale = Math.max(targetW / original.get_width(), targetH / original.get_height())
  const scaledW = Math.ceil(original.get_width() * scale)
  const scaledH = Math.ceil(original.get_height() * scale)
  const scaled = original.scale_simple(scaledW, scaledH, GdkPixbuf.InterpType.BILINEAR)!
  const offsetX = Math.floor((scaledW - targetW) / 2)
  const offsetY = Math.floor((scaledH - targetH) / 2)
  return scaled.new_subpixbuf(offsetX, offsetY, targetW, targetH)
}

export default function WallpaperPicker() {
  const [index, setIndex] = createState(indexOfActive())

  function close() {
    app.get_window(WINDOW_NAME)?.hide()
  }

  function apply(i: number) {
    const theme = themes[i]
    if (theme) {
      execAsync([`${SCRIPTS}/apply-theme.sh`, theme.folder]).catch((err) => console.error(err))
    }
    close()
  }

  if (themes.length === 0) {
    return (
      <window name={WINDOW_NAME} namespace={WINDOW_NAME} class="WallpaperPicker" visible={false} application={app}>
        <label label="No se encontraron temas en ~/.config/hypr/themes" />
      </window>
    )
  }

  function buildCard(i: number) {
    const theme = themes[i]
    let picture: Gtk.Picture | undefined
    let currentW = CARD_W
    let currentH = CARD_H
    let animId = 0

    function animateShape(square: boolean) {
      if (!picture) return
      const fromW = currentW
      const fromH = currentH
      const toW = square ? SQUARE_SIZE : CARD_W
      const toH = square ? SQUARE_SIZE : CARD_H
      if (fromW === toW && fromH === toH) return

      const steps = 12
      const durationMs = 220
      const myAnim = ++animId
      let step = 0

      GLib.timeout_add(GLib.PRIORITY_DEFAULT, Math.round(durationMs / steps), () => {
        if (myAnim !== animId || !picture) return GLib.SOURCE_REMOVE
        step++
        const t = Math.min(1, step / steps)
        const eased = 1 - Math.pow(1 - t, 3)
        currentW = Math.round(fromW + (toW - fromW) * eased)
        currentH = Math.round(fromH + (toH - fromH) * eased)
        picture.set_size_request(currentW, currentH)
        return t < 1 ? GLib.SOURCE_CONTINUE : GLib.SOURCE_REMOVE
      })
    }

    index.subscribe(() => animateShape(index.peek() === i))

    return (
      <button
        class={index.as((s) => (s === i ? "wp-card selected" : "wp-card"))}
        css={index.as((s) => {
          const dist = Math.abs(i - s)
          const scale = i === s ? 1 : scaleAt(dist)
          const recenter = i === s ? (SQUARE_SIZE - CARD_W) / 2 : 0
          const dx = offsetOf(i, s) - recenter
          const dy = CURVE_K * dist * dist
          return `transform: translate(${dx}px, ${dy}px) scale(${scale});`
        })}
        onClicked={() => apply(i)}
      >
        <Gtk.Picture
          $={(self: Gtk.Picture) => {
            picture = self
            try {
              const pixbuf = loadCoverThumbnail(theme.wallpaper, SQUARE_SIZE, SQUARE_SIZE)
              self.set_paintable(Gdk.Texture.new_for_pixbuf(pixbuf))
            } catch (err) {
              console.error(err)
            }
            if (index.peek() === i) {
              currentW = SQUARE_SIZE
              currentH = SQUARE_SIZE
              self.set_size_request(SQUARE_SIZE, SQUARE_SIZE)
            }
          }}
          contentFit={Gtk.ContentFit.COVER}
          widthRequest={CARD_W}
          heightRequest={CARD_H}
          class="wp-thumb"
        />
      </button>
    )
  }

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      class="WallpaperPicker"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={Astal.WindowAnchor.NONE}
      onNotifyVisible={(self: Gtk.Window) => {
        if (self.visible) setIndex(indexOfActive())
      }}
    >
      <Gtk.EventControllerKey
        propagationPhase={Gtk.PropagationPhase.CAPTURE}
        onKeyPressed={(_ctrl: unknown, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) {
            close()
            return true
          }
          if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) {
            apply(index.peek())
            return true
          }
          if (keyval === Gdk.KEY_Right) {
            setIndex((i) => Math.min(themes.length - 1, i + 1))
            return true
          }
          if (keyval === Gdk.KEY_Left) {
            setIndex((i) => Math.max(0, i - 1))
            return true
          }
          return false
        }}
      />
      <box orientation={Gtk.Orientation.VERTICAL} class="wp-root">
        <Gtk.Fixed
          widthRequest={CONTAINER_W}
          heightRequest={CONTAINER_H}
          $={(self: Gtk.Fixed) => {
            const cards: Gtk.Widget[] = []
            const baseX = Math.round(CONTAINER_W / 2 - CARD_W / 2)

            themes.forEach((_, i) => {
              const card = buildCard(i) as unknown as Gtk.Widget
              self.put(card, baseX, 0)
              cards[i] = card
            })

            function reorderZ(s: number) {
              const order = themes.map((_, i) => i).sort((a, b) => Math.abs(b - s) - Math.abs(a - s))
              let prev: Gtk.Widget | null = null
              for (const i of order) {
                cards[i].insert_after(self, prev)
                prev = cards[i]
              }
            }

            reorderZ(index.peek())
            index.subscribe(() => reorderZ(index.peek()))
          }}
        />
      </box>
    </window>
  )
}
