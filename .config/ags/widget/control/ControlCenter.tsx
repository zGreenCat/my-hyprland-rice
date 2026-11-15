import GLib from "gi://GLib"
import Pango from "gi://Pango"
import Wp from "gi://AstalWp"
import AstalNotifd from "gi://AstalNotifd?version=0.1"
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { Accessor, createBinding, createConnection, createState, For, With } from "gnim"
import { notifd, type Notification } from "../notifications/notifd"
import { LIMITS, plainText, timeLabel, truncate, type PlayerState } from "./parse"
import Avatar, { colorClass } from "../notifications/Avatar"
import {
  playerAction,
  readPlayer,
  readSystem,
  setBluetooth,
  setBrightness,
  setWifi,
  toggleNoLock,
  type SystemState,
} from "./system"

export const CONTROL_WINDOW = "control-center"
const PLAYER_POLL_MS = 2000
const SYSTEM_POLL_MS = 10_000
const HIDDEN_STREAM = /speech-dispatcher/

const INITIAL_SYSTEM: SystemState = {
  wifi: { enabled: false, ssid: null },
  bluetooth: { powered: false, device: null },
  brightness: null,
  noLock: false,
}

const [mixerOpen, setMixerOpen] = createState(false)

/** Abre el centro; con `withMixer` despliega "Salida y apps" (clic derecho en el volumen de waybar). */
export function showControlCenter(withMixer: boolean) {
  setMixerOpen(withMixer)
  app.get_window(CONTROL_WINDOW)?.show()
}

function closeControlCenter() {
  app.get_window(CONTROL_WINDOW)?.hide()
}

/* ───────────────────────── piezas ───────────────────────── */

function initVolumeScale(self: Gtk.Scale, node: Wp.Node, volume: Accessor<number>) {
  let dragging = false
  self.set_range(0, 100)
  self.set_increments(1, 5)
  self.set_value(node.volume * 100)
  const drag = new Gtk.GestureClick()
  drag.connect("pressed", () => (dragging = true))
  drag.connect("released", () => (dragging = false))
  self.add_controller(drag)
  self.connect("value-changed", () => {
    node.volume = self.get_value() / 100
  })
  volume.subscribe(() => {
    if (!dragging) self.set_value(volume.peek() * 100)
  })
}

function Tile(props: { icon: string; title: string; subtitle: string; active: boolean; onToggle: () => void }) {
  return (
    <button class={props.active ? "cc-tile on" : "cc-tile"} hexpand focusOnClick={false} onClicked={props.onToggle}>
      <box spacing={12}>
        <label class="cc-tile-icon" label={props.icon} />
        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER} hexpand>
          <label class="cc-tile-title" label={props.title} xalign={0} />
          <label class="cc-tile-sub" label={props.subtitle} xalign={0} ellipsize={Pango.EllipsizeMode.END} maxWidthChars={14} />
        </box>
      </box>
    </button>
  )
}

function VolumeRow({ endpoint, icon }: { endpoint: Wp.Endpoint; icon: "speaker" | "mic" }) {
  const muted = createBinding(endpoint, "mute")
  const volume = createBinding(endpoint, "volume")
  const glyph = muted.as((m) => (icon === "mic" ? (m ? "󰍭" : "󰍬") : m ? "󰖁" : "󰕾"))
  return (
    <box class={muted.as((m) => (m ? "cc-slider muted" : "cc-slider"))} spacing={10}>
      <button class="cc-slider-icon" focusOnClick={false} onClicked={() => endpoint.set_mute(!endpoint.get_mute())}>
        <label label={glyph} />
      </button>
      <Gtk.Scale hexpand drawValue={false} $={(self: Gtk.Scale) => initVolumeScale(self, endpoint, volume)} />
      <label class="cc-slider-value" label={volume.as((v) => `${Math.round(v * 100)}%`)} widthChars={4} xalign={1} />
    </box>
  )
}

