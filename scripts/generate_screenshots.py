"""
NewsFlow screenshot generator — pulls live data from NewsAPI, renders clean iOS-style mockups.
"""

import os, sys, textwrap, warnings
warnings.filterwarnings("ignore")

import requests
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ── Config ────────────────────────────────────────────────────────────────────
API_KEY = "4ed36b1d0c034715ac08b796267b39d3"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "screenshots")
os.makedirs(OUT_DIR, exist_ok=True)

# Canvas: iPhone 15 logical size @2x
W, H, S = 390, 844, 2
CW, CH  = W * S, H * S

# ── Palette (iOS system colours) ─────────────────────────────────────────────
BG        = (242, 242, 247)
CARD      = (255, 255, 255)
INDIGO    = (88,  86,  214)
INDIGO_DK = (63,  60,  170)
LABEL     = (0,   0,   0)
SEC_LABEL = (142, 142, 147)
TERT      = (174, 174, 178)
SEP       = (198, 198, 200)
NAV       = (249, 249, 249)
RED       = (210,  35,  35)
GREEN     = (52,  199,  89)
WHITE     = (255, 255, 255)

def p(n):            return int(n * S)
def box(x,y,w,h):   return [p(x), p(y), p(x+w), p(y+h)]

# ── Fonts ─────────────────────────────────────────────────────────────────────
def font(size, bold=False):
    paths = [
        "/System/Library/Fonts/SFNSDisplay.ttf" if bold else "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in paths:
        try: return ImageFont.truetype(path, p(size))
        except: pass
    return ImageFont.load_default()

F34B = font(34, True);  F20B = font(20, True);  F17B = font(17, True)
F15B = font(15, True);  F15  = font(15);         F13B = font(13, True)
F12  = font(12);        F11  = font(11);         F11B = font(11, True)

# ── Drawing helpers ───────────────────────────────────────────────────────────
def text(draw, t, x, y, fnt, color=LABEL, anchor="la"):
    draw.text((p(x), p(y)), str(t), font=fnt, fill=color, anchor=anchor)

def rrect(draw, bx, radius, fill=None, outline=None, ow=1):
    draw.rounded_rectangle([int(v) for v in bx], radius=p(radius),
                            fill=fill, outline=outline, width=p(ow))

# ── Chrome components ─────────────────────────────────────────────────────────
def status_bar(draw):
    draw.rectangle([0, 0, CW, p(44)], fill=NAV)
    text(draw, "9:41", W//2, 15, F11B, LABEL, "mm")
    # Signal bars
    for i in range(4):
        h = p(2 + i * 2.5)
        draw.rectangle([p(18 + i*5), p(20)-h, p(21 + i*5), p(20)], fill=LABEL)
    # Battery
    bx, by = p(W-47), p(11)
    draw.rounded_rectangle([bx, by, bx+p(24), by+p(11)],
                             radius=p(2), outline=LABEL, width=p(1))
    draw.rectangle([bx+p(1), by+p(1), bx+p(19), by+p(10)], fill=GREEN)

def nav_large(draw, title):
    draw.rectangle([0, p(44), CW, p(132)], fill=NAV)
    draw.line([0, p(132), CW, p(132)], fill=SEP, width=p(0.5))
    text(draw, title, 18, 100, F34B, LABEL, "lb")

def nav_small(draw, title, back_label="Back"):
    draw.rectangle([0, p(44), CW, p(88)], fill=NAV)
    draw.line([0, p(88), CW, p(88)], fill=SEP, width=p(0.5))
    text(draw, f"< {back_label}", 16, 66, F15, INDIGO, "lm")
    text(draw, title, W//2, 66, F15B, LABEL, "mm")

def tab_bar(draw, active=0):
    ty = H - 82
    draw.rectangle([0, p(ty), CW, CH], fill=NAV)
    draw.line([0, p(ty), CW, p(ty)], fill=SEP, width=p(0.5))
    tabs = [("Headlines", "newspaper"), ("Search", "magnifyingglass"), ("Bookmarks", "bookmark")]
    for i, (label, _) in enumerate(tabs):
        cx = W // 3 * i + W // 6
        c  = INDIGO if i == active else SEC_LABEL
        # SF Symbol placeholder as text
        icons = ["⊟", "⌕", "⊕"]
        text(draw, icons[i], cx, ty + 14, F17B, c, "mm")
        text(draw, label,    cx, ty + 32, F11,  c, "mm")

# ── Image loading ─────────────────────────────────────────────────────────────
def load_remote(url, size):
    if not url: return None
    try:
        from io import BytesIO
        r = requests.get(url, timeout=7)
        img = Image.open(BytesIO(r.content)).convert("RGB")
        return img.resize(size, Image.LANCZOS)
    except:
        return None

def gradient_placeholder(size, top=(88,86,214), bottom=(50,45,150)):
    img = Image.new("RGB", size)
    for y in range(size[1]):
        t = y / size[1]
        r = int(top[0] + (bottom[0]-top[0])*t)
        g = int(top[1] + (bottom[1]-top[1])*t)
        b = int(top[2] + (bottom[2]-top[2])*t)
        ImageDraw.Draw(img).line([(0,y),(size[0],y)], fill=(r,g,b))
    return img

def rounded_paste(canvas, img, pos, radius_pt):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0]-1, img.size[1]-1], radius=p(radius_pt), fill=255)
    canvas.paste(img, pos, mask)

