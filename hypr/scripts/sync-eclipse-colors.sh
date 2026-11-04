#!/usr/bin/env bash
#
# Sincroniza as cores do Eclipse IDE com o tema do Quickshell.
#
# Fonte (uma fonte de verdade só - nada de paleta paralela):
#   ~/.config/quickshell/State/colors.json        (paleta)
#   ~/.config/quickshell/State/theme-mode.json    (claro/escuro = colorMode)
#
# Alvo (escopo de instância, ou seja, preferências do WORKSPACE):
#   <workspace>/.metadata/.plugins/org.eclipse.core.runtime/.settings/
#       org.eclipse.ui.editors.prefs          cores base de todo editor de texto
#       org.eclipse.jdt.ui.prefs              realce de sintaxe Java
#       org.eclipse.debug.ui.prefs            console
#       org.eclipse.wst.html.ui.prefs         editor HTML   (WTP/SSE)
#       org.eclipse.wst.xml.ui.prefs          editor XML    (WTP/SSE)
#       org.eclipse.wst.css.ui.prefs          editor CSS    (WTP/SSE)
#       org.eclipse.wst.jsdt.ui.prefs         editor JavaScript (JSDT)
#       org.eclipse.e4.ui.css.swt.theme.prefs tema claro/escuro da interface
#
# O que NÃO é sincronizado (ver mensagem final do script):
#   - as cores da "cara" do Eclipse (toolbars, views, abas, diálogos): vêm do
#     tema CSS e4_dark/e4_default, registrado por plugin. Trocar a paleta
#     exigiria instalar um plugin de tema - este script não instala nada.
#   - editores do Wild Web Developer (LSP): os tokens seguem o tema do tm4e.
#
# Formato das preferências (comprovado nos JARs da instalação):
#   - RGB do JFace ("r,g,b") para ui.editors/jdt.ui/debug.ui/jsdt.ui
#   - "#RRGGBB | null | false" (estilo empacotado do SSE) para html/xml/css
#
# Uso:
#   sync-eclipse-colors.sh [--workspace DIR] [--dry-run] [--force]
#                          [--restore [DIR]]
#
#   --workspace DIR   força o workspace (padrão: o último usado pelo Eclipse)
#   --dry-run         mostra o que mudaria, sem escrever nem fazer backup
#   --force           escreve mesmo com o Eclipse aberto (veja o aviso)
#   --restore [DIR]   restaura um backup (padrão: o mais recente)
#
# Variáveis de ambiente (úteis para teste):
#   ECLIPSE_HOME       diretório da instalação (padrão: dir do `eclipse` no PATH)
#   ECLIPSE_WORKSPACE  mesmo que --workspace
#   COLORS_FILE        paleta alternativa (padrão: ~/.config/quickshell/State/colors.json)
#   THEME_MODE_FILE    claro/escuro alternativo (padrão: .../State/theme-mode.json)
#
# Códigos de saída:
#   0  sincronizado, ou nada a fazer (Eclipse ausente/nunca iniciado)
#   1  erro real (paleta inválida, workspace quebrado, falha de escrita)
#   2  uso incorreto
#

set -euo pipefail

colors_file="${COLORS_FILE:-$HOME/.config/quickshell/State/colors.json}"
mode_file="${THEME_MODE_FILE:-$HOME/.config/quickshell/State/theme-mode.json}"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/zeroshell/eclipse-colors/backups"

workspace=""
dry_run="no"
force="no"
restore=""

die() {
    echo "sync-eclipse-colors: $*" >&2
    exit 1
}

say() {
    echo "$*"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --workspace)
            [ $# -ge 2 ] || { echo "uso: $(basename "$0") --workspace DIR" >&2; exit 2; }
            workspace="$2"
            shift 2
            ;;
        --dry-run)
            dry_run="yes"
            shift
            ;;
        --force)
            force="yes"
            shift
            ;;
        --restore)
            restore="latest"
            shift
            # DIR é opcional: só consome se não parecer outra opção
            if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then
                restore="$1"
                shift
            fi
            ;;
        -h|--help)
            sed -n '2,50p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "opção desconhecida: $1" >&2
            exit 2
            ;;
    esac