function StreamRow({ stream }: { stream: Wp.Stream }) {
  const name = createBinding(stream, "description").as((d) => d || stream.name || "Aplicación")
  const icon = createBinding(stream, "icon").as((i) => i || "audio-x-generic-symbolic")
  const volume = createBinding(stream, "volume")
  const muted = createBinding(stream, "mute")
  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="cc-stream" spacing={4}>
      <box spacing={8}>
        <image iconName={icon} pixelSize={16} />
        <label class="cc-stream-name" label={name} xalign={0} hexpand ellipsize={Pango.EllipsizeMode.END} />
      </box>
      <box class={muted.as((m) => (m ? "cc-slider small muted" : "cc-slider small"))} spacing={10}>
        <button class="cc-slider-icon" focusOnClick={false} onClicked={() => stream.set_mute(!stream.get_mute())}>
          <label label={muted.as((m) => (m ? "󰖁" : "󰕾"))} />
        </button>
        <Gtk.Scale hexpand drawValue={false} $={(self: Gtk.Scale) => initVolumeScale(self, stream, volume)} />
        <label class="cc-slider-value" label={volume.as((v) => `${Math.round(v * 100)}%`)} widthChars={4} xalign={1} />
      </box>
    </box>
  )
}

function Mixer() {
  const audio = Wp.get_default()!.audio
  const speakers = createConnection<Wp.Endpoint[]>(
    audio.get_speakers() ?? [],
    [audio, "speaker-added", () => audio.get_speakers() ?? []],
    [audio, "speaker-removed", () => audio.get_speakers() ?? []],
  )
  const appStreams = () => (audio.get_streams() ?? []).filter((s) => !HIDDEN_STREAM.test(`${s.name ?? ""} ${s.description ?? ""}`))
  const streams = createConnection<Wp.Stream[]>(
    appStreams(),
    [audio, "stream-added", appStreams],
    [audio, "stream-removed", appStreams],
  )
  const microphone = createConnection<Wp.Endpoint>(audio.default_microphone, [
    audio,
    "notify::default-microphone",
    () => audio.default_microphone,
  ])

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="cc-mixer" spacing={10}>
      <label class="cc-caption" label="SALIDA" xalign={0} />
      <box class="cc-outputs" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <For each={speakers}>
          {(sp: Wp.Endpoint) => (
            <button
              class={createBinding(sp, "isDefault").as((on) => (on ? "cc-output on" : "cc-output"))}
              hexpand
              focusOnClick={false}
              onClicked={() => sp.set_is_default(true)}
            >
              <label label={sp.description || sp.name || "Salida"} xalign={0} ellipsize={Pango.EllipsizeMode.END} />
            </button>
          )}
        </For>
      </box>
      <label class="cc-caption" label="APPS" xalign={0} />
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <With value={streams.as((s) => s.length === 0)}>
          {(empty: boolean) => (empty ? <label class="cc-muted" label="Ninguna app está sonando" xalign={0} /> : <box />)}
        </With>
        <For each={streams}>{(s: Wp.Stream) => <StreamRow stream={s} />}</For>
      </box>
      <label class="cc-caption" label="MICRÓFONO" xalign={0} />
      <box>
        <With value={microphone}>{(mic: Wp.Endpoint) => (mic ? <VolumeRow endpoint={mic} icon="mic" /> : <box />)}</With>
      </box>
    </box>
  )
}

function Player({ player }: { player: PlayerState }) {
  return (
    <box class="cc-player" spacing={12}>
      <label class="cc-player-art" label="󰎆" />
      <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
        <label class="cc-player-title" label={player.title} xalign={0} ellipsize={Pango.EllipsizeMode.END} maxWidthChars={22} />
        <label
          class="cc-player-artist"
          label={[player.artist, player.player].filter(Boolean).join(" · ")}
          xalign={0}
          ellipsize={Pango.EllipsizeMode.END}
          maxWidthChars={26}
        />
      </box>
      <box spacing={2} valign={Gtk.Align.CENTER}>
        <button class="cc-player-btn" focusOnClick={false} onClicked={() => playerAction("previous")}>
          <label label="󰒮" />
        </button>
        <button class="cc-player-btn main" focusOnClick={false} onClicked={() => playerAction("play-pause")}>
          <label label={player.status === "Playing" ? "󰏤" : "󰐊"} />
        </button>
        <button class="cc-player-btn" focusOnClick={false} onClicked={() => playerAction("next")}>
          <label label="󰒭" />
        </button>
      </box>
    </box>
  )
}

