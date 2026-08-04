-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
-- hl.on("hyprland.start", function ()
--   hl.exec_cmd(terminal)
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
-- end)

hl.on("hyprland.start", function ()
  hl.exec_cmd("qs")
  hl.exec_cmd("~/.config/hypr/scripts/load-wallpaper.sh")
  -- Helena não é mais um serviço de sistema à parte - o próprio Main.qml do
  -- plugin (plugins/ai-plugin/) sobe e supervisiona local_server.py junto
  -- do quickshell, então não precisa de linha própria aqui.
end)
