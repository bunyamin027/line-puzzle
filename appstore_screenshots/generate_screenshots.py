#!/usr/bin/env python3
"""
Çizgi Bulmaca — App Store Screenshot Generator v2
Generates 1242×2688px marketing screenshots with gradient backgrounds,
headlines, and phone mockups. Uses overlay compositing for translucent elements.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# ───── CONFIGURATION ─────
SCREENSHOTS_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCREENSHOTS_DIR, "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

W, H = 1242, 2688
PHONE_W = 700
PHONE_RADIUS = 54
PHONE_BORDER = 8

# Brand colors
PURPLE = (108, 76, 245)
MINT = (58, 222, 176)
YELLOW = (255, 201, 60)
MAGENTA = (224, 64, 251)
RED = (255, 92, 92)
DARK_BG = (18, 16, 28)
DARK_MID = (30, 27, 58)

# ───── HELPER FUNCTIONS ─────

def create_gradient(width, height, colors):
    """Create a vertical gradient image with 2 or 3 color stops."""
    img = Image.new('RGBA', (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(height - 1, 1)
        if len(colors) == 2:
            r = int(colors[0][0] + (colors[1][0] - colors[0][0]) * t)
            g = int(colors[0][1] + (colors[1][1] - colors[0][1]) * t)
            b = int(colors[0][2] + (colors[1][2] - colors[0][2]) * t)
        else:
            if t < 0.5:
                t2 = t * 2
                r = int(colors[0][0] + (colors[1][0] - colors[0][0]) * t2)
                g = int(colors[0][1] + (colors[1][1] - colors[0][1]) * t2)
                b = int(colors[0][2] + (colors[1][2] - colors[0][2]) * t2)
            else:
                t2 = (t - 0.5) * 2
                r = int(colors[1][0] + (colors[2][0] - colors[1][0]) * t2)
                g = int(colors[1][1] + (colors[2][1] - colors[1][1]) * t2)
                b = int(colors[1][2] + (colors[2][2] - colors[1][2]) * t2)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
    return img

def add_glow(img, cx, cy, radius, color, alpha=60):
    """Add a radial glow effect."""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for r in range(radius, 0, -3):
        a = int(alpha * (1 - (r / radius) ** 2))
        if a < 1:
            continue
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(color[0], color[1], color[2], a))
    return Image.alpha_composite(img, overlay)

def add_circle_deco(img, cx, cy, radius, color, opacity=25):
    """Add a decorative circle via overlay."""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius],
                 fill=(color[0], color[1], color[2], opacity))
    return Image.alpha_composite(img, overlay)

def draw_translucent_rounded_rect(img, x1, y1, x2, y2, radius, fill_rgba, outline_rgba=None, outline_width=2):
    """Draw a translucent rounded rectangle using overlay compositing."""
    overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle([x1, y1, x2, y2], radius=radius, fill=fill_rgba)
    if outline_rgba:
        draw.rounded_rectangle([x1, y1, x2, y2], radius=radius, fill=None,
                               outline=outline_rgba, width=outline_width)
    return Image.alpha_composite(img, overlay)

def create_phone_frame(screenshot_path, border_color=PURPLE):
    """Create a phone mockup with rounded corners and border."""
    try:
        screenshot = Image.open(screenshot_path).convert('RGBA')
    except Exception as e:
        print(f"  ⚠ Could not load {screenshot_path}: {e}")
        screenshot = Image.new('RGBA', (1170, 2532), (200, 200, 200, 255))

    inner_w = PHONE_W - PHONE_BORDER * 2
    scale = inner_w / screenshot.width
    inner_h = int(screenshot.height * scale)
    screenshot = screenshot.resize((inner_w, inner_h), Image.LANCZOS)

    total_h = inner_h + PHONE_BORDER * 2
    phone = Image.new('RGBA', (PHONE_W, total_h), (0, 0, 0, 0))

    # Border background
    border_img = Image.new('RGBA', (PHONE_W, total_h), (0, 0, 0, 0))
    draw_b = ImageDraw.Draw(border_img)
    draw_b.rounded_rectangle(
        [0, 0, PHONE_W - 1, total_h - 1],
        radius=PHONE_RADIUS,
        fill=(border_color[0], border_color[1], border_color[2], 200)
    )
    phone = Image.alpha_composite(phone, border_img)

    # Inner white area
    inner_img = Image.new('RGBA', (PHONE_W, total_h), (0, 0, 0, 0))
    draw_i = ImageDraw.Draw(inner_img)
    draw_i.rounded_rectangle(
        [PHONE_BORDER, PHONE_BORDER, PHONE_W - PHONE_BORDER - 1, total_h - PHONE_BORDER - 1],
        radius=PHONE_RADIUS - 4,
        fill=(255, 255, 255, 255)
    )
    phone = Image.alpha_composite(phone, inner_img)

    # Mask for screenshot (rounded corners)
    mask = Image.new('L', (inner_w, inner_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, inner_w - 1, inner_h - 1], radius=PHONE_RADIUS - 8, fill=255)

    phone.paste(screenshot, (PHONE_BORDER, PHONE_BORDER), mask)
    return phone

def get_font(size, bold=True):
    """Load system fonts."""
    paths = [
        "/System/Library/Fonts/SFProDisplay-Bold.otf" if bold else "/System/Library/Fonts/SFProDisplay-Regular.otf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
    ]
    for fp in paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except:
                continue
    return ImageFont.load_default()

def draw_centered_text(draw, text, y, font, fill=(255, 255, 255, 255), width=W):
    """Draw centered text. Returns text height."""
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (width - tw) // 2
    draw.text((x, y), text, font=font, fill=fill)
    return bbox[3] - bbox[1]

# ───── SLIDE GENERATORS ─────

def generate_slide_1():
    """Gameplay: Tek Çizgiyle Bulmacayı Çöz!"""
    print("🎮 Generating Slide 1: Gameplay...")
    img = create_gradient(W, H, [DARK_BG, DARK_MID, PURPLE])

    img = add_circle_deco(img, W + 50, -50, 200, PURPLE, 30)
    img = add_circle_deco(img, -40, H - 600, 150, MINT, 30)
    img = add_circle_deco(img, W + 20, 500, 100, YELLOW, 18)
    img = add_glow(img, W // 2, H - 800, 500, MINT, 45)

    draw = ImageDraw.Draw(img)
    font_title = get_font(82)
    font_sub = get_font(38, bold=False)

    h1 = draw_centered_text(draw, "Tek Çizgiyle", 120, font_title)
    draw_centered_text(draw, "Bulmacayı Çöz!", 120 + h1 + 10, font_title, fill=(*MINT, 255))
    draw_centered_text(draw, "Parmağını kaldırmadan tamamla", 120 + h1 * 2 + 50, font_sub, fill=(255, 255, 255, 170))

    phone = create_phone_frame(os.path.join(SCREENSHOTS_DIR, "IMG_1969.PNG"), (42, 42, 74))
    phone_x = (W - phone.width) // 2
    phone_y = H - phone.height + 80  # Moved up
    img.paste(phone, (phone_x, phone_y), phone)

    img.save(os.path.join(OUTPUT_DIR, "cizgi_bulmaca_01_oynaniş.png"))
    print("  ✅ Saved")

def generate_slide_2():
    """Home: 600+ Seviye Seni Bekliyor!"""
    print("🏠 Generating Slide 2: Home Screen...")
    img = create_gradient(W, H, [(10, 43, 39), DARK_BG, DARK_MID])

    img = add_circle_deco(img, W + 50, -50, 200, MINT, 30)
    img = add_circle_deco(img, -40, H - 700, 150, (255, 170, 51), 25)
    img = add_glow(img, W // 2, H - 800, 500, MINT, 35)

    draw = ImageDraw.Draw(img)
    font_title = get_font(78)
    font_sub = get_font(38, bold=False)
    font_badge = get_font(32)

    h1 = draw_centered_text(draw, "600+ Seviye", 120, font_title, fill=(*MINT, 255))
    draw_centered_text(draw, "Seni Bekliyor!", 120 + h1 + 10, font_title)
    draw_centered_text(draw, "Kolay · Orta · Zor modları keşfet", 120 + h1 * 2 + 50, font_sub, fill=(255, 255, 255, 155))

    # Translucent badges
    badge_y = 460
    badge_data = [
        ("😊 Kolay", MINT),
        ("🔧 Orta", (255, 170, 51)),
        ("🔥 Zor", MAGENTA)
    ]
    badge_widths = []
    badge_gap = 28
    for text, _ in badge_data:
        bbox = draw.textbbox((0, 0), text, font=font_badge)
        badge_widths.append(bbox[2] - bbox[0] + 76)

    total_w = sum(badge_widths) + badge_gap * 2
    bx = (W - total_w) // 2
    for i, (text, color) in enumerate(badge_data):
        bw = badge_widths[i]
        bh = 72
        img = draw_translucent_rounded_rect(
            img, bx, badge_y, bx + bw, badge_y + bh, 34,
            fill_rgba=(color[0], color[1], color[2], 50),
            outline_rgba=(color[0], color[1], color[2], 120)
        )
        draw = ImageDraw.Draw(img)
        bbox = draw.textbbox((0, 0), text, font=font_badge)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((bx + (bw - tw) // 2, badge_y + (bh - th) // 2), text, font=font_badge, fill=(255, 255, 255, 255))
        bx += bw + badge_gap

    phone = create_phone_frame(os.path.join(SCREENSHOTS_DIR, "IMG_1968.PNG"), (26, 58, 53))
    phone_x = (W - phone.width) // 2
    phone_y = H - phone.height + 80
    img.paste(phone, (phone_x, phone_y), phone)

    img.save(os.path.join(OUTPUT_DIR, "cizgi_bulmaca_02_ana_ekran.png"))
    print("  ✅ Saved")

def generate_slide_3():
    """Level Map: Her Seviye Yeni Bir Meydan Okuma"""
    print("🗺️  Generating Slide 3: Level Map...")
    img = create_gradient(W, H, [(42, 31, 94), DARK_BG, DARK_MID])

    img = add_circle_deco(img, W + 50, -50, 200, MAGENTA, 30)
    img = add_circle_deco(img, -40, H - 600, 150, RED, 25)
    img = add_glow(img, W // 2, H - 800, 500, MAGENTA, 35)

    draw = ImageDraw.Draw(img)
    font_title = get_font(76)
    font_sub = get_font(38, bold=False)
    font_badge = get_font(30)

    h1 = draw_centered_text(draw, "Her Seviye", 120, font_title)
    draw_centered_text(draw, "Yeni Bir Meydan Okuma", 120 + h1 + 10, font_title, fill=(*MAGENTA, 255))
    draw_centered_text(draw, "200 seviye × 3 zorluk modu", 120 + h1 * 2 + 50, font_sub, fill=(255, 255, 255, 155))

    # Level badges
    badge_y = 450
    badges = [("🟢 200 Kolay", MINT), ("🟠 200 Orta", (255, 170, 51)), ("🟣 200 Zor", MAGENTA)]
    badge_widths = []
    for text, _ in badges:
        bbox = draw.textbbox((0, 0), text, font=font_badge)
        badge_widths.append(bbox[2] - bbox[0] + 64)
    total_w = sum(badge_widths) + 20 * 2
    bx = (W - total_w) // 2
    for i, (text, color) in enumerate(badges):
        bw = badge_widths[i]
        bh = 65
        img = draw_translucent_rounded_rect(
            img, bx, badge_y, bx + bw, badge_y + bh, 20,
            fill_rgba=(color[0], color[1], color[2], 40),
            outline_rgba=(255, 255, 255, 30)
        )
        draw = ImageDraw.Draw(img)
        bbox = draw.textbbox((0, 0), text, font=font_badge)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((bx + (bw - tw) // 2, badge_y + (bh - th) // 2), text, font=font_badge, fill=(255, 255, 255, 220))
        bx += bw + 20

    phone = create_phone_frame(os.path.join(SCREENSHOTS_DIR, "IMG_1970.PNG"), (42, 42, 74))
    phone_x = (W - phone.width) // 2
    phone_y = H - phone.height + 80
    img.paste(phone, (phone_x, phone_y), phone)

    img.save(os.path.join(OUTPUT_DIR, "cizgi_bulmaca_03_seviye_haritasi.png"))
    print("  ✅ Saved")

def generate_slide_4():
    """Profile: Yıldız Kazan Rekor Kır!"""
    print("⭐ Generating Slide 4: Profile...")
    img = create_gradient(W, H, [DARK_BG, DARK_MID, (42, 31, 94)])

    img = add_circle_deco(img, W + 50, -50, 200, YELLOW, 20)
    img = add_circle_deco(img, -40, H - 600, 150, PURPLE, 20)
    img = add_glow(img, W // 2, H - 800, 500, YELLOW, 30)

    draw = ImageDraw.Draw(img)
    font_title = get_font(78)
    font_sub = get_font(38, bold=False)
    font_stat_big = get_font(52)
    font_stat_label = get_font(26, bold=False)

    h1 = draw_centered_text(draw, "Yıldız Kazan", 120, font_title, fill=(*YELLOW, 255))
    draw_centered_text(draw, "Rekor Kır!", 120 + h1 + 10, font_title)
    draw_centered_text(draw, "İlerlemeni takip et", 120 + h1 * 2 + 50, font_sub, fill=(255, 255, 255, 155))

    # Stat cards with proper overlay
    card_y = 450
    stats = [("⭐ 58", "Yıldız"), ("🏆 5800", "Puan"), ("✅ 20", "Çözülen")]
    card_w = 240
    card_h = 160
    card_gap = 32
    total_cw = card_w * 3 + card_gap * 2
    sx = (W - total_cw) // 2
    for i, (val, label) in enumerate(stats):
        cx = sx + i * (card_w + card_gap)
        img = draw_translucent_rounded_rect(
            img, cx, card_y, cx + card_w, card_y + card_h, 28,
            fill_rgba=(255, 255, 255, 18),
            outline_rgba=(255, 255, 255, 35)
        )
        draw = ImageDraw.Draw(img)
        # Value
        bbox = draw.textbbox((0, 0), val, font=font_stat_big)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((cx + (card_w - tw) // 2, card_y + 28), val, font=font_stat_big, fill=(*YELLOW, 255))
        # Label
        bbox2 = draw.textbbox((0, 0), label, font=font_stat_label)
        lw = bbox2[2] - bbox2[0]
        draw.text((cx + (card_w - lw) // 2, card_y + card_h - 50), label, font=font_stat_label, fill=(255, 255, 255, 160))

    phone = create_phone_frame(os.path.join(SCREENSHOTS_DIR, "IMG_1977.PNG"), (42, 42, 74))
    phone_x = (W - phone.width) // 2
    phone_y = H - phone.height + 80
    img.paste(phone, (phone_x, phone_y), phone)

    img.save(os.path.join(OUTPUT_DIR, "cizgi_bulmaca_04_profil.png"))
    print("  ✅ Saved")

def generate_slide_5():
    """Onboarding: Kolay Başla Ustalaş!"""
    print("🚀 Generating Slide 5: Onboarding...")
    img = create_gradient(W, H, [DARK_BG, (26, 16, 64), PURPLE])

    img = add_circle_deco(img, -50, -50, 200, PURPLE, 30)
    img = add_circle_deco(img, W + 40, H - 600, 150, YELLOW, 22)
    img = add_glow(img, W // 2, H - 800, 500, PURPLE, 40)

    draw = ImageDraw.Draw(img)
    font_title = get_font(78)
    font_sub = get_font(38, bold=False)
    font_feature = get_font(26, bold=False)

    h1 = draw_centered_text(draw, "Kolay Başla", 120, font_title)
    draw_centered_text(draw, "Ustalaş!", 120 + h1 + 10, font_title, fill=(*YELLOW, 255))
    draw_centered_text(draw, "Sezgisel oynanış, anında başla", 120 + h1 * 2 + 50, font_sub, fill=(255, 255, 255, 155))

    # Feature cards
    feature_y = 450
    features = [("👆", "Tek Parmak", "Kontrolü"), ("🧩", "Sezgisel", "Tasarım"), ("🚀", "Hemen", "Oyna")]
    card_w = 210
    card_h = 150
    gap = 24
    total_w = card_w * 3 + gap * 2
    sx = (W - total_w) // 2
    for i, (icon, line1, line2) in enumerate(features):
        cx = sx + i * (card_w + gap)
        img = draw_translucent_rounded_rect(
            img, cx, feature_y, cx + card_w, feature_y + card_h, 24,
            fill_rgba=(255, 255, 255, 18),
            outline_rgba=(255, 255, 255, 30)
        )
        draw = ImageDraw.Draw(img)
        # Icon
        font_icon = get_font(36)
        bbox_i = draw.textbbox((0, 0), icon, font=font_icon)
        iw = bbox_i[2] - bbox_i[0]
        draw.text((cx + (card_w - iw) // 2, feature_y + 15), icon, font=font_icon, fill=(255, 255, 255, 255))
        # Text
        for j, line in enumerate([line1, line2]):
            bbox = draw.textbbox((0, 0), line, font=font_feature)
            tw = bbox[2] - bbox[0]
            draw.text((cx + (card_w - tw) // 2, feature_y + 70 + j * 32), line, font=font_feature, fill=(255, 255, 255, 190))

    phone = create_phone_frame(os.path.join(SCREENSHOTS_DIR, "IMG_1965.PNG"), (42, 42, 74))
    phone_x = (W - phone.width) // 2
    phone_y = H - phone.height + 80
    img.paste(phone, (phone_x, phone_y), phone)

    img.save(os.path.join(OUTPUT_DIR, "cizgi_bulmaca_05_baslangic.png"))
    print("  ✅ Saved")

# ───── MAIN ─────
if __name__ == "__main__":
    print("=" * 50)
    print("📱 Çizgi Bulmaca — App Store Screenshots v2")
    print(f"   Output: {OUTPUT_DIR}")
    print(f"   Size: {W}×{H}px")
    print("=" * 50)

    generate_slide_1()
    generate_slide_2()
    generate_slide_3()
    generate_slide_4()
    generate_slide_5()

    print("\n" + "=" * 50)
    print("🎉 Tüm 5 screenshot oluşturuldu!")
    print(f"📁 Dosyalar: {OUTPUT_DIR}")
    print("=" * 50)

    for f in sorted(os.listdir(OUTPUT_DIR)):
        if f.endswith('.png'):
            fpath = os.path.join(OUTPUT_DIR, f)
            with Image.open(fpath) as im:
                print(f"  📄 {f}: {im.size[0]}×{im.size[1]}px ({os.path.getsize(fpath) // 1024}KB)")
