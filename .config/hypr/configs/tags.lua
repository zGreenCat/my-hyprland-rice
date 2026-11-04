hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia_video" })

hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager|org\\.gnome\\.FileRoller)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(org\\.gnome\\.DiskUtility|wihotspot(-gui)?)$" }, tag = "+settings" })

hl.window_rule({ match = { class = "^(org\\.gnome\\.SystemMonitor)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Evince)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(eog|org\\.gnome\\.Loupe)$" }, tag = "+viewer" })

-- Fijar workspaces 1-5 al monitor de la laptop y 6-10 al externo
for ws = 1, 10 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = ws <= 5 and "eDP-1" or "HDMI-A-1" })
end
