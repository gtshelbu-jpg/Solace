"""Impala's background is a selection/input fill, not the terminal background."""

import re


def rgb(color):
    if not isinstance(color, str) or not re.fullmatch(r"#[a-fA-F0-9]{6}", color):
        raise ValueError("Expected a six-digit palette color")
    return tuple(int(color[i:i+2], 16) for i in (1, 3, 5))


def luminance(color):
    channels = [value / 255 for value in rgb(color)]
    channels = [value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4 for value in channels]
    return sum(value * weight for value, weight in zip(channels, (0.2126, 0.7152, 0.0722)))


def contrast(a, b):
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def selection_color(palette):
    background, foreground, accent = (palette[key] for key in ("background", "foreground", "accent"))
    base = rgb(background)
    def blends(color):
        target = rgb(color)
        return ["#" + "".join(f"{round(a + (b - a) * step / 100):02x}" for a, b in zip(base, target))
                for step in range(100, -1, -1)]
    tinted = blends(accent)
    neutral = blends(foreground)
    # Prefer a recognizable accent, readable text, and a clearly distinct row.
    for separation in (3.0, 2.0):
        for candidate in tinted + neutral:
            if contrast(candidate, foreground) >= 4.5 and contrast(candidate, background) >= separation:
                return candidate
    # A low-contrast source palette may make both targets impossible. Choose the
    # best compromise rather than making a false accessibility guarantee.
    return max(tinted + neutral, key=lambda color: min(contrast(color, foreground) / 4.5,
                                                       contrast(color, background) / 3.0))


if __name__ == "__main__":
    import sys
    import tomllib
    with open(sys.argv[1], "rb") as handle:
        print(selection_color(tomllib.load(handle)))