done

command -v python3 >/dev/null 2>&1 || die "python3 não encontrado"

# ============================================================================
#  Localiza a instalação do Eclipse
# ============================================================================

eclipse_home=""
if [ -n "${ECLIPSE_HOME:-}" ]; then
    eclipse_home="$ECLIPSE_HOME"
elif command -v eclipse >/dev/null 2>&1; then
    launcher="$(readlink -f "$(command -v eclipse)")"
    eclipse_home="$(dirname "$launcher")"
fi

if [ -z "$eclipse_home" ] || [ ! -d "$eclipse_home/plugins" ]; then
    # Mesma convenção dos outros sync-*: ausência do app não é erro, para não
    # derrubar a cadeia do apply-theme.sh (set -e).
    say "Eclipse não encontrado, pulando sincronização."
    exit 0
fi

plugins_dir="$eclipse_home/plugins"

eclipse_version="desconhecida"
if [ -f "$eclipse_home/.eclipseproduct" ]; then
    eclipse_version="$(sed -n 's/^version=//p' "$eclipse_home/.eclipseproduct" | head -1)"
fi

# ============================================================================
#  Localiza o workspace (sem assumir que todo mundo usa ~/eclipse-workspace)
# ============================================================================

if [ -z "$workspace" ]; then
    workspace="${ECLIPSE_WORKSPACE:-}"
fi

if [ -z "$workspace" ]; then
    # O Eclipse guarda o último workspace em
    # ~/.eclipse/<plataforma>/configuration/.settings/org.eclipse.ui.ide.prefs
    ide_prefs="$(ls -t "$HOME"/.eclipse/*/configuration/.settings/org.eclipse.ui.ide.prefs 2>/dev/null | head -1 || true)"
    if [ -n "$ide_prefs" ]; then
        workspace="$(python3 - "$ide_prefs" <<'PY'
import sys

# Formato: RECENT_WORKSPACES=/caminho/1\n/caminho/2 (escapado como Properties).
# O primeiro da lista é o último workspace aberto.
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
value = ""
for line in text.splitlines():
    if line.startswith("RECENT_WORKSPACES="):
        value = line[len("RECENT_WORKSPACES="):]
        break

out = []
i = 0
while i < len(value):
    ch = value[i]
    if ch == "\\" and i + 1 < len(value):
        nxt = value[i + 1]
        out.append("\n" if nxt == "n" else ("\t" if nxt == "t" else nxt))
        i += 2
        continue
    out.append(ch)
    i += 1

entries = [e.strip() for e in "".join(out).split("\n") if e.strip()]
print(entries[0] if entries else "")
PY
)"
    fi
fi

if [ -z "$workspace" ]; then
    say "Nenhum workspace do Eclipse encontrado (o Eclipse parece nunca ter sido iniciado), pulando sincronização."
    exit 0
fi

if [ ! -d "$workspace" ]; then
    die "workspace não existe: $workspace"
fi

if [ ! -d "$workspace/.metadata" ]; then
    die "o diretório existe mas não é um workspace do Eclipse (falta .metadata): $workspace"
fi

settings_dir="$workspace/.metadata/.plugins/org.eclipse.core.runtime/.settings"

# ============================================================================
#  Restaurar backup (não mexe em mais nada)
# ============================================================================

