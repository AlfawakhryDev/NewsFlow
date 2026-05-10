"""
Generates realistic iOS UI screenshots for NewsFlow using live NewsAPI data.
Outputs 4 PNG files into ../screenshots/
"""

import os, sys, textwrap, math, warnings
warnings.filterwarnings("ignore")

import requests
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

API_KEY  = "4ed36b1d0c034715ac08b796267b39d3"
OUT_DIR  = os.path.join(os.path.dirname(__file__), "..", "screenshots")
os.makedirs(OUT_DIR, exist_ok=True)

# ── Canvas ──────────────────────────────────────────────────────────────────
W, H   = 390, 844          # iPhone 14 logical px
SCALE  = 3                 # render at @3x then downsample
CW, CH = W * SCALE, H * SCALE

# ── Colors ──────────────────────────────────────────────────────────────────
BG          = (242, 242, 247)   # systemGroupedBackground
CARD        = (255, 255, 255)
INDIGO      = (88,  86, 214)    # systemIndigo
LABEL       = (0,   0,   0)
SECONDARY   = (142, 142, 147)
SEPARATOR   = (198, 198, 200)
NAV_BG      = (249, 249, 249)
TAB_BG      = (249, 249, 249)
WHITE       = (255, 255, 255)
RED         = (255,  59,  48)
GREEN       = (52,  199,  89)

