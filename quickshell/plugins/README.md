# Plugins do Quickshell

Este diretório (`~/.config/quickshell/plugins/`) é onde plugins instalados
vivem, um por subpasta. O shell descobre o que tem aqui (via
`Modules/Plugins/PluginService.qml`) e integra automaticamente com base num
arquivo `plugin.json` que cada plugin declara.

Tem um plugin de exemplo aqui - leia o código, está bem comentado:

- **`window-example/`** - abre uma janela de verdade (`PanelWindow`)
  estilizada com o tema do shell, com um ícone próprio na sidebar
  (`sidebar.component`) que liga/desliga essa janela via IPC. Foca em
  `main` + `sidebar.component` + integração de tema; não declara
  `settingsPage` nem `testScript`.

## Instalando um plugin

Clone ou baixe a pasta do plugin pra dentro de `~/.config/quickshell/plugins/`
(o nome da pasta não precisa bater com o `"id"` do manifesto, mas é bom
prática). Depois abra as Configurações do shell, vá na aba **Plugins** e
clique em **Atualizar** - a descoberta de plugins não é reativa de propósito
(instalar plugin é uma ação rara e deliberada, não precisa de polling
constante no disco). Editar arquivos de um plugin já instalado, por outro
lado, recarrega sozinho (mesmo comportamento hot-reload de qualquer QML do
shell) - só instalar/remover a PASTA de um plugin exige clicar Atualizar.

## O manifesto (`plugin.json`)

```jsonc
{
    "id": "meu-plugin",              // obrigatório, único entre os plugins instalados
    "name": "Meu Plugin",            // opcional, mostrado na aba Plugins (fallback: id)
    "version": "0.1.0",              // opcional, só exibição
    "description": "...",            // opcional, só exibição
    "main": "Main.qml",              // opcional - ver "main" abaixo
    "sidebar": { "component": "SidebarButton.qml" }, // opcional - ver "sidebar" abaixo
    "settingsPage": "SettingsPage.qml", // opcional - ver "settingsPage" abaixo
    "testScript": "test.sh"          // opcional - ver "testScript" abaixo
}
```

Só `"id"` é obrigatório. Um plugin pode declarar qualquer subconjunto dos
outros campos - um plugin só de sidebar, ou só de settings, ou só de IPC em
segundo plano, todos são válidos.

### `main`

Um arquivo QML carregado **permanentemente** assim que o plugin é
descoberto e está ligado (Switch "on" na aba Plugins) - o mesmo tratamento
que `Sidebar{}`, `PowerMenu{}`, `DashboardWindow{}` recebem nativamente em
`shell.qml`. É aqui que mora:

- Um `IpcHandler` (não existe um campo `"ipc": true` separado no manifesto -
  se o plugin quer IPC, só bota um `IpcHandler` dentro do `main` que o
  Quickshell registra sozinho).
- Timers, `Process`es de fundo, e qualquer estado que precisa sobreviver
  enquanto o shell roda.
- Se o plugin abre uma janela (`PanelWindow`/`FloatingWindow`), normalmente
  é aqui também - ver `window-example/Main.qml`.

### `sidebar.component`

Um ícone próprio na barra lateral (`Modules/Sidebar/Sidebar.qml`). O
componente carregado é responsável por desenhar a si mesmo do tamanho de um
`IconButton` comum (cabe numa coluna de 56px).

**Importante**: ligar o plugin (Switch na aba Plugins) **não** liga o ícone
na sidebar sozinho. O usuário escolhe isso à parte, na aba **Sidebar** das
Configurações, onde aparece uma linha por plugin que declarou
`sidebar.component` - desligada por padrão. Instalar/ligar um plugin não
deve mudar a sidebar sem o usuário pedir.

Uma vez ligado, o ícone do plugin também ganha os mesmos controles dos
itens nativos da sidebar, na mesma linha: em qual terço da coluna ele fica
(topo/centro/rodapé) e a ordem dele dentro desse grupo (setas ▲▼). Isso é
inteiramente gerenciado pelo shell a partir do `"id"` do plugin - não
existe (nem precisa existir) nenhum campo novo no manifesto pra isso.

### `settingsPage`

Uma página mostrada inline na aba Plugins das Configurações, quando o
usuário clica no ícone de engrenagem do card do plugin. Só é carregada
(`Loader.active`) enquanto expandida - não fica instanciada à toa pra todo
plugin instalado o tempo todo.

### `testScript`

