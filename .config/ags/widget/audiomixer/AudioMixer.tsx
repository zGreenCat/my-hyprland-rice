import Wp from "gi://AstalWp"
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { Accessor, createBinding, createConnection, createState, For, With } from "gnim"

const WINDOW_NAME = "audiomixer"

function close() {
  app.get_window(WINDOW_NAME)?.hide()
}

function initVolumeScale(self: Gtk.Scale, node: Wp.Node, volume: Accessor<number>) {
  let dragging = false

  self.set_range(0, 100)
  self.set_increments(1, 10)
  self.set_value(node.volume * 100)

  const drag = new Gtk.GestureClick()
  drag.connect("pressed", () => {
    dragging = true
  })
  drag.connect("released", () => {
    dragging = false
  })
  self.add_controller(drag)

  self.connect("value-changed", () => {
    node.volume = self.get_value() / 100
  })

  volume.subscribe(() => {
    if (!dragging) self.set_value(volume.peek() * 100)
  })
}

function renderSpeakerList(activeId: number, onSelect: (speakerId: number) => void) {
  const audio = Wp.get_default()!.audio
  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="mixer-route-list">
      {(audio.get_speakers() ?? []).map((sp) => (
        <button
          class={sp.id === activeId ? "mixer-route-item active" : "mixer-route-item"}
          onClicked={() => onSelect(sp.id)}
        >
          <label label={sp.description || sp.name || "Salida"} halign={Gtk.Align.START} />
        </button>
      ))}
    </box>
  )
}

function SystemRow({
  speaker,
  onPopoverOpenChange,
}: {
  speaker: Wp.Endpoint
  onPopoverOpenChange: (open: boolean, menubutton: Gtk.MenuButton) => void
}) {
  const description = createBinding(speaker, "description").as((d) => d || speaker.name || "Sistema")
  const icon = createBinding(speaker, "icon").as((i) => i || "audio-card-symbolic")
  const muted = createBinding(speaker, "mute")
  const volume = createBinding(speaker, "volume")

  function toggleMute() {
    speaker.set_mute(!speaker.get_mute())
  }

  let menubuttonInstance: Gtk.MenuButton | null = null

  function selectDefault(speakerId: number) {
    const target = Wp.get_default()!.audio.get_speaker(speakerId)
    target?.set_is_default(true)
    menubuttonInstance?.get_popover()?.popdown()
  }

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="mixer-item mixer-system-item">
      <box class="mixer-item-header">
        <image iconName={icon} pixelSize={20} />
        <label label={description} class="mixer-app-name" hexpand halign={Gtk.Align.START} />
        <menubutton
          class="mixer-route-button"
          $={(self: Gtk.MenuButton) => {
            menubuttonInstance = self
          }}
        >
          <label label="󰓃" />
          <popover
            autohide={false}
            onNotifyVisible={(self: Gtk.Popover) => onPopoverOpenChange(self.visible, menubuttonInstance!)}
          >
            {renderSpeakerList(speaker.id, selectDefault)}
          </popover>
        </menubutton>
      </box>
      <box class="mixer-slider-row">
        <button class="mixer-icon-button" onClicked={toggleMute}>
          <label label={muted.as((m) => (m ? "󰖁" : "󰕾"))} />
        </button>
        <Gtk.Scale
          orientation={Gtk.Orientation.HORIZONTAL}
          drawValue={false}
          hexpand
          $={(self: Gtk.Scale) => initVolumeScale(self, speaker, volume)}
        />
        <label class="mixer-value" label={volume.as((v) => `${Math.round(v * 100)}%`)} />
      </box>
    </box>
  )
}

