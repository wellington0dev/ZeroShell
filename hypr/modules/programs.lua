---------------------
---- MY PROGRAMS ----
---------------------

-- Comandos usados pelos keybindings (modules/keybindings.lua).
return {
    terminal    = "kitty",
    fileManager = "dolphin",
    browser     = "firefox",
    menu        = "qs ipc call launcher toggle",         -- quickshell's own app launcher, replaces rofi
    captureMenu = "qs ipc call capture toggle",           -- menu de captura/gravação de tela (só pela sidebar agora)
    captureAuto = "qs ipc call capture screenshotAuto",   -- captura: clique=janela, fora=tela cheia, arrasta=região
    recordAuto  = "qs ipc call capture recordAuto",       -- mesmo esquema do de cima, pra gravação
    settingsWin = "qs ipc call settings toggle",           -- janela de Configurações
}
