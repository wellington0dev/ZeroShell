#!/usr/bin/env python3
#
# Picks the two most dominant, sufficiently saturated colors in an image
# that have visibly different hues, then builds the WHOLE shell palette
# (neutros + accent/accentAlt) from them in HLS space - not just accent.
# Used instead of matugen's own Material You roles for every field (see
# quickshell-colors.json) because a Material You scheme only ever samples
# ONE real color from the image (the seed) and derives the rest
# mathematically, which can drift onto hues that aren't actually in the
# picture (e.g. a wallpaper with no cyan at all still getting a cyan
# accent). It also became necessary for the neutros specifically once
# claro/escuro (--mode) foi adicionado: no modo claro, o "background" do
# Material You vira quase branco puro (lightness ~98%, quase sem matiz) -
# no escuro ele preserva bem mais matiz. Pra manter o mesmo "background
# tingido pela cor do wallpaper" nos dois modos, os dois viram a mesma
# fórmula (matiz real da imagem + lightness/saturação alvo), só o alvo
# muda com o modo - não dá pra pedir isso pro matugen mudar sozinho.
#
# Nenhum desses alvos (lightness/saturação) pode morar num filtro do
# template (tipo "set_lightness: N") porque esses filtros só aceitam
# número literal, não variável - não dá pra fazer depender de --mode de
# dentro do template. Por isso a paleta inteira é resolvida aqui, e o
# template (matugen/templates/quickshell-colors.json) só faz passagem
# direta dos hex já prontos.
#
# Usage:
#   extract-colors.py <path-to-image> [dark|light] [scheme-type]

import colorsys
import json
import sys

from PIL import Image

MIN_SATURATION = 0.2
MIN_LIGHTNESS = 0.1
MAX_LIGHTNESS = 0.9
MIN_HUE_DISTANCE = 0.08  # 0..0.5, fraction of the hue wheel

# Multiplicador de saturação por "--type" do matugen (Estilo de cor, ver
# WallpaperGrid.qml/apply-theme.sh) - desde que fundo/superfície/accent
# passaram a vir INTEIRAMENTE daqui (Python) em vez dos papéis nativos do
# matugen, o "--type" sozinho parou de ter QUALQUER efeito visível (só
# ainda mexia em danger/success, que o resto do shell mal usa) - o "Estilo
# de cor" tinha virado, na prática, 9 botões que faziam a mesma coisa.
# Fix: aplica o "--type" escolhido como um multiplicador na saturação alvo
# de TONES abaixo (neutros e accent) - não são os algoritmos reais de cada
# scheme do Material You (isso ficaria só no matugen), só uma aproximação
# usando o eixo que mais salta aos olhos (de "monochrome" quase cinza até
# "vibrant" bem saturado).
SCHEME_SATURATION = {
    "scheme-monochrome": 0.05,
    "scheme-neutral": 0.55,
    "scheme-tonal-spot": 0.75,
    "scheme-content": 0.85,
    "scheme-fidelity": 0.85,
    "scheme-expressive": 1.05,
    "scheme-fruit-salad": 1.15,
    "scheme-rainbow": 1.15,
    "scheme-vibrant": 1.3,
}

