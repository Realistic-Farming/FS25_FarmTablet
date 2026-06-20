# -*- coding: utf-8 -*-
# ============================================================
# gen_icons.py  -  FarmTablet glossy app-icon generator
#
# Bakes one premium "glossy skeuomorphic" PNG per app:
#   rounded tile + vertical gradient + top gloss + soft drop
#   shadow + a white emblem (glyph) baked in.
#
# Output:  gui/icons/<app_id>.png   (+ _fallback.png, wallpaper.png)
#          tools/_contact_sheet.png  (for visual QA, not shipped)
#
# Run:  py tools/gen_icons.py
# Requires: Pillow
# ============================================================
import os
import math
from PIL import Image, ImageDraw, ImageFilter

HERE     = os.path.dirname(os.path.abspath(__file__))
MOD_DIR  = os.path.dirname(HERE)
OUT_DIR  = os.path.join(MOD_DIR, "gui", "icons")
WALL_OUT = os.path.join(MOD_DIR, "gui", "wallpaper.png")
SHEET    = os.path.join(HERE, "_contact_sheet.png")

os.makedirs(OUT_DIR, exist_ok=True)

SIZE = 128          # final icon size (px)
SS   = 4            # supersample factor
S    = SIZE * SS    # working canvas size

# ── color helpers ─────────────────────────────────────────
def f2b(c):
    return tuple(int(round(max(0.0, min(1.0, x)) * 255)) for x in c)

def shade(rgb, f):
    """f>0 lighten toward white, f<0 darken toward black. rgb is 0..1 triple."""
    if f >= 0:
        return tuple(x + (1.0 - x) * f for x in rgb)
    return tuple(x * (1.0 + f) for x in rgb)

# ── tile geometry (in working px) ─────────────────────────
MARGIN_TOP = int(S * 0.045)
MARGIN_BOT = int(S * 0.085)         # extra room for drop shadow
MARGIN_X   = int(S * 0.055)
TILE_X0    = MARGIN_X
TILE_Y0    = MARGIN_TOP
TILE_X1    = S - MARGIN_X
TILE_Y1    = S - MARGIN_BOT
TILE_W     = TILE_X1 - TILE_X0
TILE_H     = TILE_Y1 - TILE_Y0
RADIUS     = int(TILE_W * 0.225)
CX         = (TILE_X0 + TILE_X1) // 2
CY         = (TILE_Y0 + TILE_Y1) // 2

def tile_mask():
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([TILE_X0, TILE_Y0, TILE_X1, TILE_Y1], RADIUS, fill=255)
    return m

def vgradient(top_rgb, bot_rgb):
    g = Image.new("RGB", (S, S))
    px = g.load()
    tb = f2b(top_rgb)
    bb = f2b(bot_rgb)
    for y in range(S):
        t = y / float(S - 1)
        r = int(tb[0] + (bb[0] - tb[0]) * t)
        gg = int(tb[1] + (bb[1] - tb[1]) * t)
        b = int(tb[2] + (bb[2] - tb[2]) * t)
        for x in range(S):
            px[x, y] = (r, gg, b)
    return g

