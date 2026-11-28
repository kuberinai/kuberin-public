#!/usr/bin/env python3
"""Render slide images for the Poor Charlie's Almanack narration."""
import json, os
from PIL import Image, ImageDraw, ImageFont

BASE = os.path.dirname(os.path.abspath(__file__))
IMG_DIR = os.path.join(BASE, "img")
os.makedirs(IMG_DIR, exist_ok=True)

W, H = 1920, 1080
# Colors: warm "old paper / leather" palette
BG_TOP = (24, 22, 28)
BG_BOT = (44, 38, 34)
GOLD = (201, 162, 96)        # muted gold
PAPER = (240, 233, 220)      # warm off-white text
MUTED = (170, 160, 145)
ACCENT = (190, 120, 90)      # terracotta

GEORGIA = "/System/Library/Fonts/Georgia.ttf"
GEORGIA_B = "/System/Library/Fonts/Georgia Bold.ttf"
GEORGIA_I = "/System/Library/Fonts/Georgia Italic.ttf"
FUTURA = "/System/Library/Fonts/Futura.ttc"

def font(path, size, index=0):
    try:
        return ImageFont.truetype(path, size, index=index)
    except Exception:
        return ImageFont.truetype(GEORGIA, size)

def gradient():
    img = Image.new("RGB", (W, H), BG_TOP)
    px = img.load()
    for y in range(H):
        t = y / H
        r = int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
        g = int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
        b = int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
        for x in range(W):
            px[x, y] = (r, g, b)
    return img

def wrap(draw, text, f, max_w):
    words = text.split()
    lines, cur = [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if draw.textlength(trial, font=f) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines

def draw_text_block(draw, lines, f, x, y, line_h, fill, align="left"):
    for ln in lines:
        if align == "center":
            w = draw.textlength(ln, font=f)
            draw.text(((W - w) / 2, y), ln, font=f, fill=fill)
        elif align == "right":
            w = draw.textlength(ln, font=f)
            draw.text((x - w, y), ln, font=f, fill=fill)
        else:
            draw.text((x, y), ln, font=f, fill=fill)
        y += line_h
    return y

def make(seg, idx, total):
    img = gradient()
    d = ImageDraw.Draw(img)
    t = seg["type"]
    lx = 140
    kicker = seg.get("kicker", "")
    title = seg.get("title", "")
    subtitle = seg.get("subtitle", "")

    # decorative top/bottom rules
    d.line([(140, 150), (W - 140, 150)], fill=GOLD, width=3)
    d.line([(140, H - 150), (W - 140, H - 150)], fill=GOLD, width=3)

    if t in ("title", "outro"):
        # Centered big display
        d.text(((W) / 2 - d.textlength(kicker, font=font(FUTURA, 30, 0)) / 2, 330),
               kicker, font=font(FUTURA, 30, 0), fill=GOLD)
        tf = font(GEORGIA_B, 118)
        tl = wrap(d, title, tf, W - 360)
        draw_text_block(d, tl, tf, W / 2, 430, 130, PAPER, "center")
        if subtitle:
            sf = font(GEORGIA_I, 46)
            sl = wrap(d, subtitle, sf, W - 360)
            y0 = 430 + 130 * len(tl) + 30
            draw_text_block(d, sl, sf, W / 2, y0, 62, MUTED, "center")
    else:
        # Lesson layout: left column
        lx = 140
        # Kicker
        d.text((lx, 210), kicker, font=font(FUTURA, 34, 0), fill=ACCENT)
        d.line([(lx, 260), (lx + 120, 260)], fill=GOLD, width=4)
        # Title (may wrap)
        tf = font(GEORGIA_B, 92)
        tl = wrap(d, title, tf, W - 2 * lx - 60)
        y = 300
        y = draw_text_block(d, tl, tf, lx, y, 104, PAPER)
        # Subtitle in italic, under a thin rule
        if subtitle:
            y += 30
            d.line([(lx, y), (W - lx, y)], fill=(90, 80, 70), width=2)
            y += 30
            sf = font(GEORGIA_I, 44)
            sl = wrap(d, subtitle, sf, W - 2 * lx)
            y = draw_text_block(d, sl, sf, lx, y, 60, GOLD)
        # Big faded lesson number in the background right side
        num = kicker.replace("LESSON ", "")
        nf = font(GEORGIA_B, 520)
        nw = d.textlength(num, font=nf)
        d.text((W - 140 - nw, 180), num, font=nf, fill=(60, 54, 48))

    # Footer
    foot = "Poor Charlie's Almanack \u2022 The Essence"
    ff = font(GEORGIA_I, 26)
    d.text((lx, H - 118), foot, font=ff, fill=MUTED)
    # page indicator
    pg = f"{idx + 1:02d} / {total:02d}"
    pgw = d.textlength(pg, font=ff)
    d.text((W - lx - pgw, H - 118), pg, font=ff, fill=MUTED)

    out = os.path.join(IMG_DIR, f"slide_{idx:02d}.png")
    img.save(out, "PNG")
    return out

def main():
    segs = json.load(open(os.path.join(BASE, "segments.json")))
    total = len(segs)
    for i, s in enumerate(segs):
        out = make(s, i, total)
        print("wrote", os.path.basename(out))
    print("DONE", total, "slides")

if __name__ == "__main__":
    main()
