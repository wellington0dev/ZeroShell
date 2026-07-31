#!/usr/bin/env bash
#
# Lista os plugins instalados em ~/.config/quickshell/plugins/<id>/ - cada
# pasta com um "plugin.json" válido vira um item de um array JSON impresso
# na saída padrão (usado por Modules/Plugins/PluginService.qml). O campo
# "dir" (caminho absoluto da pasta) é injetado em cada manifesto - o próprio
# plugin.json não precisa (nem devia) saber onde foi instalado.
#
# Pasta sem plugin.json é ignorada silenciosamente (pode ser lixo/pasta
# incompleta). plugin.json inválido (JSON quebrado) é ignorado com um aviso
# em stderr, não derruba o scan inteiro.
#
# Usage: scan-plugins.sh <pasta-de-plugins>

set -euo pipefail

plugins_dir="${1:?Uso: $(basename "$0") <pasta-de-plugins>}"

python3 -c "
import json
import os
import sys

plugins_dir = sys.argv[1]
result = []

if os.path.isdir(plugins_dir):
    for name in sorted(os.listdir(plugins_dir)):
        pdir = os.path.join(plugins_dir, name)
        manifest_path = os.path.join(pdir, 'plugin.json')
        if not os.path.isdir(pdir) or not os.path.isfile(manifest_path):
            continue
        try:
            with open(manifest_path, encoding='utf-8') as f:
                manifest = json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            print(f'aviso: plugin.json inválido em {pdir}: {e}', file=sys.stderr)
            continue
        if not isinstance(manifest, dict) or not manifest.get('id'):
            print(f'aviso: plugin.json sem \"id\" em {pdir}', file=sys.stderr)
            continue
        manifest['dir'] = pdir
        result.append(manifest)

print(json.dumps(result))
" "$plugins_dir"