# ── Fonts ────────────────────────────────────────────────────────────────────
def load_font(size, bold=False):
    candidates = [
        f"/System/Library/Fonts/{'SFNSDisplay' if bold else 'SFNS'}.ttf",
        f"/System/Library/Fonts/{'SFNSText-Bold' if bold else 'SFNSText'}.otf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size * SCALE)
        except Exception:
            continue
    return ImageFont.load_default()

FONT_LG_BOLD  = load_font(34, bold=True)
FONT_MD_BOLD  = load_font(17, bold=True)
FONT_MD       = load_font(15)
FONT_SM_BOLD  = load_font(13, bold=True)
FONT_SM       = load_font(12)
FONT_XS       = load_font(11)

# ── Helpers ──────────────────────────────────────────────────────────────────
def px(n):   return n * SCALE
def rect(x,y,w,h): return [px(x), px(y), px(x+w), px(y+h)]

def rounded_rect(draw, box, radius, fill, outline=None, outline_width=1):
    x0,y0,x1,y1 = [int(v) for v in box]
    r = int(radius * SCALE)
    draw.rounded_rectangle([x0,y0,x1,y1], radius=r, fill=fill,
                            outline=outline, width=int(outline_width*SCALE))

def draw_text(draw, text, x, y, font, color=LABEL, anchor="la"):
    draw.text((px(x), px(y)), text, font=font, fill=color, anchor=anchor)

def wrap(text, max_chars):
    return textwrap.fill(text, max_chars)

def draw_status_bar(draw):
    draw.rectangle([0, 0, CW, px(44)], fill=NAV_BG)
    draw_text(draw, "9:41", W//2, 14, FONT_SM_BOLD, LABEL, anchor="mm")
    # Battery
    bx, by = px(W-46), px(10)
    draw.rounded_rectangle([bx, by, bx+px(25), by+px(12)], radius=px(2), outline=LABEL, width=px(1))
    draw.rectangle([bx+px(1), by+px(1), bx+px(20), by+px(11)], fill=GREEN)
    # Signal dots
    for i in range(4):
        h_bar = px(3 + i*2)
        draw.rectangle([px(18+i*5), px(20)-h_bar, px(21+i*5), px(20)], fill=LABEL)

def draw_nav_bar(draw, title, large=True, back=False):
    draw.rectangle([0, px(44), CW, px(44 + (88 if large else 44))], fill=NAV_BG)
    # Separator
    draw.line([0, px(44+(88 if large else 44)), CW, px(44+(88 if large else 44))],
              fill=SEPARATOR, width=px(1))
    if large:
        draw_text(draw, title, 18, 88, FONT_LG_BOLD, LABEL)
    else:
        draw_text(draw, title, W//2, 66, FONT_MD_BOLD, LABEL, anchor="mm")
    if back:
        draw_text(draw, "‹  Back", 18, 66, FONT_MD, INDIGO, anchor="lm")

def draw_tab_bar(draw, active=0):
    tb_y = H - 83
    draw.rectangle([0, px(tb_y), CW, CH], fill=TAB_BG)
    draw.line([0, px(tb_y), CW, px(tb_y)], fill=SEPARATOR, width=px(1))
    tabs = [("Headlines", "⊟"), ("Search", "⌕"), ("Bookmarks", "⊕")]
    tab_w = W // len(tabs)
    for i, (label, icon) in enumerate(tabs):
        cx = tab_w * i + tab_w // 2
        color = INDIGO if i == active else SECONDARY
        draw_text(draw, icon, cx, tb_y + 12, FONT_MD_BOLD, color, anchor="mm")
        draw_text(draw, label, cx, tb_y + 28, FONT_XS, color, anchor="mm")

def fetch_image(url, size):
    """Download and resize an image, return PIL Image."""
    try:
        r = requests.get(url, timeout=8)
        from io import BytesIO
        img = Image.open(BytesIO(r.content)).convert("RGB")
        img = img.resize(size, Image.LANCZOS)
        return img
    except Exception:
        return None

def placeholder_thumb(size=(px(80), px(80))):
    img = Image.new("RGB", size, (200, 200, 205))
    return img

def draw_card(draw, canvas, article, y, bookmark_filled=False):
    """Draw a single article card at vertical position y."""
    card_m = 16
    card_h = 98
    # Card shadow / background
    shadow = Image.new("RGBA", (CW, px(card_h+4)), (0,0,0,0))
    sdraw  = ImageDraw.Draw(shadow)
    rounded_rect(sdraw, [px(card_m-2), px(2), px(W-card_m+2), px(card_h+2)],
                 12, (0,0,0,18))
    shadow = shadow.filter(ImageFilter.GaussianBlur(px(3)))
    canvas.paste(shadow, (0, px(y-2)), shadow)

    rounded_rect(draw, rect(card_m, y, W-card_m*2, card_h), 12, CARD)

    # Thumbnail
    img_size = (px(80), px(80))
    thumb = None
    if article.get("urlToImage"):
        thumb = fetch_image(article["urlToImage"], img_size)
    if thumb is None:
        thumb = placeholder_thumb(img_size)
    # Clip to rounded rect
    mask = Image.new("L", img_size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0,0,img_size[0]-1,img_size[1]-1],
                                            radius=px(8), fill=255)
    canvas.paste(thumb, (px(card_m+9), px(y+9)), mask)

    # Title
    title = (article.get("title") or "")[:80]
    lines = textwrap.wrap(title, 32)[:2]
    for li, line in enumerate(lines):
        draw_text(draw, line, 118, y + 12 + li*19, FONT_MD_BOLD, LABEL)

    # Source
    source = article.get("source", {}).get("name", "")
    draw_text(draw, source, 118, y + 56, FONT_SM_BOLD, INDIGO)

    # Date (simple)
    pub = (article.get("publishedAt") or "")[:10]
    draw_text(draw, pub, 118, y + 72, FONT_XS, SECONDARY)

    # Bookmark
    bm = "🔖" if bookmark_filled else "🔖"
    bm_icon = "■" if bookmark_filled else "□"
    bm_color = INDIGO if bookmark_filled else SECONDARY
    draw_text(draw, bm_icon, W - card_m - 14, y + card_h//2, FONT_MD, bm_color, anchor="mm")


# ── Fetch news ────────────────────────────────────────────────────────────────
def fetch_headlines(category="general"):
    url = (f"https://newsapi.org/v2/top-headlines?"
           f"country=us&category={category}&pageSize=6&apiKey={API_KEY}")
    try:
        data = requests.get(url, timeout=10).json()
        return [a for a in data.get("articles", []) if "[Removed]" not in a.get("title","")][:5]
    except Exception:
        return []

def fetch_search(q="technology"):
    url = (f"https://newsapi.org/v2/everything?"
           f"q={q}&sortBy=publishedAt&pageSize=4&apiKey={API_KEY}")
    try:
        data = requests.get(url, timeout=10).json()
        return [a for a in data.get("articles", []) if "[Removed]" not in a.get("title","")][:4]
    except Exception:
        return []

# ── Screen 1: Headlines ───────────────────────────────────────────────────────
def screen_headlines(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)

    draw_status_bar(draw)
    draw_nav_bar(draw, "Top Headlines", large=True)

    # Category chips
    chip_y    = 138
    chip_h    = 34
    cats      = ["General", "Technology", "Business", "Science", "Health"]
    cx        = 16
    for i, cat in enumerate(cats):
        tw    = len(cat) * 8 + 28
        color = INDIGO if i == 0 else CARD
        tc    = WHITE  if i == 0 else LABEL
        bc    = INDIGO if i == 0 else SEPARATOR
        rounded_rect(draw, rect(cx, chip_y, tw, chip_h), 17,
                     fill=color, outline=bc, outline_width=1.5)
        draw_text(draw, cat, cx + tw//2, chip_y + chip_h//2, FONT_SM_BOLD, tc, anchor="mm")
        cx += tw + 8

    # Article cards
    card_y = 184
    for article in articles[:4]:
        draw_card(draw, canvas, article, card_y)
        card_y += 110

    draw_tab_bar(draw, active=0)
    return canvas

# ── Screen 2: Article Detail ──────────────────────────────────────────────────
def screen_detail(article):
    canvas = Image.new("RGB", (CW, CH), (255,255,255))
    draw   = ImageDraw.Draw(canvas)

    draw_status_bar(draw)
    draw_nav_bar(draw, article.get("source",{}).get("name",""), large=False, back=True)

    # Hero image
    hero_y, hero_h = 88, 200
    hero = None
    if article.get("urlToImage"):
        hero = fetch_image(article["urlToImage"], (CW, px(hero_h)))
    if hero is None:
        hero = Image.new("RGB", (CW, px(hero_h)), (180, 180, 190))
    # Darken bottom edge
    overlay = Image.new("RGBA", hero.size, (0,0,0,0))
    for row in range(hero.size[1]//2, hero.size[1]):
        alpha = int(120 * (row - hero.size[1]//2) / (hero.size[1]//2))
        overlay.paste((0,0,0,alpha), (0, row, hero.size[0], row+1))
    hero = hero.convert("RGBA")
    hero.alpha_composite(overlay)
    canvas.paste(hero.convert("RGB"), (0, px(hero_y)))

    # Bookmark button (top right of nav)
    draw_text(draw, "□", W-20, 66, FONT_MD_BOLD, INDIGO, anchor="mm")

    # Title
    title = (article.get("title") or "")
    title_y = hero_y + hero_h + 18
    for i, line in enumerate(textwrap.wrap(title, 36)[:3]):
        draw_text(draw, line, 18, title_y + i*28, FONT_MD_BOLD, LABEL)

    # Meta
    meta_y = title_y + 100
    source = article.get("source",{}).get("name","")
    author = article.get("author") or ""
    meta   = f"{source}  ·  {author[:30]}" if author else source
    pub    = (article.get("publishedAt") or "")[:10]
    draw_text(draw, meta, 18, meta_y, FONT_SM, SECONDARY)
    draw_text(draw, pub,  18, meta_y+18, FONT_SM, SECONDARY)

    # Description
    desc = article.get("description") or article.get("content") or "No description available."
    desc_y = meta_y + 50
    for i, line in enumerate(textwrap.wrap(desc, 44)[:5]):
        draw_text(draw, line, 18, desc_y + i*22, FONT_MD, LABEL)

    # Read Full Article button
    btn_y = desc_y + 130
    rounded_rect(draw, rect(18, btn_y, W-36, 50), 14, INDIGO)
    draw_text(draw, "Read Full Article →", W//2, btn_y+25, FONT_MD_BOLD, WHITE, anchor="mm")

    draw_tab_bar(draw, active=0)
    return canvas

# ── Screen 3: Search ──────────────────────────────────────────────────────────
def screen_search(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)

    draw_status_bar(draw)
    draw_nav_bar(draw, "Search", large=True)

    # Search bar
    bar_y = 138
    rounded_rect(draw, rect(16, bar_y, W-32, 36), 10, (228, 228, 230))
    draw_text(draw, "⌕  Search articles…", 32, bar_y+18, FONT_MD, SECONDARY, anchor="lm")

    card_y = 186
    for article in articles[:4]:
        draw_card(draw, canvas, article, card_y)
        card_y += 110

    draw_tab_bar(draw, active=1)
    return canvas

# ── Screen 4: Bookmarks ───────────────────────────────────────────────────────
def screen_bookmarks(articles):
    canvas = Image.new("RGB", (CW, CH), BG)
    draw   = ImageDraw.Draw(canvas)

    draw_status_bar(draw)
    draw_nav_bar(draw, "Bookmarks", large=True)

    card_y = 138
    for article in articles[:3]:
        draw_card(draw, canvas, article, card_y, bookmark_filled=True)
        card_y += 110

    draw_tab_bar(draw, active=2)
    return canvas

# ── Main ──────────────────────────────────────────────────────────────────────
def add_device_frame(canvas):
    """Add a simple iPhone frame border."""
    framed = Image.new("RGB", (CW + px(12), CH + px(24)), (30, 30, 32))
    mask   = Image.new("L", framed.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, framed.size[0]-1, framed.size[1]-1], radius=px(44), fill=255)
    base = Image.new("RGB", framed.size, (30, 30, 32))
    base.paste(framed, mask=mask)
    base.paste(canvas, (px(6), px(12)))
    # Dynamic Island
    di_w, di_h = px(120), px(34)
    di_x = (framed.size[0] - di_w) // 2
    ImageDraw.Draw(base).rounded_rectangle(
        [di_x, px(14), di_x+di_w, px(14)+di_h], radius=px(17), fill=(20,20,22))
    return base

def save(img, name):
    # Downsample from @3x to a nice display size
    target_w = W + 12  # with frame margin
    target_h = H + 24
    img = img.resize((target_w * 2, target_h * 2), Image.LANCZOS)
    path = os.path.join(OUT_DIR, f"{name}.png")
    img.save(path, "PNG", optimize=True)
    print(f"  ✓  {path}")
    return path

if __name__ == "__main__":
    print("Fetching live news data…")
    headlines_data  = fetch_headlines("general")
    tech_data       = fetch_headlines("technology")
    search_data     = fetch_search("AI")

    bookmarks_data  = headlines_data[:3]

    if not headlines_data:
        print("ERROR: Could not fetch articles. Check API key / network.")
        sys.exit(1)

    print(f"Got {len(headlines_data)} headlines, {len(search_data)} search results")
    print("Rendering screenshots…")

    s1 = screen_headlines(headlines_data)
    s2 = screen_detail(headlines_data[0])
    s3 = screen_search(search_data or tech_data)
    s4 = screen_bookmarks(bookmarks_data)

    print("Saving…")
    save(add_device_frame(s1), "1_headlines")
    save(add_device_frame(s2), "2_detail")
    save(add_device_frame(s3), "3_search")
    save(add_device_frame(s4), "4_bookmarks")
    print("Done.")
