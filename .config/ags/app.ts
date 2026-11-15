import app from "ags/gtk4/app"
import style from "./style.scss"
import Clipboard from "./widget/clipboard/Clipboard"
import OMenu from "./widget/omenu/OMenu"
import ObsidianHub from "./widget/obsidian/ObsidianHub"
import WallpaperPicker from "./widget/wallpaper/WallpaperPicker"
import Calendar from "./widget/calendar/Calendar"
import NotificationCenter from "./widget/notifications/NotificationCenter"
import NotificationPopup from "./widget/notifications/NotificationPopup"
import AudioMixer from "./widget/audiomixer/AudioMixer"
import AudioMixerScrim from "./widget/audiomixer/AudioMixerScrim"

app.start({
  css: style,
  main() {
    Clipboard()
    OMenu()
    ObsidianHub()
    WallpaperPicker()
    Calendar()
    NotificationCenter()
    NotificationPopup()
    AudioMixer()
    AudioMixerScrim()
  },
})
