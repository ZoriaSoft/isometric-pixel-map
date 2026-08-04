# DESIGN — Isometric Pixel Map

## Karakter
Retro tool-first: koyu editör, net accent, pixel-grid hissi. Marketing sitesi değil — ürün = tuval.

## Palet
| Token | Hex | Kullanım |
|-------|-----|----------|
| bg | `#0B0F14` | Clear color / canvas |
| panel | `#121820` | Top/bottom bars |
| accent | `#3DDC97` | Title, selection border |
| muted | `#8A93A0` | Hints, status |
| danger | `#E85D5D` | Erase ghost |

**Yasak:** mor gradyan, generic purple-AI look, aşırı glow.

## Tipografi
Godot default UI font (MVP). Bundled pixel font opsiyonel post-MVP.

## Grid
- Classic 2:1 iso diamond
- Tile 32×16 logical
- `texture_filter = nearest` (project)

## UX
- İlk 2 sn: seed harita görünür
- Tooltip: Click / Scroll / Drag
- Tek sahne editör; ayrı landing route yok

## Chrome (toolbar) — v0.3.0
```
[Iso] | [P E F] | [1× 3× 5×] | [↶ ↷] | [− + #] | [Ground|Props] | Maps Load Save [PNG] [Share] | ? |··| status
 brand   tools     brush         hist     view       layers*          file + primary CTA + share
```
- Tools: compact + teal active fill
- Brush: cycle 1×/3×/5× (B key)
- Layers: quieter segment style (not same as tools)
- Grid: yellow-green toggle when on
- PNG: primary/accent CTA
- Share: copy map as URL hash
- Status: `title · layer · tile` (hover: `x,y · ground/prop`)
- Bottom: short hint + palette (inactive layer tiles dimmed)
