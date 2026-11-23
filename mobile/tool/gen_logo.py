"""Génère les logos TMK Immobilier à partir du logo TMK de VTC Manager.

Le logo TMK reste dominant ; un petit badge « immeuble » premium (pastille verte
en dégradé, liseré blanc, ombre douce, glyphe blanc) est posé en bas à droite.

Usage : python3 tool/gen_logo.py <logo_tmk.png de VTC> assets/images
"""
import sys
from PIL import Image, ImageDraw, ImageFilter

SRC, OUT = sys.argv[1], sys.argv[2]
GREEN_LIGHT = (52, 211, 120)
GREEN_DARK = (18, 140, 72)
WHITE = (255, 255, 255, 255)


def tmk_transparent():
    """Logo TMK (fond blanc) -> RGBA à fond transparent, recadré."""
    im = Image.open(SRC).convert("RGB")
    out = Image.new("RGBA", im.size)
    px, po = im.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b = px[x, y]
            a = min(1.0, (255 - min(r, g, b)) / 170.0)
            if a < 0.06:
                continue
            c = tuple(max(0, min(255, round(255 - (255 - v) / a))) for v in (r, g, b))
            po[x, y] = (*c, round(a * 255))
    return out.crop(out.getbbox())


def badge(size):
    """Pastille premium : ombre, liseré blanc, dégradé vert, immeuble blanc."""
    S = 4
    D = size * S
    pad = round(D * 0.10)  # place pour l'ombre
    img = Image.new("RGBA", (D, D))

    # ombre douce décalée vers le bas
    shadow = Image.new("RGBA", (D, D))
    ImageDraw.Draw(shadow).ellipse(
        [pad, pad + D * 0.035, D - pad, D - pad + D * 0.035], fill=(0, 0, 0, 70))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(D * 0.035)))

    # liseré blanc
    d = ImageDraw.Draw(img)
    d.ellipse([pad, pad, D - pad, D - pad], fill=WHITE)

    # disque en dégradé vertical vert clair -> vert foncé
    ring = round(D * 0.045)
    inner = D - 2 * (pad + ring)
    grad = Image.new("RGBA", (inner, inner))
    gd = ImageDraw.Draw(grad)
    for y in range(inner):
        t = y / max(1, inner - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(GREEN_LIGHT, GREEN_DARK))
        gd.line([(0, y), (inner, y)], fill=(*c, 255))
    mask = Image.new("L", (inner, inner))
    ImageDraw.Draw(mask).ellipse([0, 0, inner - 1, inner - 1], fill=255)
    img.paste(grad, (pad + ring, pad + ring), mask)

    # reflet discret en haut
    gloss = Image.new("RGBA", (D, D))
    ImageDraw.Draw(gloss).ellipse(
        [pad + ring + inner * 0.12, pad + ring + inner * 0.04,
         pad + ring + inner * 0.88, pad + ring + inner * 0.50], fill=(255, 255, 255, 38))
    img.alpha_composite(gloss.filter(ImageFilter.GaussianBlur(D * 0.02)))

    # glyphe immeuble blanc, fenêtres creusées dans le vert
    d = ImageDraw.Draw(img)
    cx, cy = D / 2, D / 2
    u = inner / 78.0
    rr = round(1.6 * u)
    green_mid = (*[round((a + b) / 2) for a, b in zip(GREEN_LIGHT, GREEN_DARK)], 255)
    # tour principale
    tx0, ty0, tx1, ty1 = cx - 16 * u, cy - 26 * u, cx + 8 * u, cy + 24 * u
    d.rounded_rectangle([tx0, ty0, tx1, ty1], radius=rr, fill=WHITE)
    # annexe basse à droite
    ax0, ay0, ax1, ay1 = cx + 8 * u, cy - 6 * u, cx + 22 * u, cy + 24 * u
    d.rounded_rectangle([ax0, ay0, ax1, ay1], radius=rr, fill=WHITE)
    # fenêtres de la tour (2 colonnes x 4 rangées)
    ww, wh = 6 * u, 5.5 * u
    for i in range(2):
        for j in range(4):
            x = tx0 + 4 * u + i * 10 * u
            y = ty0 + 5 * u + j * 9 * u
            d.rounded_rectangle([x, y, x + ww, y + wh], radius=round(0.8 * u), fill=green_mid)
    # fenêtres de l'annexe (1 colonne x 2 rangées)
    for j in range(2):
        x = ax0 + 4 * u
        y = ay0 + 5 * u + j * 9 * u
        d.rounded_rectangle([x, y, x + ww, y + wh], radius=round(0.8 * u), fill=green_mid)
    # porte
    d.rounded_rectangle([cx - 7 * u, ty1 - 10 * u, cx - 1 * u, ty1], radius=round(0.8 * u),
                        fill=green_mid)
    return img.resize((size, size), Image.LANCZOS)


def fit_w(img, width):
    return img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)


tmk = tmk_transparent()


def compose(logo_width, badge_ratio=0.30):
    """TMK + badge en bas à droite, sur fond transparent, recadré."""
    logo = fit_w(tmk, logo_width)
    b = round(logo_width * badge_ratio)
    bdg = badge(b)
    W = logo.width + round(b * 0.45)
    H = logo.height + round(b * 0.40)
    canvas = Image.new("RGBA", (W, H))
    canvas.alpha_composite(logo, (0, 0))
    canvas.alpha_composite(bdg, (W - b, H - b))
    return canvas.crop(canvas.getbbox())


def on_square(size, content_ratio, bg):
    canvas = Image.new("RGBA", (size, size), bg)
    art = compose(1000)
    box = round(size * content_ratio)
    scale = box / max(art.width, art.height)
    art = art.resize((round(art.width * scale), round(art.height * scale)), Image.LANCZOS)
    canvas.alpha_composite(art, ((size - art.width) // 2, (size - art.height) // 2))
    return canvas


# Icône de lancement (fond blanc, iOS + Android legacy)
on_square(1024, 0.84, (255, 255, 255, 255)).convert("RGB").save(f"{OUT}/logo_tmk_icon.png")
# Premier plan adaptatif Android : flutter_launcher_icons ajoute un inset de 16 %,
# le contenu (84 %) finit donc à ≈ 57 % de l'icône, dans la zone sûre de 66 %.
on_square(1024, 0.84, (0, 0, 0, 0)).save(f"{OUT}/logo_tmk_icon_foreground.png")

# Logo pour l'app (écrans de connexion / chargement), fond blanc
art = compose(1000)
pad = 40
wide = Image.new("RGBA", (art.width + 2 * pad, art.height + 2 * pad), (255, 255, 255, 255))
wide.alpha_composite(art, (pad, pad))
wide.convert("RGB").save(f"{OUT}/logo_tmk.png")
print("ok", wide.size)