def make_base(accent):
    """Returns an RGBA canvas with shadow + gradient tile + gloss + rim."""
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    mask = tile_mask()

    # --- soft drop shadow ---
    sh = Image.new("L", (S, S), 0)
    sd = ImageDraw.Draw(sh)
    off = int(S * 0.03)
    sd.rounded_rectangle([TILE_X0, TILE_Y0 + off, TILE_X1, TILE_Y1 + off], RADIUS, fill=130)
    sh = sh.filter(ImageFilter.GaussianBlur(int(S * 0.035)))
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow.putalpha(sh)
    canvas = Image.alpha_composite(canvas, shadow)

    # --- gradient body ---
    grad = vgradient(shade(accent, 0.22), shade(accent, -0.34)).convert("RGBA")
    grad.putalpha(mask)
    canvas = Image.alpha_composite(canvas, grad)

    # --- top gloss (glossy skeuomorphic highlight) ---
    gloss = Image.new("L", (S, S), 0)
    gd = ImageDraw.Draw(gloss)
    # an elliptical highlight bulging across the upper half
    gy1 = TILE_Y0 + int(TILE_H * 0.52)
    gd.ellipse([TILE_X0 - TILE_W * 0.10, TILE_Y0 - TILE_H * 0.55,
                TILE_X1 + TILE_W * 0.10, gy1], fill=255)
    # vertical alpha falloff so gloss fades downward
    falloff = Image.new("L", (S, S), 0)
    fp = falloff.load()
    for y in range(S):
        t = (y - TILE_Y0) / float(TILE_H)
        a = max(0.0, 1.0 - t / 0.55)
        v = int(150 * a)
        for x in range(S):
            fp[x, y] = v
    gloss = Image.composite(gloss, Image.new("L", (S, S), 0), falloff)
    gloss = Image.composite(gloss, Image.new("L", (S, S), 0), mask)  # clip to tile
    white = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    white.putalpha(gloss)
    canvas = Image.alpha_composite(canvas, white)

    # --- inner top rim light + bottom shade for depth ---
    rim = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim)
    rd.rounded_rectangle([TILE_X0, TILE_Y0, TILE_X1, TILE_Y1], RADIUS,
                         outline=(255, 255, 255, 70), width=max(2, SS))
    rim_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(rim_mask).rounded_rectangle(
        [TILE_X0, TILE_Y0, TILE_X1, TILE_Y0 + TILE_H // 2], RADIUS, fill=255)
    rim.putalpha(Image.composite(rim.getchannel("A"), Image.new("L", (S, S), 0), rim_mask))
    canvas = Image.alpha_composite(canvas, rim)

    return canvas

def stamp_emblem(canvas, emblem):
    """Draw an emblem (white shapes) on its own layer with a soft shadow, then composite."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    emblem(d, layer)
    # drop shadow for the glyph (legibility on bright tiles)
    alpha = layer.getchannel("A")
    sh = alpha.filter(ImageFilter.GaussianBlur(int(S * 0.012)))
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow.putalpha(sh.point(lambda a: int(a * 0.55)))
    sxoff = int(S * 0.008)
    canvas = Image.alpha_composite(canvas, ImageChops_offset(shadow, sxoff, sxoff))
    canvas = Image.alpha_composite(canvas, layer)
    return canvas

def ImageChops_offset(img, dx, dy):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (dx, dy))
    return out

# ── small drawing primitives (work in canvas px) ──────────
W = (255, 255, 255, 255)
# "engraved" detail: semi-dark, drawn over the white emblem so the tile
# shows through a little — reads as a cut/notch/line on the final icon.
DETAIL = (18, 22, 30, 165)

def line(d, p0, p1, w, fill=W):
    d.line([p0, p1], fill=fill, width=int(w), joint="curve")

def circle(d, cx, cy, r, fill=None, outline=None, w=0):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=outline, width=int(w))

def rrect(d, box, rad, fill=None, outline=None, w=0):
    d.rounded_rectangle(box, rad, fill=fill, outline=outline, width=int(w))

def poly(d, pts, fill=W, outline=None, w=0):
    d.polygon(pts, fill=fill, outline=outline, width=int(w))

def rotate_layer(emblem_fn, deg):
    def inner(d, layer):
        tmp = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        td = ImageDraw.Draw(tmp)
        emblem_fn(td, tmp)
        tmp = tmp.rotate(deg, resample=Image.BICUBIC, center=(CX, CY))
        layer.alpha_composite(tmp)
    return inner

# unit: radius for emblem scaling
R = int(TILE_W * 0.30)

# ── emblem drawers ────────────────────────────────────────
def em_dashboard(d, L):
    g = int(R * 0.34); gap = int(R * 0.16)
    x0 = CX - g - gap // 2; y0 = CY - g - gap // 2
    for ix in (0, 1):
        for iy in (0, 1):
            bx = x0 + ix * (g + gap); by = y0 + iy * (g + gap)
            rrect(d, [bx, by, bx + g, by + g], int(g * 0.28), fill=W)

def em_store(d, L):
    # shopping bag (trapezoid, wider at base) + two handle loops
    topw = int(R * 0.95); botw = int(R * 1.18); bh = int(R * 1.08)
    y0 = CY - bh // 2 + int(R * 0.20); y1 = y0 + bh
    poly(d, [(CX - topw//2, y0), (CX + topw//2, y0),
             (CX + botw//2, y1), (CX - botw//2, y1)], fill=W)
    # handle loops
    hw = int(R * 0.20)
    for off in (-int(R * 0.30), int(R * 0.30)):
        d.arc([CX + off - hw, y0 - int(R * 0.55), CX + off + hw, y0 + int(R * 0.18)],
              180, 360, fill=W, width=int(R * 0.10))
    # paper-bag fold line
    line(d, (CX, y0), (CX, y1), R * 0.05, fill=DETAIL)

def em_settings(d, L):
    teeth = 8
    rout = int(R * 0.95); rin = int(R * 0.66)
    tooth_w = math.radians(15)
    pts_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pts_layer)
    for i in range(teeth):
        a = i * (2 * math.pi / teeth)
        for sgn in (-1, 1):
            pass
    # gear body
    circle(d, CX, CY, rout, fill=W)
    # teeth as small rounded rects around
    tlen = int(R * 0.34); tw = int(R * 0.30)
    for i in range(teeth):
        a = i * (2 * math.pi / teeth)
        tx = CX + math.cos(a) * (rout + tlen * 0.2)
        ty = CY + math.sin(a) * (rout + tlen * 0.2)
        tt = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ttd = ImageDraw.Draw(tt)
        ttd.rounded_rectangle([CX - tw//2, CY - rout - tlen, CX + tw//2, CY - rout + int(tlen*0.4)],
                              int(tw*0.3), fill=W)
        tt = tt.rotate(-math.degrees(a) - 90, resample=Image.BICUBIC, center=(CX, CY))
        L.alpha_composite(tt)
    # center hole (punch to accent)
    circle(d, CX, CY, int(R * 0.30), fill=DETAIL)

def em_updates(d, L):
    # circular refresh arrow
    r = int(R * 0.78)
    d.arc([CX - r, CY - r, CX + r, CY + r], 50, 330, fill=W, width=int(R * 0.20))
    # arrowhead at end (~330 deg)
    a = math.radians(330)
    ex = CX + math.cos(a) * r; ey = CY + math.sin(a) * r
    poly(d, [(ex - R*0.04, ey - R*0.30), (ex + R*0.30, ey), (ex - R*0.30, ey + R*0.06)], fill=W)

def em_wrench(d, L):
    def draw(td, tl):
        # handle
        td.rounded_rectangle([CX - int(R*0.12), CY - int(R*0.1), CX + int(R*0.12), CY + int(R*0.95)],
                             int(R*0.12), fill=W)
        # open head (C shape)
        hr = int(R * 0.42)
        circle(td, CX, CY - int(R*0.42), hr, fill=W)
        circle(td, CX, CY - int(R*0.42), int(hr*0.5), fill=DETAIL)
        td.rectangle([CX - int(R*0.18), CY - int(R*0.95), CX + int(R*0.18), CY - int(R*0.42)], fill=DETAIL)
    rotate_layer(draw, -35)(d, L)

def em_fields(d, L):
    n = 4; gap = int(R * 0.42); w = int(R * 1.5); h = int(R * 0.16)
    y = CY - gap * (n - 1) / 2
    for i in range(n):
        yy = int(y + i * gap)
        rrect(d, [CX - w//2, yy - h//2, CX + w//2, yy + h//2], h//2, fill=W)

def em_animals(d, L):
    pad_w = int(R * 0.9); pad_h = int(R * 0.7)
    rrect(d, [CX - pad_w//2, CY, CX + pad_w//2, CY + pad_h], int(pad_w*0.4), fill=W)
    tr = int(R * 0.22)
    for dx, dy in [(-0.55, -0.55), (-0.18, -0.78), (0.18, -0.78), (0.55, -0.55)]:
        circle(d, CX + int(R*dx), CY + int(R*dy), tr, fill=W)

def em_weather(d, L):
    # sun
    sx, sy, sr = CX + int(R*0.32), CY - int(R*0.42), int(R*0.42)
    for i in range(8):
        a = i * math.pi / 4
        x0 = sx + math.cos(a) * sr * 1.25; y0 = sy + math.sin(a) * sr * 1.25
        x1 = sx + math.cos(a) * sr * 1.75; y1 = sy + math.sin(a) * sr * 1.75
        line(d, (x0, y0), (x1, y1), R*0.12)
    circle(d, sx, sy, sr, fill=W)
    # cloud
    circle(d, CX - int(R*0.45), CY + int(R*0.30), int(R*0.42), fill=W)
    circle(d, CX + int(R*0.05), CY + int(R*0.18), int(R*0.55), fill=W)
    circle(d, CX + int(R*0.55), CY + int(R*0.35), int(R*0.40), fill=W)
    d.rectangle([CX - int(R*0.45), CY + int(R*0.30), CX + int(R*0.55), CY + int(R*0.75)], fill=W)

def em_digging(d, L):
    def draw(td, tl):
        # handle
        td.rounded_rectangle([CX - int(R*0.10), CY - int(R*0.95), CX + int(R*0.10), CY + int(R*0.30)],
                             int(R*0.1), fill=W)
        # T grip
        td.rounded_rectangle([CX - int(R*0.34), CY - int(R*1.05), CX + int(R*0.34), CY - int(R*0.80)],
                             int(R*0.1), fill=W)
        # blade
        poly(td, [(CX - int(R*0.40), CY + int(R*0.30)), (CX + int(R*0.40), CY + int(R*0.30)),
                  (CX + int(R*0.30), CY + int(R*0.85)), (CX - int(R*0.30), CY + int(R*0.85))], fill=W)
    rotate_layer(draw, 30)(d, L)

def em_bucket(d, L):
    tw = int(R * 1.1); bw = int(R * 0.7); h = int(R * 1.0)
    x_t = CX - tw//2; y_t = CY - int(R*0.4)
    poly(d, [(CX - tw//2, y_t), (CX + tw//2, y_t),
             (CX + bw//2, y_t + h), (CX - bw//2, y_t + h)], fill=W)
    # handle arc
    d.arc([CX - tw//2, y_t - int(R*0.7), CX + tw//2, y_t + int(R*0.3)], 180, 360, fill=W, width=int(R*0.13))

def em_storage(d, L):
    bw = int(R * 0.62)
    coords = [(-0.5, 0.05), (0.5, 0.05), (0.0, -0.62)]
    for dx, dy in coords:
        bx = CX + int(R*dx) - bw//2; by = CY + int(R*dy) - bw//2
        rrect(d, [bx, by, bx + bw, by + bw], int(bw*0.18), fill=W)
        line(d, (bx, by + bw*0.5), (bx + bw, by + bw*0.5), R*0.05, fill=DETAIL)

def em_time(d, L):
    r = int(R * 0.92)
    circle(d, CX, CY, r, outline=W, w=int(R*0.16))
    line(d, (CX, CY), (CX, CY - int(r*0.55)), R*0.13)
    line(d, (CX, CY), (CX + int(r*0.45), CY + int(r*0.12)), R*0.13)

def em_hotspot(d, L):
    r = int(R * 0.6)
    circle(d, CX, CY - int(R*0.25), r, fill=W)
    poly(d, [(CX - int(r*0.85), CY - int(R*0.05)), (CX + int(r*0.85), CY - int(R*0.05)),
             (CX, CY + int(R*0.85))], fill=W)
    circle(d, CX, CY - int(R*0.25), int(r*0.42), fill=DETAIL)

def em_notes(d, L):
    w = int(R * 1.1); h = int(R * 1.3)
    x0 = CX - w//2; y0 = CY - h//2
    rrect(d, [x0, y0, x0 + w, y0 + h], int(R*0.14), fill=W)
    for i in range(3):
        yy = y0 + int(h*0.30) + i * int(h*0.22)
        line(d, (x0 + int(w*0.18), yy), (x0 + int(w*0.82), yy), R*0.08, fill=DETAIL)

def em_admin(d, L):
    # three sliders
    n = 3; w = int(R * 1.5)
    for i in range(n):
        yy = CY - int(R*0.6) + i * int(R*0.6)
        line(d, (CX - w//2, yy), (CX + w//2, yy), R*0.10)
        knob = CX - w//2 + int(w * (0.3 + 0.25*i))
        circle(d, knob, yy, int(R*0.20), fill=W)
        circle(d, knob, yy, int(R*0.20), outline=W, w=int(R*0.06))

def em_jobs(d, L):
    w = int(R * 1.05); h = int(R * 1.34)
    x0 = CX - w//2; y0 = CY - h//2
    rrect(d, [x0, y0, x0 + w, y0 + h], int(R*0.12), fill=W)
    # clip at top
    cw = int(w*0.46)
    rrect(d, [CX - cw//2, y0 - int(R*0.18), CX + cw//2, y0 + int(R*0.14)], int(R*0.09), fill=W)
    # checklist: boxes + lines (engraved)
    for i in range(3):
        yy = y0 + int(h*0.36) + i*int(h*0.22)
        bx = x0 + int(w*0.18)
        rrect(d, [bx, yy - int(R*0.11), bx + int(R*0.22), yy + int(R*0.11)],
              int(R*0.04), outline=DETAIL, w=max(2, int(R*0.05)))
        line(d, (bx + int(R*0.36), yy), (x0 + int(w*0.84), yy), R*0.07, fill=DETAIL)

def em_contracts(d, L):
    w = int(R * 1.1); h = int(R * 1.3)
    x0 = CX - w//2; y0 = CY - h//2
    rrect(d, [x0, y0, x0 + w, y0 + h], int(R*0.12), fill=W)
    # check mark
    line(d, (CX - int(R*0.3), CY + int(R*0.1)), (CX - int(R*0.05), CY + int(R*0.35)), R*0.12, fill=DETAIL)
    line(d, (CX - int(R*0.05), CY + int(R*0.35)), (CX + int(R*0.4), CY - int(R*0.25)), R*0.12, fill=DETAIL)

def em_fleet(d, L):
    # truck
    bw = int(R*0.8); bh = int(R*0.6)
    bx = CX - int(R*0.9); by = CY - bh//2
    rrect(d, [bx, by, bx+bw, by+bh], int(R*0.1), fill=W)  # box
    cw = int(R*0.6); ch = int(R*0.45)
    cx = bx + bw; cy = by + bh - ch
    poly(d, [(cx, by+bh), (cx, cy), (cx+cw, cy+int(ch*0.2)), (cx+int(cw*1.1), by+bh)], fill=W)  # cab
    wr = int(R*0.18)
    circle(d, bx + int(bw*0.35), by+bh+int(R*0.02), wr, fill=W)
    circle(d, cx + int(cw*0.6), by+bh+int(R*0.02), wr, fill=W)

def em_production(d, L):
    w = int(R*1.5); h = int(R*0.9)
    x0 = CX - w//2; y0 = CY + int(R*0.0)
    # body
    d.rectangle([x0, y0, x0+w, y0+h], fill=W)
    # saw-tooth roof
    teeth = 3; tw = w//teeth
    for i in range(teeth):
        tx = x0 + i*tw
        poly(d, [(tx, y0), (tx+tw, y0), (tx+tw, y0-int(R*0.45))], fill=W)
    # chimney
    d.rectangle([x0+int(w*0.1), y0-int(R*0.8), x0+int(w*0.22), y0-int(R*0.2)], fill=W)

def em_stats(d, L):
    bw = int(R*0.30); gap = int(R*0.12); base = CY + int(R*0.7)
    heights = [0.6, 1.0, 0.8, 1.3]
    total = len(heights)*(bw+gap) - gap
    x = CX - total//2
    for hh in heights:
        bh = int(R*hh)
        rrect(d, [x, base-bh, x+bw, base], int(bw*0.2), fill=W)
        x += bw+gap

def em_income(d, L):
    # coin stack
    cw = int(R*1.2); ch = int(R*0.34)
    for i in range(3):
        yy = CY + int(R*0.5) - i*int(R*0.42)
        d.ellipse([CX-cw//2, yy-ch//2, CX+cw//2, yy+ch//2], fill=W)
        d.ellipse([CX-cw//2, yy-ch//2-int(R*0.12), CX+cw//2, yy+ch//2-int(R*0.12)],
                  outline=W, width=int(R*0.0))
    # up arrow
    poly(d, [(CX+int(R*0.5), CY-int(R*0.5)), (CX+int(R*0.95), CY-int(R*0.5)), (CX+int(R*0.72), CY-int(R*0.95))], fill=W)

def em_tax(d, L):
    rr = int(R*0.24)
    circle(d, CX-int(R*0.45), CY-int(R*0.45), rr, fill=W)
    circle(d, CX+int(R*0.45), CY+int(R*0.45), rr, fill=W)
    line(d, (CX+int(R*0.6), CY-int(R*0.7)), (CX-int(R*0.6), CY+int(R*0.7)), R*0.16)

def em_npc(d, L):
    r = int(R*0.46)
    circle(d, CX-int(R*0.40), CY-int(R*0.25), r, fill=W)
    circle(d, CX+int(R*0.40), CY-int(R*0.25), r, fill=W)
    poly(d, [(CX-int(R*0.82), CY-int(R*0.05)), (CX+int(R*0.82), CY-int(R*0.05)), (CX, CY+int(R*0.85))], fill=W)

def em_crop_stress(d, L):
    # sprout with droop
    line(d, (CX, CY+int(R*0.8)), (CX, CY-int(R*0.2)), R*0.13)
    # leaf left up
    d.pieslice([CX-int(R*0.8), CY-int(R*0.5), CX, CY+int(R*0.2)], 20, 160, fill=W)
    # leaf right drooping
    d.pieslice([CX, CY-int(R*0.1), CX+int(R*0.85), CY+int(R*0.6)], 200, 340, fill=W)

def em_soil(d, L):
    # tilted teardrop leaf with veins
    def draw(td, tl):
        circle(td, CX, CY + int(R*0.22), int(R*0.60), fill=W)
        poly(td, [(CX - int(R*0.58), CY + int(R*0.28)),
                  (CX + int(R*0.58), CY + int(R*0.28)),
                  (CX, CY - int(R*0.88))], fill=W)
        line(td, (CX, CY - int(R*0.6)), (CX, CY + int(R*0.72)), R*0.07, fill=DETAIL)
        line(td, (CX, CY - int(R*0.1)), (CX - int(R*0.34), CY - int(R*0.30)), R*0.06, fill=DETAIL)
        line(td, (CX, CY + int(R*0.22)), (CX + int(R*0.34), CY + int(R*0.02)), R*0.06, fill=DETAIL)
    rotate_layer(draw, -28)(d, L)

def em_sentry(d, L):
    w = int(R*1.4); h = int(R*1.6)
    poly(d, [(CX-w//2, CY-h//2), (CX+w//2, CY-h//2), (CX+w//2, CY+int(h*0.1)),
             (CX, CY+h//2), (CX-w//2, CY+int(h*0.1))], fill=W)
    # check
    line(d, (CX-int(R*0.32), CY), (CX-int(R*0.05), CY+int(R*0.28)), R*0.12, fill=DETAIL)
    line(d, (CX-int(R*0.05), CY+int(R*0.28)), (CX+int(R*0.4), CY-int(R*0.3)), R*0.12, fill=DETAIL)

def em_market(d, L):
    base = CY + int(R*0.7)
    pts = [(CX-int(R*0.9), base-int(R*0.2)), (CX-int(R*0.3), base-int(R*0.7)),
           (CX+int(R*0.1), base-int(R*0.45)), (CX+int(R*0.85), base-int(R*1.25))]
    for i in range(len(pts)-1):
        line(d, pts[i], pts[i+1], R*0.13)
    # arrowhead
    ex, ey = pts[-1]
    poly(d, [(ex, ey), (ex-int(R*0.36), ey+int(R*0.06)), (ex-int(R*0.02), ey+int(R*0.4))], fill=W)

def em_worker(d, L):
    # hard hat
    d.pieslice([CX-int(R*0.8), CY-int(R*0.5), CX+int(R*0.8), CY+int(R*0.9)], 180, 360, fill=W)
    d.rounded_rectangle([CX-int(R*1.0), CY+int(R*0.32), CX+int(R*1.0), CY+int(R*0.52)], int(R*0.1), fill=W)
    d.rectangle([CX-int(R*0.16), CY-int(R*0.7), CX+int(R*0.16), CY-int(R*0.3)], fill=W)

def em_personnel(d, L):
    for dx in (-0.42, 0.42):
        hx = CX + int(R*dx)
        circle(d, hx, CY-int(R*0.42), int(R*0.32), fill=W)
        d.pieslice([hx-int(R*0.5), CY-int(R*0.05), hx+int(R*0.5), CY+int(R*1.0)], 180, 360, fill=W)

def em_events(d, L):
    poly(d, [(CX+int(R*0.25), CY-int(R*0.95)), (CX-int(R*0.55), CY+int(R*0.15)),
             (CX-int(R*0.05), CY+int(R*0.15)), (CX-int(R*0.25), CY+int(R*0.95)),
             (CX+int(R*0.55), CY-int(R*0.2)), (CX+int(R*0.05), CY-int(R*0.2))], fill=W)

def em_used_plus(d, L):
    def draw(td, tl):
        w = int(R*1.5); h = int(R*0.85)
        x0 = CX - w//2; y0 = CY - h//2
        poly(td, [(x0, y0), (x0+w-int(h*0.6), y0), (x0+w, CY), (x0+w-int(h*0.6), y0+h), (x0, y0+h)], fill=W)
        circle(td, x0+int(h*0.5), CY, int(R*0.14), fill=DETAIL)
    rotate_layer(draw, -18)(d, L)
    # plus
    line(d, (CX+int(R*0.45), CY-int(R*0.3)), (CX+int(R*0.45), CY+int(R*0.1)), R*0.12, fill=DETAIL)

def em_invoice(d, L):
    w = int(R*1.05); h = int(R*1.35)
    x0 = CX - w//2; y0 = CY - h//2
    # receipt with zigzag bottom
    body = [(x0, y0+h)]
    zig = 5; zw = w/zig
    for i in range(zig+1):
        zx = x0 + i*zw
        zy = y0 + h - (int(R*0.12) if i % 2 == 0 else 0)
        body.append((zx, zy))
    body += [(x0+w, y0), (x0, y0)]
    poly(d, body, fill=W)
    for i in range(3):
        yy = y0 + int(h*0.28) + i*int(h*0.2)
        line(d, (x0+int(w*0.2), yy), (x0+int(w*0.8), yy), R*0.07, fill=DETAIL)

# ── app registry (id -> (accent 0..1, emblem)) ────────────
ICONS = {
    "dashboard":            ((0.16, 0.76, 0.38), em_dashboard),
    "app_store":            ((0.30, 0.65, 1.00), em_store),
    "settings":             ((0.60, 0.62, 0.70), em_settings),
    "updates":              ((1.00, 0.72, 0.10), em_updates),
    "weather":              ((0.35, 0.72, 1.00), em_weather),
    "field_status":         ((0.45, 0.85, 0.30), em_fields),
    "animals":              ((1.00, 0.62, 0.22), em_animals),
    "workshop":             ((0.90, 0.38, 0.38), em_wrench),
    "digging":              ((0.75, 0.55, 0.28), em_digging),
    "bucket_tracker":       ((0.80, 0.60, 0.25), em_bucket),
    "storage":              ((0.92, 0.78, 0.25), em_storage),
    "time_controls":        ((0.30, 0.78, 1.00), em_time),
    "hotspot_manager":      ((1.00, 0.72, 0.10), em_hotspot),
    "notes":                ((0.55, 0.90, 0.35), em_notes),
    "farm_admin":           ((0.95, 0.30, 0.30), em_admin),
    "field_jobs":           ((0.30, 0.75, 1.00), em_jobs),
    "contracts":            ((0.95, 0.72, 0.15), em_contracts),
    "fleet_manager":        ((0.20, 0.85, 0.78), em_fleet),
    "production_buildings": ((0.90, 0.62, 0.15), em_production),
    "farm_stats":           ((0.40, 0.88, 0.55), em_stats),
    "income_mod":           ((0.28, 0.90, 0.55), em_income),
    "tax_mod":              ((1.00, 0.40, 0.40), em_tax),
    "npc_favor":            ((0.80, 0.50, 1.00), em_npc),
    "crop_stress":          ((1.00, 0.80, 0.25), em_crop_stress),
    "soil_fertilizer":      ((0.55, 0.80, 0.40), em_soil),
    "field_sentry":         ((0.35, 0.82, 0.66), em_sentry),
    "market_dynamics":      ((0.30, 0.78, 0.95), em_market),
    "worker_costs":         ((0.95, 0.58, 0.20), em_worker),
    "personnel":            ((0.95, 0.45, 0.30), em_personnel),
    "random_world_events":  ((0.70, 0.35, 0.90), em_events),
    "used_plus":            ((0.20, 0.78, 0.90), em_used_plus),
    "roleplay_phone":       ((0.90, 0.35, 0.85), em_invoice),
}

def render_icon(accent, emblem):
    canvas = make_base(accent)
    if emblem is not None:
        canvas = stamp_emblem(canvas, emblem)
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)

def make_wallpaper():
    w, h = 1024, 768
    img = Image.new("RGB", (w, h))
    px = img.load()
    top = (16, 22, 32); bot = (6, 8, 12)
    for y in range(h):
        t = y / float(h - 1)
        r = int(top[0] + (bot[0]-top[0]) * t)
        g = int(top[1] + (bot[1]-top[1]) * t)
        b = int(top[2] + (bot[2]-top[2]) * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    # soft radial glow upper-center
    glow = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([w*0.18, -h*0.35, w*0.82, h*0.55], fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    tint = Image.new("RGB", (w, h), (30, 90, 70))
    img = Image.composite(tint, img, glow)
    # vignette
    vig = Image.new("L", (w, h), 0)
    vd = ImageDraw.Draw(vig)
    vd.ellipse([-w*0.2, -h*0.2, w*1.2, h*1.2], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(160))
    dark = Image.new("RGB", (w, h), (0, 0, 0))
    img = Image.composite(img, dark, vig)
    img.convert("RGBA").save(WALL_OUT)
    print("  wallpaper.png")

def make_frame():
    # Rounded tablet body baked with transparency outside the radius, so the
    # tablet has a real rounded silhouette (rects can't round corners).
    # The BODY occupies the centre [mf .. 1-mf] of the texture; the outer margin
    # holds the soft drop shadow. FarmTabletUI renders it so the body maps to the
    # tablet rect (keep mf in sync with FarmTabletUI FRAME_MF).
    base_w, base_h = 768, 512          # 3:2, matches FT.REF_W:FT.REF_H
    ssf = 2
    cw, ch = base_w*ssf, base_h*ssf
    img = Image.new("RGBA", (cw, ch), (0,0,0,0))
    mf = 0.055
    bx0, by0 = int(cw*mf), int(ch*mf)
    bx1, by1 = int(cw*(1-mf)), int(ch*(1-mf))
    bw, bh = bx1-bx0, by1-by0
    rad = int(bw*0.05)

    # soft drop shadow (toward image bottom == screen bottom)
    sh = Image.new("L", (cw, ch), 0)
    soff = int(ch*0.016)
    ImageDraw.Draw(sh).rounded_rectangle([bx0, by0+soff, bx1, by1+soff], rad, fill=150)
    sh = sh.filter(ImageFilter.GaussianBlur(int(ch*0.028)))
    shadow = Image.new("RGBA", (cw, ch), (0,0,0,0)); shadow.putalpha(sh)
    img = Image.alpha_composite(img, shadow)

    # graphite body via vertical gradient, clipped to a rounded-rect mask
    mask = Image.new("L", (cw, ch), 0)
    ImageDraw.Draw(mask).rounded_rectangle([bx0, by0, bx1, by1], rad, fill=255)
    grad = Image.new("RGB", (cw, ch)); gp = grad.load()
    top, bot = (42,45,53), (15,17,22)
    for y in range(ch):
        t = max(0.0, min(1.0, (y-by0)/float(max(1, bh))))
        r = int(top[0]+(bot[0]-top[0])*t); g = int(top[1]+(bot[1]-top[1])*t); b = int(top[2]+(bot[2]-top[2])*t)
        for x in range(cw): gp[x, y] = (r, g, b)
    grad = grad.convert("RGBA"); grad.putalpha(mask)
    img = Image.alpha_composite(img, grad)

    # top-half rim glint
    glint = Image.new("RGBA", (cw, ch), (0,0,0,0))
    ImageDraw.Draw(glint).rounded_rectangle([bx0, by0, bx1, by1], rad, outline=(255,255,255,42), width=max(2, ssf*2))
    gm = Image.new("L", (cw, ch), 0)
    ImageDraw.Draw(gm).rectangle([0, by0, cw, by0 + bh//2], fill=255)
    glint.putalpha(Image.composite(glint.getchannel("A"), Image.new("L", (cw, ch), 0), gm))
    img = Image.alpha_composite(img, glint)

    d = ImageDraw.Draw(img)
    # screen recess (glass) — content is drawn over this in-game; bezel fractions
    # match FT BEZEL_REF/REF_W and /REF_H so the recess lines up with the screen.
    bezelx, bezely = int(bw*0.0444), int(bh*0.0667)
    sx0, sy0, sx1, sy1 = bx0+bezelx, by0+bezely, bx1-bezelx, by1-bezely
    srad = int(rad*0.55)
    d.rounded_rectangle([sx0, sy0, sx1, sy1], srad, fill=(5,7,10,255))
    rec = Image.new("RGBA", (cw, ch), (0,0,0,0))
    ImageDraw.Draw(rec).rounded_rectangle([sx0, sy0, sx1, sy1], srad, outline=(0,0,0,150), width=max(2, ssf*2))
    img = Image.alpha_composite(img, rec)

    d = ImageDraw.Draw(img)
    # camera dot in the top bezel
    camcx = (bx0+bx1)//2; camcy = by0 + bezely//2
    d.ellipse([camcx-ssf*4, camcy-ssf*4, camcx+ssf*4, camcy+ssf*4], fill=(10,12,16,255))
    d.ellipse([camcx-ssf*1, camcy-ssf*1, camcx+ssf*2, camcy+ssf*2], fill=(70,95,125,255))
    # speaker grille in the left bezel
    spx = bx0 + bezelx//2
    for i in range(6):
        sy = (by0+by1)//2 - ssf*22 + i*ssf*9
        d.rectangle([spx-ssf, sy, spx+ssf, sy+ssf*3], fill=(8,9,12,255))
    # side hardware nubs straddling the right edge
    rbx = bx1 - ssf*1
    d.rounded_rectangle([rbx, int(by0+bh*0.16), rbx+ssf*4, int(by0+bh*0.30)], ssf*2, fill=(28,31,38,255))
    d.rounded_rectangle([rbx, int(by0+bh*0.38), rbx+ssf*4, int(by0+bh*0.50)], ssf*2, fill=(28,31,38,255))

    img = img.resize((base_w, base_h), Image.LANCZOS)
    img.save(os.path.join(MOD_DIR, "gui", "tablet_frame.png"))
    print("  tablet_frame.png")

def main():
    print("Generating %d app icons at %dpx (SS x%d)..." % (len(ICONS), SIZE, SS))
    rendered = {}
    for app_id, (accent, emblem) in ICONS.items():
        ic = render_icon(accent, emblem)
        ic.save(os.path.join(OUT_DIR, app_id + ".png"))
        rendered[app_id] = ic
    # fallback: neutral tile, no emblem (UI draws a monogram on top)
    fb = render_icon((0.45, 0.48, 0.55), None)
    fb.save(os.path.join(OUT_DIR, "_fallback.png"))
    rendered["_fallback"] = fb
    print("  %d icons + _fallback.png written to gui/icons/" % len(ICONS))

    make_wallpaper()
    make_frame()

    # contact sheet for QA
    cols = 8
    ids = list(ICONS.keys()) + ["_fallback"]
    rows = (len(ids) + cols - 1) // cols
    pad = 12
    cell = SIZE + pad
    sheet = Image.new("RGBA", (cols * cell + pad, rows * cell + pad), (24, 26, 32, 255))
    for i, app_id in enumerate(ids):
        cx = pad + (i % cols) * cell
        cy = pad + (i // cols) * cell
        sheet.alpha_composite(rendered[app_id], (cx, cy))
    sheet.save(SHEET)
    print("  contact sheet -> tools/_contact_sheet.png")

if __name__ == "__main__":
    main()
