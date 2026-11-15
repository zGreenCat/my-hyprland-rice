import app from "ags/gtk4/app"
import style from "./style.scss"
import Clipboard from "./widget/clipboard/Clipboard"
import OMenu from "./widget/omenu/OMenu"
import ObsidianHub from "./widget/obsidian/ObsidianHub"
import WallpaperPicker from "./widget/wallpaper/WallpaperPicker"
import Calendar from "./widget/calendar/Calendar"
import ControlCenter, { CONTROL_WINDOW, showControlCenter } from "./widget/control/ControlCenter"
import NotificationPopup from "./widget/notifications/NotificationPopup"
import Scrim from "./widget/common/Scrim"

app.start({
  css: style,
  requestHandler(argv: string[], res: (response: string) => void) {
    const [command, option] = argv
    if (command === "control") {
      showControlCenter(option === "mixer")
      res("ok")
      return
    }
    res(`comando desconocido: ${argv.join(" ")} (usa: control [mixer])`)
  },
  main() {
    Clipboard()
    OMenu()
    ObsidianHub()
    WallpaperPicker()
    Calendar()
    Scrim("calendar")
    ControlCenter()
    Scrim(CONTROL_WINDOW)
    NotificationPopup()
  },
})
