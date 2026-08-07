# ZeroShell

ZeroShell é um shell desktop para Hyprland construído com
[Quickshell](https://quickshell.outfoxxed.me/), ainda em desenvolvimento.
O objetivo do projeto é ser extremamente personalizável: cores geradas a
partir do wallpaper (via matugen), raio de canto configurável por
categoria, itens da sidebar ligáveis/desligáveis um a um, e um sistema de
plugins pra estender o shell sem precisar editar o núcleo dele.

## Funcionalidades

- **Sidebar** - foto de perfil, workspaces, apps em segundo plano, relógio,
  bateria, atalho de captura de tela e o menu de energia, cada um
  ligável/desligável nas Configurações, com posição (topo/centro/rodapé) e
  ordem dentro do grupo configuráveis também.
- **Dock** de aplicativos, flutuante e ancorado embaixo (não reserva
  espaço na tela). Mistura apps fixados (escolhidos em Configurações > aba
  "Dock") com apps rodando não-fixados, que aparecem emprestado enquanto a
  janela existir.
- **Notificações** - popups + histórico persistido, consultável na aba
  "Início" do Dashboard mesmo depois do popup sumir.
- **Launcher** de aplicativos.
- **Dashboard** com 4 abas: Início (relógio, foto, notificações), Player
  (controle de mídia via MPRIS), Sistema (CPU/RAM/temperatura/rede/bateria)
  e Ajustes (toggles rápidos).
- **Captura de tela** - menu com escolha de região/janela/tela cheia, ou um
  picker num gesto só nos atalhos de teclado (clique numa janela = só ela,
  clique fora = tela cheia, clique e arrasta = região livre), inspirado no
  areapicker do Caelestia (ver Créditos).
- **Lockscreen própria**, via `ext-session-lock` do Wayland, com senha
  conferida por PAM (não é o hyprlock).
- **Player** de mídia (MPRIS) e painel de **volume** com slide pela borda.
- **Menu de energia** (bloquear, sair, suspender, reiniciar, desligar).
- **Central de Configurações** com abas de Wi-Fi, Bluetooth, Áudio,
  Aparência, Captura, Sidebar, Plugins e Dock.
- **Temas de cor** - dentro de Aparência, a aba "Cores do wallpaper" gera a
  paleta inteira (fundo/superfície/borda/texto/accent) a partir das cores
  dominantes do wallpaper atual, com "Estilo de cor" (9 algoritmos do
  matugen, de Monochrome a Vibrant) e modo Claro/Escuro escolhíveis. A aba
  "Personalizar" cobre o resto: ajuste manual cor por cor, temas prontos
  (Tokyo Night, Catppuccin, Nord, Gruvbox Dark) e o botão pra voltar às
  cores do wallpaper.
- **Sistema de plugins** - instale plugins de terceiros sem editar o
  núcleo do shell (ver seção própria abaixo).
- **Wallpaper renderizado pelo próprio shell** - sem daemon externo
  (`awww`/`swww`): o quickshell desenha a imagem direto como parte da
  árvore de UI, com recuo e cantos arredondados de verdade configuráveis em
  Configurações > Wallpaper, e crossfade na troca. matugen continua
  responsável só pela extração de cor.

Tudo documentado com comentários no próprio código explicando o "porquê"
das decisões, não só o "o quê".

## Dependências e instalação

O setup foi feito pra Arch Linux (ou derivada), já que a instalação usa
`pacman`. Pacotes instalados por `install.sh`:

- `hyprland` - compositor
- `quickshell` - o shell em si (`qs`), usado no autostart e em toda a interface
  (também renderiza o wallpaper, sem daemon externo)
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
git clone https://github.com/wellington0dev/ZeroShell.git ~/ZeroShell
cd ~/ZeroShell
./install.sh
```

`install.sh` instala os pacotes acima e copia (não symlinka) as pastas de
configuração (`hypr`, `quickshell`, `kitty`, `matugen`) e os scripts do
próprio setup (`install.sh`, `update.sh`, `dirs.sh`, `README.md`) de
`~/ZeroShell` pra `~/.config` - tudo com base nos arrays declarados em
`dirs.sh`. Sendo cópia de verdade, `~/.config` fica independente do clone
depois de instalado (dá pra até apagar `~/ZeroShell`). Se já existir algo
com o mesmo nome em `~/.config`, o instalador faz backup antes de
sobrescrever.

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
um plugin de exemplo comentado (`window-example`).

## Créditos

Inspirado por outros shells de Hyprland/Quickshell da comunidade:

- [Caelestia](https://github.com/caelestia-dots/caelestia)
- [illogical-impulse](https://github.com/end-4/dots-hyprland)
- [Ambxst](https://github.com/Axenide/Ambxst)