if [ -n "$restore" ]; then
    if [ "$restore" = "latest" ]; then
        [ -d "$backup_root" ] || die "nenhum backup em $backup_root"
        restore="$(ls -1d "$backup_root"/*/ 2>/dev/null | sort | tail -1 || true)"
        [ -n "$restore" ] || die "nenhum backup em $backup_root"
    fi

    restore="${restore%/}"
    [ -d "$restore" ] || die "backup não encontrado: $restore"

    count=0
    for f in "$restore"/*.prefs; do
        [ -f "$f" ] || continue
        target="$settings_dir/$(basename "$f")"
        if [ "$dry_run" = "yes" ]; then
            say "(dry-run) restauraria $target"
        else
            mkdir -p "$settings_dir"
            cp -p "$f" "$target"
            say "restaurado: $target"
        fi
        count=$((count + 1))
    done

    [ "$count" -gt 0 ] || die "o diretório de backup não tem nenhum .prefs: $restore"
    say "Backup restaurado de: $restore"
    say "Reinicie o Eclipse para valer."
    exit 0
fi

# ============================================================================
#  Aplica a paleta
# ============================================================================

status=0
python3 - "$colors_file" "$mode_file" "$settings_dir" "$plugins_dir" \
           "$backup_root" "$dry_run" "$workspace" "$eclipse_home" <<'PY' || status=$?
#
# Mapeamento paleta -> Eclipse.
#
# Isto é o coração da integração. Cada chave abaixo foi confirmada na
# instalação local (constantes dos próprios plugins, não documentação chutada):
#
#   ui.editors     org.eclipse.ui.texteditor.AbstractDecoratedTextEditorPreferenceConstants
#                  (lidas pelo Java Editor e pelos editores SSE via
#                  ChainedPreferenceStore; ver StructuredTextEditor)
#   jdt.ui         org.eclipse.jdt.ui.PreferenceConstants (EDITOR_*_COLOR)
#   debug.ui       org.eclipse.debug.ui.PreferenceConstants (console)
#   wst.*.ui       org.eclipse.wst.sse.ui.internal.preferences.ui.ColorHelper
#                  (valor no formato "#RRGGBB | null | false")
#   css.swt.theme  themeid -> org.eclipse.e4.ui.css.theme.e4_dark / e4_default
#
# Onde aparece "surface" num fundo, é o tom imediatamente acima do
# "background" - dá o degrau de contraste sem sair da paleta.
#

import glob
import json
import os
import re
import shutil
import sys
import time

(
    colors_path,
    mode_path,
    settings_dir,
    plugins_dir,
    backup_root,
    dry_run,
    workspace,
    eclipse_home,
) = sys.argv[1:9]

dry_run = dry_run == "yes"

REQUIRED = [
    "background",
    "surface",
    "surfaceAlt",
    "border",
    "foreground",
    "foregroundMuted",
    "accent",
    "accentAlt",
    "danger",
    "success",
]
HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")


def fail(message):
    print(f"sync-eclipse-colors: {message}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Validação da paleta (antes de tocar em qualquer preferência)
# ---------------------------------------------------------------------------

if not os.path.isfile(colors_path):
    fail(f"paleta não encontrada: {colors_path}")

try:
    with open(colors_path, encoding="utf-8") as f:
        palette = json.load(f)
except json.JSONDecodeError as exc:
    fail(f"paleta inválida ({colors_path}): {exc}")

if not isinstance(palette, dict):
    fail(f"paleta inválida ({colors_path}): esperado um objeto JSON")

problems = []
for key in REQUIRED:
    if key not in palette:
        problems.append(f"chave ausente: {key}")
    elif not isinstance(palette[key], str) or not HEX_RE.match(palette[key]):
        problems.append(
            f"valor inválido para {key}: {palette[key]!r} (esperado #RRGGBB)"
        )

if problems:
    fail("paleta inválida:\n  - " + "\n  - ".join(problems))


def rgb(name):
    h = palette[name].lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def rgbv(name):
    """Formato do JFace para cores: 'r,g,b'."""
    return "%d,%d,%d" % rgb(name)


def ssev(name):
    """Formato do SSE (HTML/XML/CSS): '<#RRGGBB> | <background|null> | <bold>'."""
    return f"{palette[name]} | null | false"


# ---------------------------------------------------------------------------
# Claro/escuro: theme-mode.json é a fonte de verdade do shell; a luminância do
# fundo só entra como reserva se o arquivo não existir.
# ---------------------------------------------------------------------------

color_mode = ""
if os.path.isfile(mode_path):
    try:
        with open(mode_path, encoding="utf-8") as f:
            color_mode = (json.load(f).get("colorMode") or "").strip().lower()
    except (json.JSONDecodeError, OSError):
        color_mode = ""

if color_mode not in ("light", "dark"):
    r, g, b = rgb("background")
    luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
    color_mode = "dark" if luminance < 0.5 else "light"

theme_id = (
    "org.eclipse.e4.ui.css.theme.e4_dark"
    if color_mode == "dark"
    else "org.eclipse.e4.ui.css.theme.e4_default"
)

# ---------------------------------------------------------------------------
# Áreas suportadas: chaves por plugin.
# ---------------------------------------------------------------------------

# --- Cores base de qualquer editor de texto (ui.editors) --------------------
# Fundo/texto/seleção/linha atual/números de linha/erros e avisos.
base_editor = [
    ("AbstractTextEditor.Color.Background", rgbv("background")),
    ("AbstractTextEditor.Color.Foreground", rgbv("foreground")),
    # Sem os "*SystemDefault=false" o Eclipse ignora as cores acima.
    ("AbstractTextEditor.Color.Background.SystemDefault", "false"),
    ("AbstractTextEditor.Color.Foreground.SystemDefault", "false"),
    # Seleção invertida (destaque sobre o fundo) - contraste garantido porque
    # accent e background vêm de extremos opostos da paleta.
    ("AbstractTextEditor.Color.SelectionBackground", rgbv("accent")),
    ("AbstractTextEditor.Color.SelectionForeground", rgbv("background")),
    ("AbstractTextEditor.Color.SelectionBackground.SystemDefault", "false"),
    ("AbstractTextEditor.Color.SelectionForeground.SystemDefault", "false"),
    ("AbstractTextEditor.Color.FindScope", rgbv("accentAlt")),
    ("currentLineColor", rgbv("surface")),
    ("lineNumberColor", rgbv("foregroundMuted")),
    ("printMarginColor", rgbv("border")),
    ("matchingBracketsColor", rgbv("accentAlt")),
    ("hyperlinkColor", rgbv("accentAlt")),
    ("hyperlinkColor.SystemDefault", "false"),
    # Marcações na régua/visão geral
    ("errorIndicationColor", rgbv("danger")),
    ("warningIndicationColor", rgbv("accentAlt")),  # paleta não tem "warning"
    ("infoIndicationColor", rgbv("accentAlt")),
    ("taskIndicationColor", rgbv("success")),
    ("bookmarkIndicationColor", rgbv("accent")),
    ("searchResultIndicationColor", rgbv("accentAlt")),
    ("othersIndicationColor", rgbv("foregroundMuted")),
    # Quick diff (comparação com o disco)
    ("changeIndicationColor", rgbv("accentAlt")),
    ("additionIndicationColor", rgbv("success")),
    ("deletionIndicationColor", rgbv("danger")),
]

# --- Java (jdt.ui) --------------------------------------------------------
# Nomes exatos de PreferenceConstants.EDITOR_*_COLOR.
java_editor = [
    ("java_keyword", rgbv("accent")),
    ("java_keyword_return", rgbv("accent")),
    ("java_string", rgbv("success")),
    ("java_single_line_comment", rgbv("foregroundMuted")),
    ("java_multi_line_comment", rgbv("foregroundMuted")),
    ("java_comment_task_tag", rgbv("accent")),
    ("java_method_name", rgbv("accentAlt")),
    ("java_operator", rgbv("foreground")),
    ("java_bracket", rgbv("foregroundMuted")),
    ("java_annotation", rgbv("accentAlt")),
    ("java_default", rgbv("foreground")),
    ("java_doc_keyword", rgbv("accent")),
    ("java_doc_tag", rgbv("accentAlt")),
    ("java_doc_link", rgbv("accentAlt")),
    ("java_doc_default", rgbv("foregroundMuted")),
    # Erro de compilação no editor Java (chave própria do jdt.ui)
    ("problemIndicationColor", rgbv("danger")),
    ("content_assist_proposals_background", rgbv("surface")),
    ("content_assist_proposals_foreground", rgbv("foreground")),
]

# --- Console (debug.ui) ---------------------------------------------------
console = [
    ("org.eclipse.debug.ui.consoleBackground", rgbv("background")),
    ("org.eclipse.debug.ui.outColor", rgbv("foreground")),
    ("org.eclipse.debug.ui.inColor", rgbv("foregroundMuted")),
    ("org.eclipse.debug.ui.errorColor", rgbv("danger")),
]

# --- HTML / XML (WTP, editores SSE) ---------------------------------------
# Valores no formato do ColorHelper ("#RRGGBB | null | false").
markup_editor = [
    ("tagName", ssev("accent")),
    ("tagBorder", ssev("foregroundMuted")),
    ("tagAttributeName", ssev("accentAlt")),
    ("tagAttributeValue", ssev("success")),
    ("tagAttributeEquals", ssev("foregroundMuted")),
    ("commentText", ssev("foregroundMuted")),
    ("commentBorder", ssev("border")),
    ("declBoder", ssev("accentAlt")),  # [sic] o Eclipse escreve "declBoder"
    ("doctypeName", ssev("accentAlt")),
    ("doctypeExternalPubref", ssev("foregroundMuted")),
    ("doctypeExternalId", ssev("foregroundMuted")),
    ("doctypeExtrenalSysref", ssev("success")),  # [sic] também
    ("xmlContent", ssev("foreground")),
    ("piBorder", ssev("accentAlt")),
    ("piContent", ssev("foregroundMuted")),
    ("cdataBorder", ssev("border")),
    ("cdataText", ssev("foreground")),
    ("entityReference", ssev("accentAlt")),
]

# Só o editor HTML tem área de script embutida.
html_only = [("SCRIPT_AREA_BORDER", ssev("border"))]

# --- CSS (WTP) ------------------------------------------------------------
css_editor = [
    ("NORMAL", ssev("foreground")),
    ("SELECTOR", ssev("accent")),
    ("UNIVERSAL", ssev("foregroundMuted")),
    ("CLASS", ssev("accentAlt")),
    ("ID", ssev("accentAlt")),
    ("PSEUDO", ssev("accentAlt")),
    ("COMBINATOR", ssev("foregroundMuted")),
    ("ATMARK_RULE", ssev("accent")),
    ("MEDIA", ssev("foregroundMuted")),
    ("COMMENT", ssev("foregroundMuted")),
    ("PROPERTY_NAME", ssev("accentAlt")),
    ("PROPERTY_VALUE", ssev("success")),
    ("STRING", ssev("success")),
    ("URI", ssev("accentAlt")),
    ("ATTRIBUTE_DELIM", ssev("foregroundMuted")),
    ("ATTRIBUTE_NAME", ssev("accentAlt")),
    ("ATTRIBUTE_OPERATOR", ssev("foregroundMuted")),
    ("ATTRIBUTE_VALUE", ssev("success")),
    ("COLON", ssev("foregroundMuted")),
    ("SEMI_COLON", ssev("foregroundMuted")),
    ("CURLY_BRACE", ssev("foregroundMuted")),
    ("ERROR", ssev("danger")),
]

# --- JavaScript (JSDT; é um fork do JDT, usa as mesmas chaves) ------------
javascript_editor = [
    ("java_keyword", rgbv("accent")),
    ("java_keyword_return", rgbv("accent")),
    ("java_string", rgbv("success")),
    ("javascript_template_literal", rgbv("success")),
    ("java_single_line_comment", rgbv("foregroundMuted")),
    ("java_multi_line_comment", rgbv("foregroundMuted")),
    ("java_method_name", rgbv("accentAlt")),
    ("java_operator", rgbv("foreground")),
    ("java_bracket", rgbv("foregroundMuted")),
    ("java_default", rgbv("foreground")),
    ("java_doc_keyword", rgbv("accent")),
    ("java_doc_tag", rgbv("accentAlt")),
    ("java_doc_default", rgbv("foregroundMuted")),
    ("problemIndicationColor", rgbv("danger")),
]

# --- Tema da interface (claro/escuro) -------------------------------------
interface_theme = [("themeid", theme_id)]

# arquivo .prefs -> (rótulo, jar que precisa existir, chaves)
#
# O jar é o que decide se a área existe nesta instalação: sem ele, a chave não
# é lida por ninguém e escrever seria lixo no workspace.
AREAS = [
    ("org.eclipse.ui.editors.prefs", "cores base do editor", "org.eclipse.ui.editors", base_editor),
    ("org.eclipse.jdt.ui.prefs", "sintaxe Java", "org.eclipse.jdt.ui", java_editor),
    ("org.eclipse.debug.ui.prefs", "console", "org.eclipse.debug.ui", console),
    ("org.eclipse.wst.html.ui.prefs", "editor HTML", "org.eclipse.wst.html.ui", markup_editor + html_only),
    ("org.eclipse.wst.xml.ui.prefs", "editor XML", "org.eclipse.wst.xml.ui", markup_editor),
    ("org.eclipse.wst.css.ui.prefs", "editor CSS", "org.eclipse.wst.css.ui", css_editor),
    ("org.eclipse.wst.jsdt.ui.prefs", "editor JavaScript", "org.eclipse.wst.jsdt.ui", javascript_editor),
    ("org.eclipse.e4.ui.css.swt.theme.prefs", "tema claro/escuro", "org.eclipse.e4.ui.css.swt.theme", interface_theme),
]

VERSION_KEY = "eclipse.preferences.version"
VERSION_VALUE = "1"


# ---------------------------------------------------------------------------
# Leitura/escrita do .prefs preservando tudo o que não é nosso
# ---------------------------------------------------------------------------

def read_prefs(path):
    """Devolve as linhas do arquivo (ou lista vazia se não existir)."""
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8", errors="surrogateescape") as f:
        return f.read().splitlines()


def key_of(line):
    """Chave de uma linha 'chave=valor' (None para comentário/linha vazia)."""
    stripped = line.lstrip()
    if not stripped or stripped[0] in "#!":
        return None
    idx = line.find("=")
    if idx <= 0:
        return None
    return line[:idx].strip()


def merge(lines, pairs):
    """Acrescenta/substitui só as chaves de `pairs`; devolve (linhas, novas, alteradas)."""
    current = {}
    for i, line in enumerate(lines):
        k = key_of(line)
        if k is not None:
            current[k] = (i, line[len(k) + 1 :].strip())

    out = list(lines)
    added = 0
    changed = 0

    if VERSION_KEY not in current:
        out.append(f"{VERSION_KEY}={VERSION_VALUE}")
        added += 1

    for key, value in pairs:
        if key in current and current[key][1] == value:
            continue
        if key in current:
            out[current[key][0]] = f"{key}={value}"
            changed += 1
        else:
            out.append(f"{key}={value}")
            added += 1

    # Um arquivo novo não precisa de linha em branco no fim, mas um existente
    # mantém o formato do Eclipse (uma linha por chave, terminada em \n).
    return out, added, changed


def write_prefs(path, lines):
    tmp = f"{path}.zero-tmp"
    with open(tmp, "w", encoding="utf-8", errors="surrogateescape") as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp, path)


def has_plugin(pattern):
    return bool(glob.glob(os.path.join(plugins_dir, pattern + "_*.jar"))) or os.path.isdir(
        os.path.join(plugins_dir, pattern)
    )


# ---------------------------------------------------------------------------
# Executa
# ---------------------------------------------------------------------------

product_file = os.path.join(eclipse_home, ".eclipseproduct")
version = "?"
if os.path.isfile(product_file):
    for line in open(product_file, encoding="utf-8", errors="replace"):
        if line.startswith("version="):
            version = line.strip().split("=", 1)[1]
print(f"Eclipse {version} ({eclipse_home})")
print(f"Workspace: {workspace}")
print(f"Modo: {'escuro' if color_mode == 'dark' else 'claro'} ({theme_id})")
print()

if not dry_run:
    os.makedirs(settings_dir, exist_ok=True)

stamp = time.strftime("%Y%m%d-%H%M%S")
backup_dir = os.path.join(backup_root, stamp)

touched = 0
skipped_areas = []

for filename, label, plugin, pairs in AREAS:
    path = os.path.join(settings_dir, filename)

    if not has_plugin(plugin):
        skipped_areas.append((label, f"plugin {plugin} não instalado"))
        continue

    lines = read_prefs(path)
    merged, added, changed = merge(lines, pairs)

    if added == 0 and changed == 0:
        print(f"  {filename:<38} sem alterações   ({label})")
        continue

    detail = []
    if added:
        detail.append(f"{added} nova(s)")
    if changed:
        detail.append(f"{changed} alterada(s)")
    detail = ", ".join(detail) or "0"

    if dry_run:
        print(f"  {filename:<38} mudaria: {detail}   ({label})")
        continue

    if os.path.isfile(path):
        os.makedirs(backup_dir, exist_ok=True)
        shutil.copy2(path, os.path.join(backup_dir, filename))

    write_prefs(path, merged)
    print(f"  {filename:<38} {detail:<22} ({label})")
    touched += 1

print()

if touched == 0 and not dry_run:
    print("Nada mudou: as preferências já estavam sincronizadas.")
else:
    if touched and not dry_run:
        print(f"Backup dos arquivos alterados: {backup_dir}")

# Preferências de projeto têm precedência sobre as do workspace (o
# ChainedPreferenceStore do JavaEditor consulta o escopo do projeto primeiro).
overrides = sorted(
    glob.glob(os.path.join(workspace, "*", ".settings", "org.eclipse.jdt.ui.prefs"))
)
if overrides:
    print()
    print("Aviso: estes projetos sobrescrevem as cores do Java com preferências próprias:")
    for path in overrides[:5]:
        print(f"  {os.path.relpath(path, workspace)}")

if skipped_areas:
    print()
    print("Áreas não sincronizadas nesta instalação:")
    for label, reason in skipped_areas:
        print(f"  - {label}: {reason}")

print()
print("Não suportado por preferência (limitação do Eclipse, não do script):")
print("  - barras de ferramentas/views/abas/diálogos: vêm do CSS do tema e4_*;")
print("    recolorir com a paleta exigiria um plugin de tema (não instalamos nada).")
print("  - editores do Wild Web Developer: os tokens seguem o tema do tm4e.")
print("  - menus/diálogos nativos seguem o GTK (já sincronizado por sync-gtk-colors.sh).")
print()
print("Reinicie o Eclipse: os arquivos .prefs só são lidos na inicialização.")
PY

# ============================================================================
#  Eclipse aberto: arquivo de preferência só é lido na inicialização
# ============================================================================
#
# Não é um bloqueio: o arquivo pode ser escrito com o Eclipse aberto, mas a
# instância viva não relê nada. Se o usuário mexer em "Cores e Fontes" com ele
# aberto, o Eclipse grava os valores antigos por cima - daí o aviso (e por isso
# ele vem depois da escrita: se a paleta estiver inválida, nada é escrito e o
# aviso só confundiria).

if [ "$status" -eq 0 ] && [ "$force" != "yes" ]; then
    eclipse_pid="$(pgrep -f 'org\.eclipse\.equinox\.launcher_.*\.jar' | head -1 || true)"
    if [ -n "$eclipse_pid" ]; then
        echo "sync-eclipse-colors: o Eclipse está aberto (pid $eclipse_pid)." >&2
        say "As cores só aparecem depois de reiniciar o Eclipse; até lá evite aplicar cores"
        say "em Window > Preferences (o Eclipse gravaria os valores antigos por cima)."
    fi
fi

exit "$status"