# ── API fetch ─────────────────────────────────────────────────────────────────
def fetch_headlines(category="general"):
    url = (f"https://newsapi.org/v2/top-headlines"
           f"?country=us&category={category}&pageSize=8&apiKey={API_KEY}")
    try:
        data = requests.get(url, timeout=12).json()
        if data.get("status") != "ok":
            print(f"  API error: {data.get('message')}")
            return []
        return [a for a in data.get("articles", [])
                if a.get("title") and "[Removed]" not in a["title"]][:6]
    except Exception as e:
        print(f"  Fetch error: {e}"); return []

def fetch_search(q="technology"):
    url = (f"https://newsapi.org/v2/everything"
           f"?q={q}&sortBy=publishedAt&pageSize=5&apiKey={API_KEY}")
    try:
        data = requests.get(url, timeout=12).json()
        return [a for a in data.get("articles", [])
                if a.get("title") and "[Removed]" not in a["title"]][:4]
    except:
        return []

# ── Easter egg ────────────────────────────────────────────────────────────────
EASTER_EGG = {
    "source": {"name": "Cairo Tech Daily"},
    "title":  "Breaking: iOS Dev Alfawakhry Applies to BlackStone eIT — Insiders Call It a Perfect Match",
    "publishedAt": "Just now",
    "urlToImage": None,
}

