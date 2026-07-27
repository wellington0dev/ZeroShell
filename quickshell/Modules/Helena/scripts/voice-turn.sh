#!/usr/bin/env bash
#
# Faz um "turno" completo do chat de voz com a Helena: sobe o áudio gravado
# (POST /media/upload), manda como mensagem pedindo resposta em áudio
# (POST /messages com voice_reply=true) e, se a resposta trouxer áudio, baixa
# pro disco. Imprime um JSON com a resposta da API + o caminho local do áudio
# de resposta (ou null) na saída padrão, pra quem chamou (VoiceService.qml)
# só precisar ler stdout.
#
# Uso: voice-turn.sh <base_url> <token> <arquivo_gravado> <dir_downloads>

set -euo pipefail

base_url="${1:?Uso: $(basename "$0") <base_url> <token> <arquivo> <dir_downloads>}"
token="${2:?}"
audio_file="${3:?}"
download_dir="${4:?}"

auth=(-H "Authorization: Bearer $token")

upload=$(curl -sf -X POST "$base_url/media/upload" "${auth[@]}" -F "file=@$audio_file")
media_url=$(echo "$upload" | jq -r '.media_url')

response=$(curl -sf -X POST "$base_url/messages" "${auth[@]}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg url "$media_url" '{media_url: $url, media_type: "audio", voice_reply: true}')")

# Pega a primeira resposta que veio em áudio (se houver) e baixa pro disco -
# o GET /media/... exige o mesmo Bearer token, por isso não dá pra só tocar
# a URL direto num player. media_url vem "cru" (ex.: "1/arquivo.wav", sem
# barra na frente nem prefixo "/media/") - o endpoint de download é
# GET /media/<media_url> (confirmado testando contra o servidor real).
audio_reply_url=$(echo "$response" | jq -r '[.replies[]? | select(.media_type == "audio")][0].media_url // empty')

audio_reply_file=""
if [ -n "$audio_reply_url" ]; then
    mkdir -p "$download_dir"
    audio_reply_file="$download_dir/reply_$(date +%s).wav"
    curl -sf "$base_url/media/$audio_reply_url" "${auth[@]}" -o "$audio_reply_file"
fi

echo "$response" | jq --arg f "$audio_reply_file" '. + {audio_reply_file: ($f | select(. != "") // null)}'
