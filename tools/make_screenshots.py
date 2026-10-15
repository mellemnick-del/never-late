"""Builds App Store screenshots (1320 x 2868, 6.9" iPhone) for Never Late.

Each image is a headline over a phone screen. By default the phone screen is drawn
by a Python port of DialView.swift and ContentView.swift, so it matches the app.
To use a real screenshot from the phone instead, pass it for that slot:

    python3 tools/make_screenshots.py out_dir [--shot 1=path.png --shot 2=path.png ...]
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '..', 'NeverLate', 'Fonts')
BOLD = os.path.join(FONTS, 'ChakraPetch-Bold.ttf')
MEDIUM = os.path.join(FONTS, 'ChakraPetch-Medium.ttf')
MONO = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
MONO_BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'

W, H = 1320, 2868
SS = 2                      # supersampling
PT = 3 * SS                 # pixels per point on the phone screen

# Theme.swift
BG = (10, 10, 12); DIAL = (7, 7, 8); DIAL_HI = (30, 30, 34)
BURGUNDY = (128, 24, 38); NAVY = (22, 40, 82); GILT = (214, 186, 128)
LUME = (238, 226, 196); LUME_HOT = (255, 248, 226); STEEL = (154, 158, 164)
METAL = (196, 200, 204); METAL_DARK = (110, 114, 120); RED = (224, 72, 63)
PAPER = (242, 240, 234); INK = (11, 11, 12)
TAU = math.pi * 2

_font_cache = {}


def font(path, px):
    key = (path, int(px))
    if key not in _font_cache:
        _font_cache[key] = ImageFont.truetype(path, max(1, int(px)))
    return _font_cache[key]


class Layer:
    """RGBA drawing surface with helpers in pixel units."""

    def __init__(self, w, h, fill=(0, 0, 0, 0)):
        self.img = Image.new('RGBA', (w, h), fill)
        self.d = ImageDraw.Draw(self.img)

    def over(self, other, alpha=1.0):
        src = other.img
        if alpha < 1:
            a = src.getchannel('A').point(lambda v: int(v * alpha))
            src = src.copy(); src.putalpha(a)
        self.img.alpha_composite(src)
        self.d = ImageDraw.Draw(self.img)


def text_size(txt, f, tracking=0):
    if not txt:
        return 0, 0
    width = sum(f.getlength(ch) for ch in txt) + tracking * (len(txt) - 1)
    asc, desc = f.getmetrics()
    return width, asc + desc


def draw_text(layer, cx, cy, txt, f, fill, tracking=0):
    """Draw text centered on (cx, cy) with optional letter spacing."""
    w, _ = text_size(txt, f, tracking)
    x = cx - w / 2
    for ch in txt:
        layer.d.text((x, cy), ch, font=f, fill=fill, anchor='lm')
        x += f.getlength(ch) + tracking


def glow(base, shape_fn, color, radius, strength=1.0):
    g = Layer(*base.img.size)
    shape_fn(g, color + (255,))
    blurred = g.img.filter(ImageFilter.GaussianBlur(radius))
    a = blurred.getchannel('A').point(lambda v: min(255, int(v * strength)))
    blurred.putalpha(a)
    base.img.alpha_composite(blurred)
    base.d = ImageDraw.Draw(base.img)


# ---------------------------------------------------------------- dial (DialView.swift)

def draw_dial(layer, cx, cy, side, s):
    d = layer.d

    def rot(a, x, y):
        return (cx + x * math.cos(a) - y * math.sin(a), cy + x * math.sin(a) + y * math.cos(a))

    def pt(a, r):
        return rot(a, 0, -r)

    def circle(lyr, r, fill, ox=0, oy=0):
        lyr.d.ellipse([cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r], fill=fill)

    def band(r0, r1, a0, a1, n=120):
        return [pt(a0 + (a1 - a0) * i / n, r1) for i in range(n + 1)] + \
               [pt(a1 - (a1 - a0) * i / n, r0) for i in range(n + 1)]

    def along(a, pts):  # (radius, half-width) pairs
        return [rot(a, w, -r) for r, w in pts]

    def rect(a, r0, r1, hw):
        return along(a, [(r0, -hw), (r1, -hw), (r1, hw), (r0, hw)])

    R = side / 2 * 0.97

    # case and knurling
    circle(layer, R, METAL_DARK)
    for i in range(120):
        a = i / 120 * TAU
        d.line([pt(a, R * 0.965), pt(a, R)], fill=METAL, width=max(1, int(1.6 * PT / 2)))
    circle(layer, R * 0.965, METAL)

    bez_out, bez_in = R * 0.95, R * 0.76
    bez_mid, bez_w = (bez_out + bez_in) / 2, bez_out - bez_in
    d.polygon(band(bez_in, bez_out, -math.pi / 2, math.pi / 2), fill=BURGUNDY)
    d.polygon(band(bez_in, bez_out, math.pi / 2, math.pi * 1.5), fill=NAVY)

    f = font(BOLD, bez_w * 0.46 * 1.33)
    for h in range(24):
        a = h / 24 * TAU
        if h == 0:
            d.polygon([rot(a, 0, -bez_in - bez_w * 0.18), rot(a, -bez_w * 0.3, -bez_out + bez_w * 0.16),
                       rot(a, bez_w * 0.3, -bez_out + bez_w * 0.16)], fill=GILT)
        elif h % 2 == 0:
            x, y = pt(a, bez_mid)
            box = int(bez_w * 1.4)
            t = Image.new('L', (box, box), 0)
            ImageDraw.Draw(t).text((box / 2, box / 2), str(h), font=f, fill=255, anchor='mm')
            deg = -math.degrees(a)
            if math.pi / 2 - 0.001 <= a < math.pi * 1.5 - 0.001:
                deg += 180
            t = t.rotate(deg, resample=Image.BICUBIC)
            layer.img.paste(Image.new('RGBA', (box, box), GILT + (255,)), (int(x - box / 2), int(y - box / 2)), t)
            layer.d = d = ImageDraw.Draw(layer.img)
        else:
            x, y = pt(a, bez_mid); r = bez_w * 0.07
            d.ellipse([x - r, y - r, x + r, y + r], fill=GILT)

    # target marker
    if s['show_target']:
        ta, hw = s['target'], s['half_width']
        core = hw * 0.3
        r0, r1 = bez_in + bez_w * 0.06, bez_out - bez_w * 0.06
        hot = RED if s['missed'] else LUME_HOT
        base_c = RED if s['missed'] else LUME
        glow(layer, lambda g, c: g.d.polygon(band(r0, r1, ta - hw, ta + hw), fill=c), hot, 9 * PT / 2, 1.6)
        over = Layer(*layer.img.size)
        over.d.polygon(band(r0, r1, ta - hw, ta + hw), fill=base_c + (255,))
        layer.over(over, 0.75)
        layer.d.polygon(band(r0, r1, ta - core, ta + core), fill=hot)
        d = layer.d

    # dial
    circle(layer, bez_in, (30, 30, 32))
    dR = bez_in * 0.97
    circle(layer, dR, DIAL)
    dome = Layer(*layer.img.size)
    dome.d.ellipse([cx - dR * 0.15 - dR * 0.6, cy - dR * 0.5 - dR * 0.6,
                    cx - dR * 0.15 + dR * 0.6, cy - dR * 0.5 + dR * 0.6], fill=DIAL_HI + (200,))
    dome.img = dome.img.filter(ImageFilter.GaussianBlur(dR * 0.3))
    mask = Image.new('L', layer.img.size, 0)
    ImageDraw.Draw(mask).ellipse([cx - dR, cy - dR, cx + dR, cy + dR], fill=255)
    a = Image.composite(dome.img.getchannel('A'), Image.new('L', layer.img.size, 0), mask)
    dome.img.putalpha(a)
    layer.over(dome)
    d = layer.d

    for i in range(60):
        a = i / 60 * TAU
        major = i % 5 == 0
        ln = dR * (0.06 if major else 0.035)
        hw = (1.1 if major else 0.6) * PT
        d.polygon(rect(a, dR * 0.985 - ln, dR * 0.985, hw), fill=LUME if major else (226, 224, 219))

    def plot(a, h, grow):
        if h == 0:
            return [rot(a, 0, -dR * 0.66 + grow), rot(a, -dR * 0.095 - grow, -dR * 0.89 - grow),
                    rot(a, dR * 0.095 + grow, -dR * 0.89 - grow)]
        if h % 3 == 0:
            w = dR * 0.042 + grow
            return rect(a, dR * 0.68 - grow, dR * 0.89 + grow, w)
        return None

    def plots(lyr, c, grow):
        for h in range(12):
            if h == 3:
                continue
            a = h / 12 * TAU
            p = plot(a, h, grow)
            if p:
                lyr.d.polygon(p, fill=c)
            else:
                x, y = pt(a, dR * 0.8); r = dR * 0.065 + grow
                lyr.d.ellipse([x - r, y - r, x + r, y + r], fill=c)

    glow(layer, lambda g, c: plots(g, c, 0), LUME, 4 * PT / 2, 0.5)
    plots(layer, GILT, dR * 0.012)
    plots(layer, LUME, 0)
    d = layer.d

    # date window
    ww, wh, wx = dR * 0.24, dR * 0.17, dR * 0.74
    d.rounded_rectangle([cx + wx - ww / 2, cy - wh / 2, cx + wx + ww / 2, cy + wh / 2],
                        radius=2 * PT, fill=PAPER, outline=GILT, width=int(2 * PT))
    d.text((cx + wx, cy + 1 * PT), str(s['score']), font=font(BOLD, wh * 0.74 * 1.33), fill=INK, anchor='mm')

    # print
    draw_text(layer, cx, cy - dR * 0.44, 'NEVER LATE', font(BOLD, dR * 0.085 * 1.33), PAPER, dR * 0.008)
    draw_text(layer, cx, cy - dR * 0.33, 'GMT', font(BOLD, dR * 0.07 * 1.33), RED, dR * 0.01)
    draw_text(layer, cx, cy + dR * 0.45, 'CW' if s['direction'] > 0 else 'CCW', font(MONO, dR * 0.05 * 1.33), GILT)

    # real time hands (shown at 10:09, the classic watch-ad time)
    hours, minutes = s.get('time', (10, 9))
    hour_a = ((hours % 12) + minutes / 60) / 12 * TAU
    min_a = minutes / 60 * TAU
    gmt_a = (hours + minutes / 60) / 24 * TAU

    d.polygon(rect(gmt_a, -dR * 0.1, dR * 0.78, dR * 0.011), fill=BURGUNDY)
    d.polygon(along(gmt_a, [(dR * 0.74, -dR * 0.07), (dR * 0.92, 0), (dR * 0.74, dR * 0.07)]), fill=BURGUNDY)
    d.polygon(along(gmt_a, [(dR * 0.765, -dR * 0.04), (dR * 0.87, 0), (dR * 0.765, dR * 0.04)]), fill=LUME)

    d.polygon(rect(hour_a, -dR * 0.12, dR * 0.36, dR * 0.03), fill=METAL)
    d.polygon(rect(hour_a, dR * 0.36, dR * 0.52, dR * 0.08), fill=METAL)
    d.polygon(rect(hour_a, dR * 0.375, dR * 0.505, dR * 0.062), fill=LUME)
    d.polygon(along(hour_a, [(dR * 0.52, -dR * 0.03), (dR * 0.6, 0), (dR * 0.52, dR * 0.03)]), fill=METAL)

    d.polygon(along(min_a, [(-dR * 0.14, -dR * 0.026), (dR * 0.8, -dR * 0.026), (dR * 0.88, 0),
                            (dR * 0.8, dR * 0.026), (-dR * 0.14, dR * 0.026)]), fill=METAL)
    d.polygon(along(min_a, [(dR * 0.3, -dR * 0.014), (dR * 0.78, -dR * 0.014), (dR * 0.83, 0),
                            (dR * 0.78, dR * 0.014), (dR * 0.3, dR * 0.014)]), fill=LUME)

    # game hand
    ha = s['angle']
    hand_c = RED if s['missed'] else PAPER
    d.polygon(rect(ha, -dR * 0.22, dR * 0.99, dR * 0.009), fill=hand_c)
    glow(layer, lambda g, c: g.d.polygon(rect(ha, dR * 0.62, dR * 0.74, dR * 0.05), fill=c), LUME_HOT, 6 * PT / 2, 0.9)
    d = layer.d
    d.polygon(rect(ha, dR * 0.62, dR * 0.74, dR * 0.05), fill=hand_c)
    d.polygon(rect(ha, dR * 0.632, dR * 0.728, dR * 0.038), fill=LUME)
    circle(layer, dR * 0.05, METAL)
    circle(layer, dR * 0.02, METAL_DARK)

    if s.get('flash'):
        txt, perfect = s['flash']
        draw_text(layer, cx, cy + dR * 0.26, txt, font(BOLD, dR * 0.13 * 1.33), LUME_HOT if perfect else GILT)


# ---------------------------------------------------------------- screen (ContentView.swift)

def caption(layer, cx, cy, txt, color=STEEL):
    draw_text(layer, cx, cy, txt, font(MONO_BOLD, 10 * PT * 1.0), color, 2 * PT)


def draw_screen(s):
    sw, sh = W * SS, H * SS
    L = Layer(sw, sh, BG + (255,))
    top, bottom = (59 + 12) * PT, sh - (34 + 12) * PT
    left, right = 16 * PT, sw - 16 * PT

    # HUD
    caption_y = top + 8 * PT
    lx = left
    f_cap = font(MONO_BOLD, 10 * PT)
    L.d.text((lx, caption_y), 'BEST', font=f_cap, fill=STEEL, anchor='lm')
    L.d.text((lx, caption_y + 24 * PT), str(s['best']), font=font(BOLD, 28 * PT * 1.0), fill=LUME, anchor='lm')
    L.d.text((right, caption_y), 'PHASE', font=f_cap, fill=STEEL, anchor='rm')
    L.d.text((right, caption_y + 22 * PT), s['phase'], font=font(MEDIUM, 16 * PT), fill=GILT, anchor='rm')

    # dial area
    hud_bottom = top + 45 * PT + 10 * PT
    bar_top = bottom - 44 * PT
    area_top, area_bottom = hud_bottom, bar_top - 10 * PT
    side = min(right - left, area_bottom - area_top)
    cx, cy = sw / 2, (area_top + area_bottom) / 2
    draw_dial(L, cx, cy, side, s)

    if s.get('card'):
        draw_card(L, cx, cy, s['card'])

    # bottom bar (only when not playing)
    if s.get('menu'):
        by = bar_top + 22 * PT
        r = 22 * PT
        bx = left + r
        L.d.ellipse([bx - r, by - r, bx + r, by + r], fill=NAVY + (153,))
        u = PT
        spk = [(bx - 7 * u, by - 3 * u), (bx - 3 * u, by - 3 * u), (bx + 2 * u, by - 8 * u),
               (bx + 2 * u, by + 8 * u), (bx - 3 * u, by + 3 * u), (bx - 7 * u, by + 3 * u)]
        L.d.polygon(spk, fill=STEEL)
        for k, rr in enumerate((5, 9)):
            L.d.arc([bx + 2 * u - rr * u, by - rr * u, bx + 2 * u + rr * u, by + rr * u], -50, 50,
                    fill=STEEL, width=int(2 * u))
        caption(L, sw / 2, by, 'TAP ANYWHERE')

    return L.img.convert('RGB')


def draw_card(L, cx, cy, card):
    f_title = font(BOLD, 44 * PT if card['kind'] == 'over' else 40 * PT)
    lines = []  # (kind, text, font, color, tracking, height)
    if card['kind'] == 'over':
        lines += [('cap', card['caption'], font(MONO_BOLD, 10 * PT), GILT, 2 * PT, 14 * PT),
                  ('t', 'LATE', f_title, RED, 3 * PT, 50 * PT),
                  ('t', str(card['score']), font(BOLD, 60 * PT), LUME, 0, 64 * PT),
                  ('b', card['blurb'], font(MONO, 12 * PT), STEEL, 0, 18 * PT)]
    else:
        lines += [('t', 'NEVER LATE', f_title, LUME, 3 * PT, 46 * PT)]
        for ln in card['blurb_lines']:
            lines.append(('b', ln, font(MONO, 12 * PT), STEEL, 0, 18 * PT))
    spacing = 10 * PT
    pill_h = 38 * PT + 4 * PT
    content_h = sum(l[5] for l in lines) + spacing * len(lines) + pill_h
    w = 300 * PT
    h = content_h + 44 * PT
    box = Layer(*L.img.size)
    box.d.rounded_rectangle([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2], radius=14 * PT,
                            fill=BG + (217,), outline=NAVY + (255,), width=int(1 * PT))
    L.over(box)
    y = cy - h / 2 + 22 * PT
    for kind, txt, f, color, tr, lh in lines:
        draw_text(L, cx, y + lh / 2, txt, f, color, tr)
        y += lh + spacing
    pill_txt = card['pill']
    f_pill = font(MONO_BOLD, 13 * PT)
    tw, _ = text_size(pill_txt, f_pill, 2 * PT)
    pw, ph = tw + 44 * PT, 38 * PT
    y += 4 * PT
    L.d.rounded_rectangle([cx - pw / 2, y, cx + pw / 2, y + ph], radius=ph / 2, fill=LUME)
    draw_text(L, cx, y + ph / 2, pill_txt, f_pill, BG, 2 * PT)


# ---------------------------------------------------------------- App Store frame

SHOTS = [
    dict(headline='Tap on time.', sub='One tap. One seconds hand.',
         screen=dict(best=38, phase='1 · STEADY', score=6, angle=math.radians(76), target=math.radians(100),
                     half_width=0.26, direction=1, show_target=True, missed=False)),
    dict(headline='Hit dead center.', sub='Perfect hits score double.',
         screen=dict(best=38, phase='2 · REVERSE', score=17, angle=math.radians(205), target=math.radians(204),
                     half_width=0.2, direction=-1, show_target=True, missed=False, flash=('PERFECT +2', True))),
    dict(headline='It fights back.', sub='The hand reverses. The bezel drifts.',
         screen=dict(best=38, phase='3 · DRIFT', score=29, angle=math.radians(246), target=math.radians(266),
                     half_width=0.14, direction=1, show_target=True, missed=False)),
    dict(headline='Built for watch people.', sub='24-hour GMT bezel. Cream lume. Real time.',
         screen=dict(best=38, phase='1 · STEADY', score=0, angle=math.radians(205), target=0, half_width=0.3,
                     direction=1, show_target=False, missed=False, menu=True,
                     card=None)),
    dict(headline='Plays in a minute.', sub='For lines, timeouts and commercial breaks.',
         screen=dict(best=42, phase='3 · DRIFT', score=42, angle=math.radians(118), target=math.radians(84),
                     half_width=0.13, direction=1, show_target=True, missed=True, menu=True,
                     card=dict(kind='over', caption='NEW PERSONAL BEST', score=42,
                               blurb='27 clean hits · reached phase 3', pill='TAP TO GO AGAIN'))),
]


def compose(shot, screen_img):
    canvas = Layer(W * SS, H * SS, BG + (255,))
    # two-tone band like the bezel insert
    canvas.d.rectangle([0, 0, W * SS / 2, 14 * SS], fill=BURGUNDY)
    canvas.d.rectangle([W * SS / 2, 0, W * SS, 14 * SS], fill=NAVY)

    size = 118
    while text_size(shot['headline'].upper(), font(BOLD, size * SS), 4 * SS)[0] > 1200 * SS:
        size -= 2
    hf = font(BOLD, size * SS)
    draw_text(canvas, W * SS / 2, 250 * SS, shot['headline'].upper(), hf, LUME, 4 * SS)
    sf = font(MEDIUM, 56 * SS)
    draw_text(canvas, W * SS / 2, 390 * SS, shot['sub'], sf, GILT, 1 * SS)

    scale = 0.9
    pw, ph = int(W * SS * scale), int(H * SS * scale)
    px, py = (W * SS - pw) // 2, int(520 * SS)
    phone = screen_img.convert('RGB').resize((pw, ph), Image.LANCZOS)
    radius = int(150 * SS * scale)
    mask = Image.new('L', (pw, ph), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, pw - 1, ph - 1], radius=radius, fill=255)
    # soft shadow, then a thin steel frame
    sh = Layer(W * SS, H * SS)
    sh.d.rounded_rectangle([px, py + 20 * SS, px + pw, py + ph + 20 * SS], radius=radius, fill=(0, 0, 0, 200))
    sh.img = sh.img.filter(ImageFilter.GaussianBlur(40 * SS))
    canvas.over(sh)
    canvas.d.rounded_rectangle([px - 10 * SS, py - 10 * SS, px + pw + 10 * SS, py + ph + 10 * SS],
                               radius=radius + 10 * SS, fill=(52, 54, 58))
    canvas.img.paste(phone, (px, py), mask)
    return canvas.img.convert('RGB').resize((W, H), Image.LANCZOS)


def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    real = {}
    args = sys.argv[2:]
    for i, a in enumerate(args):
        if a == '--shot':
            n, path = args[i + 1].split('=', 1)
            real[int(n)] = path
    for n, shot in enumerate(SHOTS, 1):
        screen = Image.open(real[n]) if n in real else draw_screen(shot['screen'])
        img = compose(shot, screen)
        path = os.path.join(out, f'{n:02d}.png')
        img.save(path)
        print(path)


if __name__ == '__main__':
    main()
