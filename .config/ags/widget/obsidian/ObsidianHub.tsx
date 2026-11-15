import GLib from "gi://GLib"
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState, With } from "gnim"

const HOME = GLib.getenv("HOME") ?? ""
const SCRIPTS = `${HOME}/.config/hypr/scripts`

function exec(cmd: string[]) {
  execAsync(cmd).catch((err) => console.error(err))
}

const WINDOW_NAME = "obsidian"

type View = "root" | "meeting" | "decision"

export default function ObsidianHub() {
  const [view, setView] = createState<View>("root")

  function close() {
    setView("root")
    app.get_window(WINDOW_NAME)?.hide()
  }

  let meetingEntry: Gtk.Entry
  let decisionEntry: Gtk.Entry
  let contextEntry: Gtk.Entry
  let listBox: Gtk.Box | undefined

  function submitMeeting() {
    const topic = meetingEntry.text.trim()
    if (!topic) return
    exec([`${SCRIPTS}/obsidian-new-meeting.sh`, topic])
    close()
  }

  function submitDecision() {
    const decision = decisionEntry.text.trim()
    if (!decision) return
    exec([`${SCRIPTS}/obsidian-new-decision.sh`, decision, contextEntry.text.trim()])
    close()
  }

  return (
    <window
      name={WINDOW_NAME}
      namespace="obsidian-hub"
      class="ObsidianHub"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={Astal.WindowAnchor.NONE}
      widthRequest={440}
    >
      <Gtk.EventControllerKey
        propagationPhase={Gtk.PropagationPhase.CAPTURE}
        onKeyPressed={(_ctrl: unknown, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) {
            close()
            return true
          }
          if (keyval === Gdk.KEY_Down) {
            listBox?.child_focus(Gtk.DirectionType.DOWN)
            return true
          }
          if (keyval === Gdk.KEY_Up) {
            listBox?.child_focus(Gtk.DirectionType.UP)
            return true
          }
          return false
        }}
      />
      <box orientation={Gtk.Orientation.VERTICAL} class="obsidian-root">
        <With value={view}>
          {(id) => {
            if (id === "root") {
              return (
                <box orientation={Gtk.Orientation.VERTICAL} class="obsidian-screen">
                  <label label="Obsidian" class="obsidian-title" halign={Gtk.Align.START} />
                  <box
                    orientation={Gtk.Orientation.VERTICAL}
                    class="obsidian-list"
                    $={(self: Gtk.Box) => {
                      listBox = self
                      GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                        self.child_focus(Gtk.DirectionType.TAB_FORWARD)
                        return GLib.SOURCE_REMOVE
                      })
                    }}
                  >
                    <button class="obsidian-item" onClicked={() => setView("meeting")}>
                      <box>
                        <image iconName="calendar" pixelSize={28} />
                        <label label="Nueva reunión" halign={Gtk.Align.START} hexpand />
                      </box>
                    </button>
                    <button class="obsidian-item" onClicked={() => setView("decision")}>
                      <box>
                        <image iconName="dialog-question-symbolic" pixelSize={28} />
                        <label label="Nueva decisión" halign={Gtk.Align.START} hexpand />
                      </box>
                    </button>
                    <button
                      class="obsidian-item"
                      onClicked={() => {
                        exec([`${SCRIPTS}/pdf-to-vault.sh`])
                        close()
                      }}
                    >
                      <box>
                        <image iconName="application-pdf" pixelSize={28} />
                        <label label="Importar PDF" halign={Gtk.Align.START} hexpand />
                      </box>
                    </button>
                    <button
                      class="obsidian-item"
                      onClicked={() => {
                        exec(["obsidian", "obsidian://open?vault=mango-vault"])
                        close()
                      }}
                    >
                      <box>
                        <image iconName="obsidian" pixelSize={28} />
                        <label label="Abrir vault" halign={Gtk.Align.START} hexpand />
                      </box>
                    </button>
                  </box>
                </box>
              )
            }

            if (id === "meeting") {
              return (
                <box orientation={Gtk.Orientation.VERTICAL} class="obsidian-screen">
                  <box class="obsidian-header">
                    <button class="obsidian-back" onClicked={() => setView("root")}>
                      <image iconName="go-previous-symbolic" pixelSize={16} />
                    </button>
                    <label label="Nueva reunión" class="obsidian-title" hexpand halign={Gtk.Align.START} />
                  </box>
                  <entry
                    placeholderText="Nombre de la reunión..."
                    class="obsidian-entry"
                    $={(self: Gtk.Entry) => {
                      meetingEntry = self
                      GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                        self.grab_focus()
                        return GLib.SOURCE_REMOVE
                      })
                    }}
                    onActivate={submitMeeting}
                  />
                  <button class="obsidian-submit" onClicked={submitMeeting}>
                    <label label="Crear" />
                  </button>
                </box>
              )
            }

            return (
              <box orientation={Gtk.Orientation.VERTICAL} class="obsidian-screen">
                <box class="obsidian-header">
                  <button class="obsidian-back" onClicked={() => setView("root")}>
                    <image iconName="go-previous-symbolic" pixelSize={16} />
                  </button>
                  <label label="Nueva decisión" class="obsidian-title" hexpand halign={Gtk.Align.START} />
                </box>
                <entry
                  placeholderText="Describe la decisión..."
                  class="obsidian-entry"
                  $={(self: Gtk.Entry) => {
                    decisionEntry = self
                    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                      self.grab_focus()
                      return GLib.SOURCE_REMOVE
                    })
                  }}
                  onActivate={submitDecision}
                />
                <entry
                  placeholderText="Contexto/razón (opcional)..."
                  class="obsidian-entry"
                  $={(self: Gtk.Entry) => (contextEntry = self)}
                  onActivate={submitDecision}
                />
                <button class="obsidian-submit" onClicked={submitDecision}>
                  <label label="Guardar" />
                </button>
              </box>
            )
          }}
        </With>
      </box>
    </window>
  )
}