# ── Card rendering ─────────────────────────────────────────────────────────────
def draw_hero(canvas, article, y_start, badge_text, badge_color):
    """260pt tall full-width hero card with gradient overlay."""
    m, ch = 16, 244
    draw  = ImageDraw.Draw(canvas)
    card_w, card_h = W - m*2, ch

    # Shadow (draw before image)
    sh = Image.new("RGBA", (CW, p(ch+16)), (0,0,0,0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [p(m-2), p(4), p(W-m+2), p(ch+4)], radius=p(18), fill=(0,0,0,25))
    sh = sh.filter(ImageFilter.GaussianBlur(p(6)))
    canvas.paste(sh, (0, p(y_start-4)), sh)

    # Image or gradient
    img_size = (p(card_w), p(card_h))
    img = load_remote(article.get("urlToImage"), img_size) \
          or gradient_placeholder(img_size)

    # Bottom gradient overlay
    overlay = Image.new("RGBA", img_size, (0,0,0,0))
    od = ImageDraw.Draw(overlay)
    third = img_size[1] // 3
    for row in range(third, img_size[1]):
        alpha = int(190 * (row - third) / (img_size[1] - third))
        od.line([(0,row),(img_size[0],row)], fill=(0,0,0,min(alpha,190)))
    img_rgba = img.convert("RGBA")
    img_rgba.alpha_composite(overlay)

    rounded_paste(canvas, img_rgba.convert("RGB"), (p(m), p(y_start)), 18)
    draw = ImageDraw.Draw(canvas)

    # Badge
    badge_pad = p(8)
    tw = draw.textlength(badge_text, font=F11B)
    badge_w = int(tw) + badge_pad * 2
    rrect(draw, [p(m+12), p(y_start+14), p(m+12)+badge_w, p(y_start+14)+p(22)], 6, badge_color)
    text(draw, badge_text, m+12+8, y_start+25, F11B, WHITE, "lm")

    # Bookmark
    text(draw, "○", W-m-16, y_start+14, F17B, WHITE, "mm")

    # Title — 3 lines max, ellipsis on last line if truncated
    title_str   = (article.get("title") or "")
    all_lines   = textwrap.wrap(title_str, 34)
    title_lines = all_lines[:3]
    if len(all_lines) > 3:
        title_lines[2] = title_lines[2][:28].rstrip() + "…"
    title_bot = y_start + ch - 16
    title_top = title_bot - len(title_lines) * 24 - 28
    for i, line in enumerate(title_lines):
        text(draw, line, m+12, title_top + i*24, F17B, WHITE)

    # Source
    src = article.get("source", {}).get("name", "")
    text(draw, src, m+12, y_start+ch-14, F12, (210,210,255), "lb")

def draw_article_card(canvas, article, y_start, bookmarked=False):
    """110pt tall article row card."""
    m, ch = 16, 98
    draw  = ImageDraw.Draw(canvas)

    # Shadow
    sh = Image.new("RGBA", (CW, p(ch+8)), (0,0,0,0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [p(m-2), p(3), p(W-m+2), p(ch+3)], radius=p(14), fill=(0,0,0,18))
    sh = sh.filter(ImageFilter.GaussianBlur(p(4)))
    canvas.paste(sh, (0, p(y_start-3)), sh)

    # Card background
    rrect(draw, box(m, y_start, W-m*2, ch), 14, CARD)

    # Thumbnail
    thumb_size = (p(76), p(76))
    thumb = load_remote(article.get("urlToImage"), thumb_size) \
            or Image.new("RGB", thumb_size, (200,200,210))
    rounded_paste(canvas, thumb, (p(m+10), p(y_start+11)), 10)

    draw = ImageDraw.Draw(canvas)

    # Title (2 lines max)
    tx = m + 10 + 76 + 12
    title = article.get("title", "")
    for i, line in enumerate(textwrap.wrap(title, 30)[:2]):
        text(draw, line, tx, y_start+13+i*20, F15B, LABEL)

    # Source
    src = article.get("source",{}).get("name","")
    text(draw, src, tx, y_start+58, F13B, INDIGO)

    # Date
    pub = article.get("publishedAt","")[:10]
    text(draw, pub, tx, y_start+76, F11, TERT)

    # Bookmark icon
    bm_color = INDIGO if bookmarked else SEP
    bm_icon  = "■" if bookmarked else "□"
    text(draw, bm_icon, W-m-12, y_start+ch//2, F15B, bm_color, "mm")

# ── Screens ───────────────────────────────────────────────────────────────────
def screen_headlines(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)
    status_bar(draw)
    nav_large(draw, "Top Headlines")

    # Category chips — y=140
    chip_y, cx = 140, 16
    cats = [("General", True), ("Technology", False), ("Business", False),
            ("Science", False), ("Health", False)]
    for name, selected in cats:
        tw  = int(draw.textlength(name, font=F13B)) + p(28)
        rrect(draw, [p(cx), p(chip_y), p(cx)+tw, p(chip_y)+p(32)], 16,
              fill=INDIGO if selected else CARD,
              outline=INDIGO if selected else SEP, ow=1.2)
        text(draw, name, cx + tw//p(1)//2, chip_y+16, F13B,
             WHITE if selected else LABEL, "mm")
        cx += tw//p(1) + 8

    # Easter egg hero card
    draw_hero(canvas, EASTER_EGG, 182, "🚨 BREAKING", RED)

    # Real articles below
    cy = 182 + 252
    for a in articles[:2]:
        draw_article_card(canvas, a, cy); cy += 110

    tab_bar(draw, 0)
    return canvas

def screen_detail(article):
    canvas = Image.new("RGB", (CW, CH), WHITE)
    draw   = ImageDraw.Draw(canvas)
    status_bar(draw)
    nav_small(draw, article.get("source",{}).get("name",""))

    # Hero image
    hero_h = 210
    hero_img = load_remote(article.get("urlToImage"), (CW, p(hero_h))) \
               or gradient_placeholder((CW, p(hero_h)))

    # Bottom-to-top gradient on hero
    ov = Image.new("RGBA", hero_img.size, (0,0,0,0))
    for row in range(hero_img.size[1]//2, hero_img.size[1]):
        a = int(140 * (row - hero_img.size[1]//2) / (hero_img.size[1]//2))
        ImageDraw.Draw(ov).line([(0,row),(hero_img.size[0],row)], fill=(0,0,0,a))
    h2 = hero_img.convert("RGBA"); h2.alpha_composite(ov)
    canvas.paste(h2.convert("RGB"), (0, p(88)))

    draw = ImageDraw.Draw(canvas)

    # Bookmark button top-right
    text(draw, "○", W-18, 66, F17B, INDIGO, "mm")

    # Title
    ty = 88 + hero_h + 20
    title = article.get("title","")
    for i, line in enumerate(textwrap.wrap(title, 34)[:3]):
        text(draw, line, 18, ty + i*27, F20B, LABEL)

    # Meta row
    my = ty + len(textwrap.wrap(title,34)[:3]) * 27 + 14
    src = article.get("source",{}).get("name","")
    pub = article.get("publishedAt","")[:10]
    draw.rectangle([p(18), p(my), p(18+3), p(my+34)], fill=INDIGO)  # accent bar
    text(draw, src, 26, my+4,  F13B, INDIGO)
    text(draw, pub, 26, my+20, F12,  SEC_LABEL)

    # Description
    dy = my + 50
    desc = (article.get("description") or article.get("content") or "")[:400]
    for i, line in enumerate(textwrap.wrap(desc, 42)[:7]):
        text(draw, line, 18, dy+i*21, F15, LABEL)

    # Read Full Article button
    btn_y = H - 82 - 72
    rrect(draw, box(18, btn_y, W-36, 50), 14, INDIGO)
    text(draw, "Read Full Article  →", W//2, btn_y+25, F15B, WHITE, "mm")

    tab_bar(draw, 0)
    return canvas

def screen_search(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)
    status_bar(draw)
    nav_large(draw, "Search")

    # Search bar
    rrect(draw, box(16, 140, W-32, 38), 12, (228,228,230))
    text(draw, "⌕   Search articles…", 32, 159, F15, SEC_LABEL, "lm")

    cy = 192
    for a in articles[:4]:
        draw_article_card(canvas, a, cy); cy += 110

    tab_bar(draw, 1)
    return canvas

def screen_bookmarks(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)
    status_bar(draw)
    nav_large(draw, "Bookmarks")

    cy = 142
    draw_article_card(canvas, EASTER_EGG, cy, bookmarked=True); cy += 110
    for a in articles[:3]:
        draw_article_card(canvas, a, cy, bookmarked=True); cy += 110

    tab_bar(draw, 2)
    return canvas

# ── Device frame ──────────────────────────────────────────────────────────────
def device_frame(canvas):
    pad_x, pad_y = p(7), p(14)
    fw, fh = CW + pad_x*2, CH + pad_y*2
    frame  = Image.new("RGB", (fw, fh), (26, 26, 28))
    mask   = Image.new("L",   (fw, fh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,fw-1,fh-1], radius=p(46), fill=255)
    result = Image.new("RGB", (fw, fh), (26, 26, 28))
    result.paste(frame, mask=mask)
    result.paste(canvas, (pad_x, pad_y))

    # Dynamic Island
    di_w, di_h = p(118), p(32)
    di_x = (fw - di_w) // 2
    ImageDraw.Draw(result).rounded_rectangle(
        [di_x, pad_y + p(4), di_x+di_w, pad_y+p(4)+di_h],
        radius=p(16), fill=(18, 18, 20))
    return result

def save(img, name):
    # Final export at a clean display size
    tw, th = W + 14, H + 28
    img = img.resize((tw*2, th*2), Image.LANCZOS)
    path = os.path.join(OUT_DIR, f"{name}.png")
    img.save(path, "PNG", optimize=True)
    print(f"  ✓  {path}")

# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print(f"Fetching from NewsAPI (key: {API_KEY[:8]}…)")
    headlines = fetch_headlines("general")
    tech      = fetch_headlines("technology")
    search    = fetch_search("technology")

    if not headlines:
        print("ERROR: No data returned. Check API key or network.")
        sys.exit(1)

    print(f"  ✓ {len(headlines)} general headlines")
    print(f"  ✓ {len(search)} search results")
    print("Rendering screens…")

    save(device_frame(screen_headlines(headlines)),      "1_headlines")
    save(device_frame(screen_detail(headlines[0])),      "2_detail")
    save(device_frame(screen_search(search or tech)),    "3_search")
    save(device_frame(screen_bookmarks(headlines[:3])),  "4_bookmarks")
    print("All done.")