function TimelineItem({ n }: { n: Notification }) {
  const title = plainText(n.summary)
  const body = plainText(n.body)
  const urgent = n.urgency === AstalNotifd.Urgency.CRITICAL
  const clipped = title.length > LIMITS.listTitle || body.length > LIMITS.listBody
  return (
    <box class="tl-line" spacing={10}>
      <label class="tl-time" label={timeLabel(n.time)} widthChars={5} xalign={1} valign={Gtk.Align.START} />
      <box
        class={urgent ? "tl-item urgent" : "tl-item"}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={2}
        hexpand
        tooltipText={clipped ? [title, body].filter(Boolean).join("\n\n") : ""}
      >
        <box spacing={8}>
          <box class={`tl-dot ${colorClass(n)}`} valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER} widthRequest={8} heightRequest={8} />
          <Avatar n={n} size={16} />
          <label class="tl-app" label={n.appName || "Notificación"} xalign={0} ellipsize={Pango.EllipsizeMode.END} />
          <label class="tl-urgent" label="urgente" visible={urgent} />
          <box hexpand />
          <button class="tl-dismiss" focusOnClick={false} onClicked={() => n.dismiss()}>
            <label label="󰅖" />
          </button>
        </box>
        <label class="tl-title" label={truncate(title, LIMITS.listTitle)} xalign={0} ellipsize={Pango.EllipsizeMode.END} />
        <label
          class="tl-body"
          label={truncate(body, LIMITS.listBody)}
          visible={body !== ""}
          xalign={0}
          wrap
          wrapMode={Pango.WrapMode.WORD_CHAR}
          lines={2}
          ellipsize={Pango.EllipsizeMode.END}
        />
      </box>
    </box>
  )
}

/* ───────────────────────── ventana ───────────────────────── */