# Escala de tom por papel - (lightness, saturação) alvo, calibrada pra
# bater com o visual que já existia (Material You dark) e espelhada pro
# claro. "accent"/"accentAlt" ficam bem mais saturados que os neutros de
# propósito (são o destaque; os neutros são só o "pano de fundo" tingido).
#
# A saturação em HLS perde força visual perto dos extremos de lightness
# (perto de 0 = preto, perto de 1 = branco - o range de R/G/B possível
# encolhe conforme se aproxima de qualquer um dos dois, então o MESMO
# número de saturação fica bem menos perceptível lá do que em L~50%).
# Por isso os alvos de saturação aqui são bem mais altos do que pareceriam
# necessários à primeira vista, e o lightness do fundo/superfície não vai
# tão perto do 0/1 quanto o visual final sugere - dá o "respiro" que a
# saturação precisa pra aparecer de verdade.
TONES = {
    "dark": {
        "background": (0.10, 0.55), "surface": (0.14, 0.50), "surfaceAlt": (0.19, 0.42),
        "border": (0.30, 0.30), "foregroundMuted": (0.62, 0.25), "foreground": (0.90, 0.10),
        "accent": (0.80, None), "accentAlt": (0.80, None),
    },
    "light": {
        "background": (0.88, 0.55), "surface": (0.82, 0.48), "surfaceAlt": (0.76, 0.40),
        "border": (0.60, 0.30), "foregroundMuted": (0.38, 0.25), "foreground": (0.14, 0.10),
        "accent": (0.35, None), "accentAlt": (0.35, None),
    },
}


def hue_distance(a, b):
    d = abs(a - b) % 1.0
    return min(d, 1.0 - d)


def dominant_hues(path, count=2):
    img = Image.open(path).convert("RGB")
    img.thumbnail((150, 150))
    quantized = img.quantize(colors=32, method=Image.Quantize.MEDIANCUT)
    palette = quantized.getpalette()
    ranked = sorted(quantized.getcolors(), reverse=True)

    picks = []
    for _count, idx in ranked:
        r, g, b = palette[idx * 3:idx * 3 + 3]
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        if s < MIN_SATURATION or l < MIN_LIGHTNESS or l > MAX_LIGHTNESS:
            continue
        if any(hue_distance(h, ph) < MIN_HUE_DISTANCE for ph, _ in picks):
            continue
        picks.append((h, (r, g, b)))
        if len(picks) >= count:
            break
    return [rgb for _h, rgb in picks]


def main():
    path = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "dark"
    scheme = sys.argv[3] if len(sys.argv) > 3 else "scheme-neutral"
    tones = TONES[mode if mode == "light" else "dark"]
    sat_scale = SCHEME_SATURATION.get(scheme, 1.0)

    colors = dominant_hues(path, count=2)

    # Not enough distinct hues in the image - reuse whatever was found so the
    # template still gets a color, just without a guaranteed hue difference.
    while len(colors) < 2:
        colors.append(colors[0] if colors else (128, 128, 128))

    hue1, _l, sat1 = colorsys.rgb_to_hls(*(c / 255 for c in colors[0]))
    hue2, _l, sat2 = colorsys.rgb_to_hls(*(c / 255 for c in colors[1]))

    def to_hex(hue, sample_sat, target_lightness, target_sat):
        s = sample_sat if target_sat is None else target_sat
        s = max(0.0, min(0.95, s * sat_scale))
        r, g, b = colorsys.hls_to_rgb(hue, target_lightness, s)
        return "#{:02x}{:02x}{:02x}".format(round(r * 255), round(g * 255), round(b * 255))

    # Todos os neutros vêm do matiz da PRIMEIRA cor dominante (hue1) - um
    # matiz só pra fundo/superfície/borda/texto, pra ficarem visivelmente
    # da mesma família de cor entre si. accent/accentAlt continuam usando
    # cada um o seu próprio matiz sampleado (hue1/hue2).
    palette = {}
    for role in ("background", "surface", "surfaceAlt", "border", "foregroundMuted", "foreground"):
        l, s = tones[role]
        palette[role] = to_hex(hue1, sat1, l, s)

    accent_l, accent_s = tones["accent"]
    accent1 = to_hex(hue1, sat1, accent_l, accent_s)
    accent2 = to_hex(hue2, sat2, accent_l, accent_s)

    # Top-level keys, not nested under "colors": matugen's template renderer
    # only merges --import-json-string into the live "colors.*" namespace for
    # --json/--dump-json output, not for actual template rendering.
    result = {"wallAccent1": {"color": accent1}, "wallAccent2": {"color": accent2}}
    for role, hexval in palette.items():
        result["wall" + role[0].upper() + role[1:]] = {"color": hexval}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
