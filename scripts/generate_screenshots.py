"""
Generates realistic iOS UI screenshots for NewsFlow using live NewsAPI data.
Features the easter-egg breaking-news card as the hero article.
"""

import os, sys, textwrap, warnings
warnings.filterwarnings("ignore")

import requests
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

API_KEY  = "4ed36b1d0c034715ac08b796267b39d3"
OUT_DIR  = os.path.join(os.path.dirname(__file__), "..", "screenshots")
os.makedirs(OUT_DIR, exist_ok=True)

W, H   = 390, 844
SCALE  = 3
CW, CH = W * SCALE, H * SCALE

# ── Colors
BG       = (242, 242, 247)
CARD     = (255, 255, 255)
INDIGO   = (88,  86, 214)
LABEL    = (0,   0,   0)
SEC      = (142, 142, 147)
SEP      = (198, 198, 200)
NAV_BG   = (249, 249, 249)
WHITE    = (255, 255, 255)
RED      = (220,  38,  38)
GREEN    = (52,  199,  89)

def px(n): return n * SCALE
def rect(x,y,w,h): return [px(x), px(y), px(x+w), px(y+h)]

def load_font(size, bold=False):
    for path in [
        f"/System/Library/Fonts/{'SFNSDisplay' if bold else 'SFNS'}.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]:
        try: return ImageFont.truetype(path, size * SCALE)
        except: continue
    return ImageFont.load_default()

FB = load_font(34, True);  FM_B = load_font(17, True);  FM = load_font(15)
FSB = load_font(13, True); FS  = load_font(12);         FXS = load_font(11)
F20B = load_font(20, True); F22B = load_font(22, True)

def txt(draw, t, x, y, font, color=LABEL, anchor="la"):
    draw.text((px(x), px(y)), t, font=font, fill=color, anchor=anchor)

def rrect(draw, box, r, fill, outline=None, ow=1):
    draw.rounded_rectangle([int(v) for v in box], radius=int(r*SCALE),
                            fill=fill, outline=outline, width=int(ow*SCALE))

def status_bar(draw):
    draw.rectangle([0, 0, CW, px(44)], fill=NAV_BG)
    txt(draw, "9:41", W//2, 14, FSB, LABEL, "mm")
    for i in range(4):
        hb = px(3+i*2); draw.rectangle([px(18+i*5), px(20)-hb, px(21+i*5), px(20)], fill=LABEL)
    bx, by = px(W-46), px(10)
    draw.rounded_rectangle([bx,by,bx+px(25),by+px(12)], radius=px(2), outline=LABEL, width=px(1))
    draw.rectangle([bx+px(1),by+px(1),bx+px(20),by+px(11)], fill=GREEN)

def nav_bar(draw, title, large=True, back=False):
    h = 88 if large else 44
    draw.rectangle([0, px(44), CW, px(44+h)], fill=NAV_BG)
    draw.line([0, px(44+h), CW, px(44+h)], fill=SEP, width=px(1))
    if large: txt(draw, title, 18, 88, FB, LABEL)
    else:     txt(draw, title, W//2, 66, FM_B, LABEL, "mm")
    if back:  txt(draw, "‹  Back", 18, 66, FM, INDIGO, "lm")

def tab_bar(draw, active=0):
    ty = H - 83
    draw.rectangle([0, px(ty), CW, CH], fill=NAV_BG)
    draw.line([0, px(ty), CW, px(ty)], fill=SEP, width=px(1))
    for i, (label, icon) in enumerate([("Headlines","⊟"),("Search","⌕"),("Bookmarks","⊕")]):
        cx = W//(3) * i + W//6
        c  = INDIGO if i == active else SEC
        txt(draw, icon,  cx, ty+12, FM_B, c, "mm")
        txt(draw, label, cx, ty+28, FXS,  c, "mm")

def fetch_img(url, size):
    try:
        from io import BytesIO
        r = requests.get(url, timeout=8)
        return Image.open(BytesIO(r.content)).convert("RGB").resize(size, Image.LANCZOS)
    except: return None

def placeholder(size, color=(180,180,200)):
    return Image.new("RGB", size, color)

def draw_card(draw, canvas, article, y, bookmark_filled=False):
    m, ch = 16, 98
    # Shadow
    sh = Image.new("RGBA", (CW, px(ch+6)), (0,0,0,0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [px(m-2), px(2), px(W-m+2), px(ch+2)], radius=px(12), fill=(0,0,0,18))
    sh = sh.filter(ImageFilter.GaussianBlur(px(3)))
    canvas.paste(sh, (0, px(y-2)), sh)
    rrect(draw, rect(m, y, W-m*2, ch), 12, CARD)

    sz = (px(80), px(80))
    thumb = fetch_img(article.get("urlToImage"), sz) or placeholder(sz)
    mask  = Image.new("L", sz, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,sz[0]-1,sz[1]-1], radius=px(8), fill=255)
    canvas.paste(thumb, (px(m+9), px(y+9)), mask)

    for i, line in enumerate(textwrap.wrap((article.get("title") or "")[:80], 32)[:2]):
        txt(draw, line, 118, y+12+i*19, FM_B, LABEL)
    txt(draw, article.get("source",{}).get("name",""), 118, y+56, FSB, INDIGO)
    txt(draw, (article.get("publishedAt") or "")[:10], 118, y+72, FXS, SEC)
    bm_c = INDIGO if bookmark_filled else SEC
    txt(draw, "■" if bookmark_filled else "□", W-m-14, y+ch//2, FM, bm_c, "mm")

def draw_hero_card(draw, canvas, article, y, badge_text, badge_color):
    """Full-width hero card with gradient overlay — the featured article."""
    m, ch = 16, 240
    # Shadow
    sh = Image.new("RGBA", (CW, px(ch+8)), (0,0,0,0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [px(m-3), px(3), px(W-m+3), px(ch+4)], radius=px(18), fill=(0,0,0,30))
    sh = sh.filter(ImageFilter.GaussianBlur(px(5)))
    canvas.paste(sh, (0, px(y-3)), sh)

    # Hero image
    sz    = (px(W - m*2), px(ch))
    thumb = fetch_img(article.get("urlToImage"), sz)
    if thumb is None:
        thumb = Image.new("RGB", sz, (80, 60, 180))
    # Round-clip
    clip_mask = Image.new("L", sz, 0)
    ImageDraw.Draw(clip_mask).rounded_rectangle([0,0,sz[0]-1,sz[1]-1], radius=px(18), fill=255)
    canvas.paste(thumb, (px(m), px(y)), clip_mask)

    # Gradient overlay
    grad = Image.new("RGBA", sz, (0,0,0,0))
    gd   = ImageDraw.Draw(grad)
    for row in range(sz[1]//3, sz[1]):
        a = int(200 * (row - sz[1]//3) / (sz[1] * 2/3))
        gd.line([(0,row),(sz[0],row)], fill=(0,0,0,min(a,200)))
    thumb_rgba = thumb.convert("RGBA")
    thumb_rgba.alpha_composite(grad)
    canvas.paste(thumb_rgba.convert("RGB"), (px(m), px(y)), clip_mask)

    draw = ImageDraw.Draw(canvas)

    # Badge
    bw = len(badge_text)*px(7) + px(20)
    rrect(draw, [px(m+10), px(y+12), px(m+10)+bw, px(y+12)+px(22)], 6, badge_color)
    txt(draw, badge_text, m+10+4, y+23, FXS, WHITE, "lm")

    # Title
    title_lines = textwrap.wrap((article.get("title") or ""), 34)[:3]
    title_y = y + ch - 72
    for i, line in enumerate(title_lines):
        txt(draw, line, m+12, title_y + i*24, F20B, WHITE)

    # Source
    txt(draw, "✦  " + article.get("source",{}).get("name",""), m+12, y+ch-14, FS, (220,220,255), "lm")

    # Bookmark
    txt(draw, "□", W-m-18, y+18, FM_B, WHITE, "mm")

def fetch_headlines(category="general"):
    url = (f"https://newsapi.org/v2/top-headlines?"
           f"country=us&category={category}&pageSize=6&apiKey={API_KEY}")
    try:
        data = requests.get(url, timeout=10).json()
        return [a for a in data.get("articles",[]) if "[Removed]" not in a.get("title","")][:5]
    except: return []

def fetch_search(q="AI"):
    url = (f"https://newsapi.org/v2/everything?q={q}&sortBy=publishedAt&pageSize=4&apiKey={API_KEY}")
    try:
        data = requests.get(url, timeout=10).json()
        return [a for a in data.get("articles",[]) if "[Removed]" not in a.get("title","")][:4]
    except: return []

EASTER_EGG = {
    "source": {"name": "Cairo Tech Daily 🗞"},
    "author": "Newsroom",
    "title": "Breaking: iOS Dev Abdelrahman Alfawakhry Applies to BlackStone eIT — Insiders Say It's a Perfect Match",
    "description": "Cairo, Egypt — iOS developer Abdelrahman Alfawakhry has officially applied for the iOS Developer role at BlackStone eIT. Industry sources say it's 'a perfect match.'",
    "url": "https://github.com/AlfawakhryDev/NewsFlow",
    "urlToImage": None,
    "publishedAt": "2026-05-11",
}

def screen_headlines(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)
    status_bar(draw); nav_bar(draw, "Top Headlines")

    # Category chips
    chip_y, cx = 138, 16
    for i, cat in enumerate(["General","Technology","Business","Science","Health"]):
        tw = len(cat)*8+28
        rrect(draw, rect(cx,chip_y,tw,34), 17,
              INDIGO if i==0 else CARD,
              outline=INDIGO if i==0 else SEP, ow=1.5)
        txt(draw, cat, cx+tw//2, chip_y+17, FSB, WHITE if i==0 else LABEL, "mm")
        cx += tw+8

    # Easter egg as hero
    draw_hero_card(draw, canvas, EASTER_EGG, 184, "🚨 BREAKING", RED)
    # Regular cards below
    cy = 184 + 252
    for a in articles[:2]:
        draw_card(draw, canvas, a, cy); cy += 110

    tab_bar(draw, 0); return canvas

def screen_detail(article):
    canvas = Image.new("RGB", (CW, CH), WHITE)
    draw   = ImageDraw.Draw(canvas)
    status_bar(draw); nav_bar(draw, article.get("source",{}).get("name",""), large=False, back=True)

    hero_y, hero_h = 88, 210
    hero = fetch_img(article.get("urlToImage"), (CW, px(hero_h))) or \
           Image.new("RGB", (CW, px(hero_h)), (80,60,180))
    ov   = Image.new("RGBA", hero.size, (0,0,0,0))
    for row in range(hero.size[1]//2, hero.size[1]):
        a = int(130*(row-hero.size[1]//2)/(hero.size[1]//2))
        ov.paste((0,0,0,a),(0,row,hero.size[0],row+1))
    h2 = hero.convert("RGBA"); h2.alpha_composite(ov)
    canvas.paste(h2.convert("RGB"), (0, px(hero_y)))

    draw = ImageDraw.Draw(canvas)
    txt(draw, "□", W-20, 66, FM_B, INDIGO, "mm")

    ty = hero_y + hero_h + 18
    for i, line in enumerate(textwrap.wrap(article.get("title",""), 36)[:3]):
        txt(draw, line, 18, ty+i*28, FM_B, LABEL)

    my = ty + 96
    src = article.get("source",{}).get("name","")
    txt(draw, src + "  ·  " + (article.get("publishedAt","")[:10]), 18, my, FS, SEC)

    dy = my + 36
    for i, line in enumerate(textwrap.wrap(article.get("description","")[:300], 44)[:6]):
        txt(draw, line, 18, dy+i*22, FM, LABEL)

    btn_y = dy + 150
    rrect(draw, rect(18,btn_y,W-36,50), 14, INDIGO)
    txt(draw, "Read Full Article →", W//2, btn_y+25, FM_B, WHITE, "mm")

    tab_bar(draw, 0); return canvas

def screen_search(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)
    status_bar(draw); nav_bar(draw, "Search")
    rrect(draw, rect(16,138,W-32,36), 10, (228,228,230))
    txt(draw, "⌕  Search articles…", 32, 156, FM, SEC, "lm")
    cy = 186
    for a in articles[:4]: draw_card(draw, canvas, a, cy); cy += 110
    tab_bar(draw, 1); return canvas

def screen_bookmarks(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)
    status_bar(draw); nav_bar(draw, "Bookmarks")
    cy = 138
    # Easter egg bookmarked first
    draw_card(draw, canvas, EASTER_EGG, cy, bookmark_filled=True); cy += 110
    for a in articles[:2]: draw_card(draw, canvas, a, cy, True); cy += 110
    tab_bar(draw, 2); return canvas

def add_frame(canvas):
    pad_x, pad_y = px(6), px(12)
    frame = Image.new("RGB", (CW+pad_x*2, CH+pad_y*2), (28,28,30))
    mask  = Image.new("L", frame.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0,0,frame.size[0]-1,frame.size[1]-1], radius=px(44), fill=255)
    base = Image.new("RGB", frame.size, (28,28,30))
    base.paste(frame, mask=mask)
    base.paste(canvas, (pad_x, pad_y))
    # Dynamic Island
    dw,dh = px(120),px(34)
    dx = (frame.size[0]-dw)//2
    ImageDraw.Draw(base).rounded_rectangle(
        [dx,pad_y-px(2),dx+dw,pad_y-px(2)+dh], radius=px(17), fill=(18,18,20))
    return base

def save(img, name):
    img = img.resize(((W+12)*2,(H+24)*2), Image.LANCZOS)
    p   = os.path.join(OUT_DIR, f"{name}.png")
    img.save(p, "PNG", optimize=True)
    print(f"  ✓  {p}")

if __name__ == "__main__":
    print("Fetching live data…")
    hl = fetch_headlines("general")
    sr = fetch_search("AI")
    if not hl: print("ERROR: no data"); sys.exit(1)
    print(f"  {len(hl)} headlines, {len(sr)} search results")

    print("Rendering…")
    save(add_frame(screen_headlines(hl)),       "1_headlines")
    save(add_frame(screen_detail(hl[0])),       "2_detail")
    save(add_frame(screen_search(sr or hl)),    "3_search")
    save(add_frame(screen_bookmarks(hl)),       "4_bookmarks")
    print("Done.")
