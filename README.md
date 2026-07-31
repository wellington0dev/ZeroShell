# ZeroShell

ZeroShell é um shell desktop para Hyprland construído com
[Quickshell](https://quickshell.outfoxxed.me/), ainda em desenvolvimento.
O objetivo do projeto é ser extremamente personalizável: cores geradas a
partir do wallpaper (via matugen), raio de canto configurável por
categoria, itens da sidebar ligáveis/desligáveis um a um, e um sistema de
plugins pra estender o shell sem precisar editar o núcleo dele.

Sidebar, notificações, launcher, dashboard, player, captura de tela,
lockscreen própria, menu de energia e uma central de configurações fazem
parte do shell nativo - tudo documentado com comentários explicando o
"porquê" das decisões diretamente no código.

## Dependências e instalação

O setup foi feito pra Arch Linux (ou derivada), já que a instalação usa
`pacman`. Pacotes instalados por `install.sh`:

- `hyprland` - compositor
- `quickshell` - o shell em si (`qs`), usado no autostart e em toda a interface
- `awww` - daemon de wallpaper (fork drop-in do swww)
- `matugen` - gera o tema do quickshell a partir do wallpaper
- `python-pillow` - extração de uma segunda cor dominante do wallpaper
- `kitty` - terminal
- `dolphin` - gerenciador de arquivos
- `playerctl` - teclas de mídia
- `wireplumber` - controle de áudio (`wpctl`)
- `brightnessctl` - brilho da tela
- `libnotify` - notificações (`notify-send`)
- `grim` - screenshot
- `cava` - visualização de áudio no terminal
- `ttf-jetbrains-mono-nerd` - fonte usada pelo shell (com os glifos de ícone)
- `python-pam` - autenticação da lockscreen própria

Pra instalar:

```bash
git clone <url-deste-repositório> ~/ZeroShell
cd ~/ZeroShell
./install.sh
```

`install.sh` instala os pacotes acima, symlinka as pastas de configuração
(`hypr`, `quickshell`, `kitty`, `matugen`) de `~/ZeroShell` pra `~/.config`
e copia os scripts do próprio setup (`install.sh`, `update.sh`, `dirs.sh`,
`README.md`) pra lá também - tudo com base nos arrays declarados em
`dirs.sh`.

Depois de mexer na configuração diretamente em `~/.config`, `./update.sh`
copia as mudanças de volta pra `~/ZeroShell` (o caminho inverso), pra
poder commitar.

## Plugins

O shell tem um sistema de plugins: instale um plugin clonando ou baixando
a pasta dele pra dentro de `~/.config/quickshell/plugins/`, e o shell
descobre a integração sozinho a partir de um `plugin.json` que o plugin
declara (ícone na sidebar, IPC, página própria nas Configurações, script
de teste). Tudo isso é opcional e configurável por plugin instalado, na
aba **Plugins** das Configurações.

Quer criar o seu próprio plugin? O guia completo - schema do manifesto,
como as diferentes partes de um plugin se comunicam, como integrar com o
tema do shell - está em
[`quickshell/plugins/README.md`](quickshell/plugins/README.md), junto com
dois plugins de exemplo comentados (`hello-world` e `window-example`).

## Créditos

Inspirado por outros shells de Hyprland/Quickshell da comunidade:

- [`Caelestia`] (https://github.com/caelestia-dots/caelestia)
- [`illogical-impulse`] (https://github.com/end-4/dots-hyprland)
- [`Ambxst`] (https://github.com/Axenide/Ambxst)