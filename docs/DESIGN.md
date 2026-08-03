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