function MixerRow({
  id,
  onPopoverOpenChange,
}: {
  id: number
  onPopoverOpenChange: (open: boolean, menubutton: Gtk.MenuButton) => void
}) {
  const audio = Wp.get_default()!.audio
  const stream = audio.get_stream(id)
  if (!stream) return <box />

  const description = createBinding(stream, "description").as((d) => d || stream.name || "Aplicación")
  const icon = createBinding(stream, "icon").as((i) => i || "audio-x-generic-symbolic")
  const muted = createBinding(stream, "mute")
  const volume = createBinding(stream, "volume")
  const targetId = createBinding(stream, "targetEndpoint").as((e) => e?.id ?? -1)

  function toggleMute() {
    stream.set_mute(!stream.get_mute())
  }

  let menubuttonInstance: Gtk.MenuButton | null = null

  function routeTo(speakerId: number) {
    const speaker = audio.get_speaker(speakerId)
    if (!speaker) return
    stream.set_target_endpoint(speaker)
    menubuttonInstance?.get_popover()?.popdown()
  }

  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="mixer-item">
      <box class="mixer-item-header">
        <image iconName={icon} pixelSize={20} />
        <label label={description} class="mixer-app-name" hexpand halign={Gtk.Align.START} />
        <menubutton
          class="mixer-route-button"
          $={(self: Gtk.MenuButton) => {
            menubuttonInstance = self
          }}
        >
          <label label="󰓃" />
          <popover
            autohide={false}
            onNotifyVisible={(self: Gtk.Popover) => onPopoverOpenChange(self.visible, menubuttonInstance!)}
          >
            {renderSpeakerList(targetId.peek(), routeTo)}
          </popover>
        </menubutton>
      </box>
      <box class="mixer-slider-row">
        <button class="mixer-icon-button" onClicked={toggleMute}>
          <label label={muted.as((m) => (m ? "󰖁" : "󰕾"))} />
        </button>
        <Gtk.Scale
          orientation={Gtk.Orientation.HORIZONTAL}
          drawValue={false}
          hexpand
          $={(self: Gtk.Scale) => initVolumeScale(self, stream, volume)}
        />
        <label class="mixer-value" label={volume.as((v) => `${Math.round(v * 100)}%`)} />
      </box>
    </box>
  )
}

export default function AudioMixer() {
  const audio = Wp.get_default()!.audio

  const streamIds = createConnection<number[]>(
    (audio.get_streams() ?? []).map((s) => s.id),
    [audio, "stream-added", (s, ids) => (ids.includes(s.id) ? ids : [...ids, s.id])],
    [audio, "stream-removed", (s, ids) => ids.filter((i) => i !== s.id)],
  )

  const defaultSpeaker = createConnection<Wp.Endpoint>(audio.default_speaker, [
    audio,
    "notify::default-speaker",
    () => audio.default_speaker,
  ])

  const [routePopoverOpen, setRoutePopoverOpen] = createState(false)
  let openMenuButton: Gtk.MenuButton | null = null

  function handlePopoverOpenChange(open: boolean, menubutton: Gtk.MenuButton) {
    openMenuButton = open ? menubutton : null
    setRoutePopoverOpen(open)
  }

  function isDescendantOf(widget: Gtk.Widget | null, ancestor: Gtk.Widget): boolean {
    let w: Gtk.Widget | null = widget
    while (w) {
      if (w === ancestor) return true
      w = w.get_parent()
    }
    return false
  }

  function closeRouteMenuIfOutside(widget: Gtk.Widget, x: number, y: number) {
    if (!openMenuButton) return
    const popover = openMenuButton.get_popover()
    if (!popover) return
    const picked = widget.pick(x, y, Gtk.PickFlags.DEFAULT)
    if (!picked) return
    if (!isDescendantOf(picked, openMenuButton) && !isDescendantOf(picked, popover)) {
      popover.popdown()
    }
  }

  return (
    <window
      name={WINDOW_NAME}
      namespace={WINDOW_NAME}
      class="AudioMixerPopup"
      visible={false}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
      marginTop={40}
      marginEnd={16}
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
      <Gtk.EventControllerFocus
        onLeave={() => {
          if (!routePopoverOpen.peek()) close()
        }}
      />
      <Gtk.GestureClick
        propagationPhase={Gtk.PropagationPhase.CAPTURE}
        onPressed={(gesture: Gtk.GestureClick, _n: number, x: number, y: number) => {
          closeRouteMenuIfOutside(gesture.get_widget()!, x, y)
        }}
      />
      <box orientation={Gtk.Orientation.VERTICAL} class="mixer-root" widthRequest={360}>
        <With value={defaultSpeaker}>
          {(speaker) => <SystemRow speaker={speaker} onPopoverOpenChange={handlePopoverOpenChange} />}
        </With>
        <box class="mixer-divider" />
        <With value={streamIds.as((ids) => ids.length === 0)}>
          {(empty) => (empty ? <label label="Sin apps reproduciendo audio" class="mixer-empty" /> : "")}
        </With>
        <box orientation={Gtk.Orientation.VERTICAL} class="mixer-list">
          <For each={streamIds}>{(id: number) => <MixerRow id={id} onPopoverOpenChange={handlePopoverOpenChange} />}</For>
        </box>
      </box>
    </window>
  )
}
