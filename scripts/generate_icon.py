"""
Generates a 1024x1024 AppIcon.png for NewsFlow.
Design: deep indigo gradient, bold "NF" monogram, subtle newspaper texture lines.
"""
import os, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SIZE   = 1024
OUT    = os.path.join(os.path.dirname(__file__), "..", "NewsFlow", "Assets.xcassets",
                      "AppIcon.appiconset", "AppIcon.png")
os.makedirs(os.path.dirname(OUT), exist_ok=True)

img  = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ── Background gradient (indigo → deep purple) ─────────────────────────────
bg = Image.new("RGB", (SIZE, SIZE))
for y in range(SIZE):
    t   = y / SIZE
    r   = int(58  + t * (88  - 58))
    g   = int(50  + t * (40  - 50))
    b   = int(200 + t * (160 - 200))
    ImageDraw.Draw(bg).line([(0, y), (SIZE, y)], fill=(r, g, b))

# Rounded-rect mask (iOS icon shape = 22.5% corner radius)
mask = Image.new("L", (SIZE, SIZE), 0)
r    = int(SIZE * 0.225)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, SIZE-1, SIZE-1], radius=r, fill=255)

img.paste(bg, mask=mask)
draw = ImageDraw.Draw(img)

# ── Subtle diagonal newspaper lines ────────────────────────────────────────
line_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ld = ImageDraw.Draw(line_img)
for i in range(-SIZE, SIZE * 2, 48):
    ld.line([(i, 0), (i + SIZE, SIZE)], fill=(255, 255, 255, 12), width=2)
img.alpha_composite(line_img)
draw = ImageDraw.Draw(img)

# ── Glow circle behind monogram ────────────────────────────────────────────
cx, cy = SIZE // 2, SIZE // 2
glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
for radius in range(320, 140, -4):
    alpha = int(3 * (320 - radius) / 180)
    ImageDraw.Draw(glow).ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        fill=(180, 160, 255, alpha)
    )
img.alpha_composite(glow)
draw = ImageDraw.Draw(img)

# ── "NF" monogram ──────────────────────────────────────────────────────────
def load_font(size):
    for path in [
        "/System/Library/Fonts/SFNSDisplay.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            continue
    return ImageFont.load_default()

font = load_font(420)
text = "NF"

# Shadow layer
shadow_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow_img)
sd.text((cx + 6, cy + 8), text, font=font, fill=(0, 0, 0, 120), anchor="mm")
shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(12))
img.alpha_composite(shadow_img)
draw = ImageDraw.Draw(img)

# Main white text
draw.text((cx, cy - 30), text, font=font, fill=(255, 255, 255, 245), anchor="mm")

# ── Bottom tagline ─────────────────────────────────────────────────────────
tag_font = load_font(62)
draw.text((cx, cy + 270), "NewsFlow", font=tag_font,
          fill=(255, 255, 255, 160), anchor="mm")

# ── Fine border ring ───────────────────────────────────────────────────────
border_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ImageDraw.Draw(border_img).rounded_rectangle(
    [3, 3, SIZE-4, SIZE-4], radius=r,
    outline=(255, 255, 255, 40), width=6
)
img.alpha_composite(border_img)

# ── Save ───────────────────────────────────────────────────────────────────
final = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
final.paste(img.convert("RGB"), mask=img.split()[3])
final.save(OUT, "PNG", optimize=True)
print(f"✓ Icon saved → {OUT}")