Um script (bash, caminho relativo à pasta do plugin) que a aba Plugins roda
sob demanda quando o usuário clica no botão "play" do card - nunca roda
sozinho. Serve pra o autor do plugin dar um jeito rápido do usuário
verificar se a instalação/integração tá funcionando. Convenção:

- Exit code `0` = passou (a aba mostra um ✓ verde).
- Qualquer outro exit code = falhou (✗ vermelho, e o `stdout`+`stderr`
  combinados aparecem no card como diagnóstico).

Não tem um `testScript` de exemplo no plugin deste diretório no momento -
mas a ideia é o script exercitar o efeito de verdade (ex.: chamar o IPC do
próprio plugin e conferir se o estado esperado mudou), não só checar se o
processo terminou sem erro.

## Como os arquivos de um plugin conversam entre si

Cada campo do manifesto (`main`, `sidebar.component`, `settingsPage`) é
carregado pelo shell através de um `Loader` **separado e independente**. Ou
seja: `Main.qml` e `SidebarButton.qml` do mesmo plugin **não têm nenhuma
referência QML direta um pro outro** - não dá pra simplesmente declarar um
`pragma Singleton` e importar de um arquivo pro outro, porque eles não
formam um módulo QML registrado (`qmldir`), só URLs soltas carregadas via
`Loader.source`.

A ponte entre pedaços do mesmo plugin é a mesma que o resto do shell já usa
entre processos: **IPC + arquivo de estado compartilhado**.

- Ação (ex.: clique no ícone da sidebar) → `Process` local rodando
  `qs ipc call <target> <function>` → cai no `IpcHandler` que mora no
  `main` do plugin.
- Estado que precisa ser lido por mais de um pedaço (ex.: `settingsPage`
  mostrando algo que o `main` calculou) → um `FileView` +
  `JsonAdapter` apontando pro mesmo arquivo em `State/<algo>.json`, cada
  arquivo QML com o seu próprio `FileView` lendo/escrevendo o mesmo path
  (`watchChanges: true` + `onFileChanged: reload()` pro lado que só lê, pra
  atualizar sozinho quando o outro lado escreve).

Ver `window-example/Main.qml` + `window-example/SidebarButton.qml` pro
exemplo completo da parte de IPC (clique no ícone da sidebar → `Process`
→ `IpcHandler` no `main`). O lado do arquivo de estado compartilhado não
tem um exemplo próprio de plugin neste diretório no momento, mas é o
mesmo padrão `FileView` + `JsonAdapter` que os singletons do core usam
entre si (ex. `State/DockConfig.qml`, `State/SidebarConfig.qml`).

## Tema do shell (`qs.Theme`)

Qualquer arquivo QML de um plugin pode `import qs.Theme` e usar o singleton
`Styles` exatamente como um módulo nativo do shell faria - mesmo sendo
carregado de fora da árvore do shell (a resolução de imports é pelo caminho
configurado no engine QML, não pela pasta de onde o arquivo veio).

```qml
import qs.Theme

Rectangle {
    radius: Styles.radiusShell
    color: Styles.background
    border.color: Styles.border

    Text {
        color: Styles.foreground
        font.family: Styles.fontFamily
        font.pixelSize: Styles.fontSizeNormal
    }
}
```

`Styles` lê `State/colors.json` por baixo dos panos e reage sozinho quando
o usuário troca de wallpaper (matugen) ou personaliza cores em
Configurações > Aparência - um plugin usando `Styles.algumaCoisa` ganha essa
atualização em tempo real de graça, sem precisar de nenhum código extra.
Ver `window-example/Main.qml` pra um exemplo completo com janela.

`import qs.Widgets` também funciona (dá pra reusar `IconButton`, `Button`,
`Switch`, etc. em vez de reinventar), assim como `import qs.State` se o
plugin realmente precisar ler estado do shell - mas evite ESCREVER em
arquivos de estado do core (ex.: `State/sidebar-config.json`) diretamente;
use as funções expostas pelos singletons (ex.: `SidebarConfig.set(...)`) ou,
melhor ainda, guarde o estado do próprio plugin no seu próprio arquivo em
`State/`.

## Sem sandboxing

Um plugin é só QML com o mesmo acesso a `Process`/`Quickshell.execDetached`
que o resto do shell tem - não tem isolamento nenhum, de propósito (mesma
confiança de editar o shell direto, como plugins de nvim/tmux). Só instale
plugin em que você confia.
