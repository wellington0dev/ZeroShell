#!/usr/bin/env python3
#
# Finds a dominant color in an image whose hue is distinct from the image's
# single most dominant color (which matugen already uses as its source_color).
# Prints it as matugen --import-json-string input, so a second real wallpaper
# color can be injected as colors.wallAccent2 alongside matugen's own roles.
#
# Usage:
#   extract-colors.py <path-to-image>

import colorsys
import json
import sys

from PIL import Image

MIN_SATURATION = 0.2
MIN_LIGHTNESS = 0.1
MAX_LIGHTNESS = 0.9
MIN_HUE_DISTANCE = 0.08  # 0..0.5, fraction of the hue wheel


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
    colors = dominant_hues(path, count=2)

    # Not enough distinct hues in the image - reuse whatever was found so the
    # template still gets a color, just without a guaranteed hue difference.
    while len(colors) < 2:
        colors.append(colors[0] if colors else (128, 128, 128))

    r, g, b = colors[1]
    hexval = "#{:02x}{:02x}{:02x}".format(r, g, b)
    # Top-level key, not nested under "colors": matugen's template renderer
    # only merges --import-json-string into the live "colors.*" namespace for
    # --json/--dump-json output, not for actual template rendering.
    print(json.dumps({"wallAccent2": {"color": hexval}}))


if __name__ == "__main__":
    main()