export default function ControlCenter() {
  const audio = Wp.get_default()!.audio
  const [system, setSystem] = createState<SystemState>(INITIAL_SYSTEM)
  const [loaded, setLoaded] = createState(false)
  const [player, setPlayer] = createState<PlayerState | null>(null)
  const [notifications, setNotifications] = createState<Notification[]>([])
  const dnd = createBinding(notifd, "dontDisturb")
  const speaker = createConnection<Wp.Endpoint>(audio.default_speaker, [
    audio,
    "notify::default-speaker",
    () => audio.default_speaker,
  ])
  let brightnessScale: Gtk.Scale | undefined
  let brightnessFromUser = true

  const visible = () => app.get_window(CONTROL_WINDOW)?.visible === true

  function refreshNotifications() {
    setNotifications(notifd.get_notifications().slice().sort((a, b) => b.time - a.time))
  }

  async function refreshSystem() {
    const state = await readSystem()
    setLoaded(true)
    setSystem(state)
    if (brightnessScale && state.brightness !== null) {
      brightnessFromUser = false
      brightnessScale.set_value(state.brightness)
      brightnessFromUser = true
    }
  }

  async function refreshPlayer() {
    setPlayer(await readPlayer())
  }

  function after(action: Promise<unknown>) {
    action.then(refreshSystem).catch(console.error)
  }

  notifd.connect("notified", refreshNotifications)
  notifd.connect("resolved", refreshNotifications)
  refreshNotifications()

  GLib.timeout_add(GLib.PRIORITY_DEFAULT, PLAYER_POLL_MS, () => {
    if (visible()) refreshPlayer()
    return GLib.SOURCE_CONTINUE
  })
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, SYSTEM_POLL_MS, () => {
    if (visible()) refreshSystem()
    return GLib.SOURCE_CONTINUE
  })

  return (
    <window
      name={CONTROL_WINDOW}
      namespace={CONTROL_WINDOW}
      class="ControlCenter"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
      marginTop={8}
      marginEnd={10}
      onNotifyVisible={(self: Gtk.Window) => {
        if (self.visible) {
          refreshSystem()
          refreshPlayer()
          refreshNotifications()
        } else {
          setMixerOpen(false)
        }
      }}
    >
      <Gtk.EventControllerKey
        propagationPhase={Gtk.PropagationPhase.CAPTURE}
        onKeyPressed={(_c: unknown, keyval: number) => {
          if (keyval !== Gdk.KEY_Escape) return false
          closeControlCenter()
          return true
        }}
      />
      <box orientation={Gtk.Orientation.VERTICAL} class="cc-root" widthRequest={400} spacing={14}>
        <box>
          <With value={system}>
            {(s: SystemState) => (
              <box orientation={Gtk.Orientation.VERTICAL} spacing={8} hexpand class={loaded.peek() ? "" : "cc-loading"}>
                <box spacing={8} homogeneous>
                  <Tile
                    icon={s.wifi.enabled ? "󰤨" : "󰤭"}
                    title="Wi-Fi"
                    subtitle={!loaded.peek() ? "…" : s.wifi.enabled ? (s.wifi.ssid ?? "Sin conexión") : "Apagado"}
                    active={s.wifi.enabled}
                    onToggle={() => after(setWifi(!s.wifi.enabled))}
                  />
                  <Tile
                    icon={s.bluetooth.powered ? "󰂯" : "󰂲"}
                    title="Bluetooth"
                    subtitle={!loaded.peek() ? "…" : s.bluetooth.powered ? (s.bluetooth.device ?? "Encendido") : "Apagado"}
                    active={s.bluetooth.powered}
                    onToggle={() => after(setBluetooth(!s.bluetooth.powered))}
                  />
                </box>
                <box spacing={8} homogeneous>
                  <With value={dnd}>
                    {(on: boolean) => (
                      <Tile
                        icon={on ? "󰂛" : "󰂚"}
                        title="No molestar"
                        subtitle={on ? "Avisos ocultos" : "Apagado"}
                        active={on}
                        onToggle={() => notifd.set_dont_disturb(!notifd.get_dont_disturb())}
                      />
                    )}
                  </With>
                  <Tile
                    icon={s.noLock ? "󰅶" : "󰛊"}
                    title="No bloquear"
                    subtitle={!loaded.peek() ? "…" : s.noLock ? "Activo" : "Apagado"}
                    active={s.noLock}
                    onToggle={() => after(toggleNoLock())}
                  />
                </box>
              </box>
            )}
          </With>
        </box>

        <box orientation={Gtk.Orientation.VERTICAL} spacing={6} class="cc-sliders">
          <box>
            <With value={speaker}>{(sp: Wp.Endpoint) => (sp ? <VolumeRow endpoint={sp} icon="speaker" /> : <box />)}</With>
          </box>
          <box class="cc-slider" spacing={10}>
            <label class="cc-slider-icon static" label="󰃟" />
            <Gtk.Scale
              hexpand
              drawValue={false}
              $={(self: Gtk.Scale) => {
                brightnessScale = self
                self.set_range(1, 100)
                self.set_increments(1, 5)
                self.connect("value-changed", () => {
                  if (brightnessFromUser) setBrightness(self.get_value())
                })
              }}
            />
            <label
              class="cc-slider-value"
              label={system.as((s) => (s.brightness === null ? "—" : `${s.brightness}%`))}
              widthChars={4}
              xalign={1}
            />
          </box>
        </box>

        <box>
          <With value={player}>{(p: PlayerState | null) => (p ? <Player player={p} /> : <box />)}</With>
        </box>

        <box orientation={Gtk.Orientation.VERTICAL} class="cc-section">
          <button class="cc-section-head" focusOnClick={false} onClicked={() => setMixerOpen(!mixerOpen.peek())}>
            <box>
              <label label="Salida y apps" xalign={0} hexpand />
              <label class="cc-chevron" label={mixerOpen.as((o) => (o ? "󰅀" : "󰅂"))} />
            </box>
          </button>
          <Gtk.Revealer
            revealChild={mixerOpen}
            transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
            transitionDuration={180}
          >
            <Mixer />
          </Gtk.Revealer>
        </box>

        <box class="cc-divider" />

        <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          <box>
            <label class="cc-heading" label="Notificaciones" xalign={0} hexpand />
            <button
              class="cc-link"
              focusOnClick={false}
              visible={notifications.as((l) => l.length > 0)}
              onClicked={() => notifd.get_notifications().forEach((n) => n.dismiss())}
            >
              <label label="Limpiar" />
            </button>
          </box>
          <Gtk.ScrolledWindow
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            propagateNaturalHeight
            maxContentHeight={420}
          >
            <box>
              <With value={notifications}>
                {(list: Notification[]) =>
                  list.length === 0 ? (
                    <label class="cc-muted cc-empty" label="Sin notificaciones" xalign={0} hexpand />
                  ) : (
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand>
                      {list.map((n) => <TimelineItem n={n} />)}
                    </box>
                  )
                }
              </With>
            </box>
          </Gtk.ScrolledWindow>
        </box>
      </box>
    </window>
  )
}
