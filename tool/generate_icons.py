#!/usr/bin/env python3
import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BG = (28, 28, 30, 255)
FG = (240, 240, 243, 255)
ACCENT = (255, 176, 3, 255)
DARK = (28, 28, 30, 255)
TRANSPARENT = (0, 0, 0, 0)


def blend(dst, src):
    sa = src[3] / 255
    da = dst[3] / 255
    out_a = sa + da * (1 - sa)
    if out_a == 0:
        return TRANSPARENT
    return tuple(
        int((src[i] * sa + dst[i] * da * (1 - sa)) / out_a + 0.5)
        for i in range(3)
    ) + (int(out_a * 255 + 0.5),)


def write_png(path, width, height, pixels):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(pixels[y * width + x])

    def chunk(kind, data):
        return (
            struct.pack('>I', len(data))
            + kind
            + data
            + struct.pack('>I', zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
    png += chunk(b'IEND', b'')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def point_in_poly(x, y, points):
    inside = False
    px, py = points[-1]
    for cx, cy in points:
        if ((cy > y) != (py > y)) and (x < (px - cx) * (y - cy) / (py - cy + 1e-9) + cx):
            inside = not inside
        px, py = cx, cy
    return inside


def rounded_rect(x, y, left, top, right, bottom, radius):
    if x < left or x > right or y < top or y > bottom:
        return False
    if left + radius <= x <= right - radius or top + radius <= y <= bottom - radius:
        return True
    for cx, cy in ((left + radius, top + radius), (right - radius, top + radius), (left + radius, bottom - radius), (right - radius, bottom - radius)):
        if (x - cx) ** 2 + (y - cy) ** 2 <= radius ** 2:
            return True
    return False


def logo_pixel(px, py, size):
    scale = size / 1024
    x, y = px / scale, py / scale
    cx, cy = 512, 512
    if (x - cx) ** 2 + (y - cy) ** 2 > 512 ** 2:
        return TRANSPARENT

    color = BG
    bubble = rounded_rect(x, y, 255, 226, 769, 638, 80)
    tail = point_in_poly(x, y, [(343, 624), (337, 758), (470, 638)])
    if bubble or tail:
        color = FG

    bolt = [(347, 349), (501, 349), (429, 511), (518, 511), (379, 689), (421, 557), (326, 557)]
    if point_in_poly(x, y, bolt):
        color = DARK

    if rounded_rect(x, y, 537, 349, 733, 527, 40):
        color = ACCENT
    if rounded_rect(x, y, 584, 393, 728, 428, 0) or rounded_rect(x, y, 584, 460, 680, 495, 0):
        color = DARK
    return color


def render(size):
    pixels = []
    samples = 3
    for y in range(size):
        for x in range(size):
            accum = [0, 0, 0, 0]
            for sy in range(samples):
                for sx in range(samples):
                    c = logo_pixel(x + (sx + 0.5) / samples, y + (sy + 0.5) / samples, size)
                    for i in range(4):
                        accum[i] += c[i]
            pixels.append(tuple(v // (samples * samples) for v in accum))
    return pixels


def make_png(path, size):
    write_png(ROOT / path, size, size, render(size))


def make_ico(path):
    sizes = [16, 32, 48, 64, 128, 256]
    images = []
    for size in sizes:
        pixels = render(size)
        raw = bytearray()
        for y in range(size):
            raw.append(0)
            for x in range(size):
                raw.extend(pixels[y * size + x])
        def chunk(kind, data):
            return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xFFFFFFFF)
        png = b'\x89PNG\r\n\x1a\n'
        png += chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0))
        png += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
        png += chunk(b'IEND', b'')
        images.append((size, png))

    header = struct.pack('<HHH', 0, 1, len(images))
    offset = 6 + 16 * len(images)
    entries = bytearray()
    body = bytearray()
    for size, png in images:
        width = 0 if size == 256 else size
        height = 0 if size == 256 else size
        entries.extend(struct.pack('<BBBBHHII', width, height, 0, 0, 1, 32, len(png), offset))
        body.extend(png)
        offset += len(png)
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(header + entries + body)


def ios_icon_size(item):
    size = float(item['size'].split('x')[0])
    scale = int(item['scale'].rstrip('x'))
    return int(size * scale)


def main():
    make_png('web/favicon.png', 16)
    make_png('web/icons/Icon-192.png', 192)
    make_png('web/icons/Icon-maskable-192.png', 192)
    make_png('web/icons/Icon-512.png', 512)
    make_png('web/icons/Icon-maskable-512.png', 512)

    for folder, size in {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }.items():
        make_png(f'android/app/src/main/res/{folder}/ic_launcher.png', size)

    ios_json = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'
    for item in json.loads(ios_json.read_text())['images']:
        make_png(f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{item['filename']}", ios_icon_size(item))

    for size in [16, 32, 64, 128, 256, 512, 1024]:
        make_png(f'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{size}.png', size)

    make_ico('windows/runner/resources/app_icon.ico')


if __name__ == '__main__':
    main()
