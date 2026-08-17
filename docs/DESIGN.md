# DESIGN — Isometric Pixel Map

## 🎯 Aesthetic Direction (v0.7.0 — commit edilecek)

- **Akım:** Luxury / Refined — "**Pixel Atelier**"
- **Niye:** Pixel map editörü bir "atölye" — sıcak malzeme (obsidyen, pirinç, fildişi) hissi; generic koyu-editör-teal (v0.6) ve mor AI estetiğinden bilinçli ayrışma.
- **Ayrışma hamlesi:** Şampanya-altını accent + Fraunces serif display + JetBrains Mono data. Teal/koyu-lacivert yok.

## 🧬 Karakter

Retro tool-first: sıcak obsidyen tuval, pirinç-altın donanım, serif marka. Marketing sitesi değil — ürün = tuval.

## Palet (v0.7.0)

| Token | Hex | Kullanım |
|-------|-----|----------|
| bg_canvas | `#12100D` | Clear color / tuval (warm obsidian) |
| panel | `#1A1612` | Top/bottom bar'lar |
| panel_2 | `#221C15` | Buton / hover yüzeyi |
| panel_3 | `#2B241B` | Pressed / active fill |
| gold | `#C9A961` | Primary accent — seçili çerçeve, brand |
| gold_bright | `#E0C98F` | Hover / parlak vurgu |
| champagne | `#E5D4A1` | Altın üzerinde parlak metin |
| ink | `#EDE3CE` | Ana metin (warm ivory) |
| muted | `#8F8470` | İpucu / durum |
| danger | `#D98A5F` | Erase ghost (sıcak terracotta) |
| hairline | `rgba(201,169,97,0.20)` | İnce altın çizgiler |

Tek kaynak: `scripts/ui/theme_apply.gd`.

**Yasak:** mor gradyan, generic purple-AI look, teal accent (eski tema), Inter/Roboto/Arial, aşırı glow.

## Tipografi (v0.7.0)

- **Fraunces** (SIL OFL) — brand/section başlıklar (letterspaced small-caps, `ISO·MAP` markası)
- **JetBrains Mono** (SIL OFL) — data/status/kısayol etiketleri
- Kaynak: `assets/fonts/` (bundled, offline; lisans: `assets/fonts/README.md`)
- Godot default font yalnızca fallback

## Brand

- **Mark:** 45° döndürülmüş kare (elmas) + iç elmas — `UI/TopBar` brand mark
- **Splash:** elmas 0.5s spin-in (cubic ease) + fade; toplam ~1.1s

## Grid

- Classic 2:1 iso diamond
- Tile 32×16 logical
- `texture_filter = nearest` (project)

## UX

- İlk ~1.1 sn: splash (brand mark animasyonu) → seed harita görünür
- Tooltip: Click / Scroll / Drag
- Tek sahne editör; ayrı landing route yok

## Chrome (toolbar)

```
[◆ ISO·MAP] | [P E F] | [1× 3× 5×] | [↶ ↷] | [− + #] | [Ground|Props] | Maps Load Save [PNG] [Share] | ? |··| status
 brand          tools     brush         hist     view       layers*          file + primary CTA + share
```

- Tools: compact, aktif fill gold çerçeve
- Brush: cycle 1×/3×/5× (B key)
- PNG: primary CTA (gold)
- Status: `title · layer · tile` (hover: `x,y · ground/prop`)
- Bottom: short hint + palette (inactive layer tiles dimmed)

## Doğrulama (v0.7.0)

- [x] Pixel analizi: teal %0, obsidyen zemin + altın çerçeve aktif
- [x] verify selftest PASS
- [ ] Cihazda smoke (web live)
