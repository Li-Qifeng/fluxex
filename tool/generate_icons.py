#!/usr/bin/env python3
import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BG_START = (234, 242, 255, 255)
BG_END = (158, 181, 217, 255)
ACCENT_START = (255, 207, 90, 255)
ACCENT_END = (255, 143, 31, 255)
BUBBLE = (34, 49, 74, 255)
FG = (245, 248, 255, 255)
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


def gradient(x, y, start, end, p1, p2):
    x1, y1 = p1
    x2, y2 = p2
    dx, dy = x2 - x1, y2 - y1
    t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)
    t = max(0, min(1, t))
    return tuple(int(start[i] + (end[i] - start[i]) * t + 0.5) for i in range(4))


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
    color = TRANSPARENT
    if rounded_rect(x, y, 0, 0, 1024, 1024, 226):
        color = gradient(x, y, BG_START, BG_END, (110, 80), (900, 940))

    bubble = rounded_rect(x, y, 178, 135, 846, 669, 100)
    tail = point_in_poly(x, y, [(314, 817), (248, 669), (434, 669)])
    if bubble or tail:
        color = BUBBLE

    bolt = [(306, 297), (511, 297), (416, 513), (534, 513), (348, 751), (405, 575), (278, 575)]
    if point_in_poly(x, y, bolt):
        color = FG

    if rounded_rect(x, y, 548, 297, 810, 537, 56):
        color = gradient(x, y, ACCENT_START, ACCENT_END, (560, 320), (820, 560))
    if rounded_rect(x, y, 617, 359, 791, 401, 0) or rounded_rect(x, y, 617, 440, 735, 482, 0):
        color = BUBBLE
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
