# DESIGN — Isometric Pixel Map

## 🎯 Aesthetic Direction (commit edilmiş)

- **Akım:** Luxury / Refined
- **Niye bu akım:** Pixel-art yaratım aracı bir "hobi kutusu" değil — bir **zanaat atölyesi**. Sıcak obsidyen + şampanya-altın chrome, renkli pixel tile'ları bir koleksiyon parçası gibi öne çıkarır; ücretsiz araç "premium studio" hissi verir.
- **Bu akımdan ayrışan tek hamle:** "Pixel Atelier" — sıcak obsidyen kanvas + altın hairline chrome + **Fraunces** serif wordmark (ISO·MAP) + **JetBrains Mono** data readout'ları. Kare "elmas" mark, açılışta kare→elmas'a dönen yüksek etkili splash animasyonu.
- **Diğer Zoria projeleri ile gerilim:** Kardeş ürün napkin-plan (generic dark) — hairline altın + serif wordmark ile ayrışır. Zoria kataloğunda luxury akımını kullanan başka proje yok.

## 🧬 Bağlam

- **Sektör/alan:** Ücretsiz browser tabanlı izometrik pixel-map editörü (game jam / mockup / worldbuilding)
- **Hedef kitle:** Indie devler, jam'ciler, pixel-art tutkunları — "aç, boya, paylaş" kitlesi
- **Ayrışma cümlesi:** "Aseprite klonu değil — pixel dünyalar için bir atölye."

## 🅰 Typography

- Display (brand, splash, section başlıkları): **Fraunces 600** (`assets/fonts/fraunces-600.ttf`, OFL)
- Display light (tagline): **Fraunces 500**
- Data (status, koordinatlar, kısayollar, title input): **JetBrains Mono 400/500** (`assets/fonts/`, OFL)
- UI gövde: Godot default (clean sans) — Inter/Roboto/Arial kullanılmaz

## 🎨 Color & Theme

| Token | Hex | Kullanım |
|---|---|---|
| BG canvas | `#12100D` | clear color — sıcak obsidyen |
| Panel | `#1A1612` | top/bottom barlar, kartlar |
| Panel-2 | `#221C15` | butonlar, hover yüzeyleri |
| **Gold** | `#C9A961` | brand, seçim, primary CTA (PNG) |
| Gold-bright | `#E0C98F` | CTA hover |
| Champagne | `#E5D4A1` | hover text, section başlıkları |
| Ink | `#EDE3CE` | ana metin (sıcak fildişi) |
| Muted | `#8F8470` | ipuçları, status |
| Danger | `#D98A5F` | erase ghost (sıcak terracotta) |
| Hairline | `rgba(201,169,97,.20)` | ince altın çizgiler |

**Yasak:** mor gradyan, #0A0A0F zemin, #F5F1E8 metin, amber+emerald+teal üçlüsü, Inter/Roboto/Arial.

## 🌀 Motion

- **High-impact moment:** Splash'ta elmas mark'ın kare→elmas'a dönüşü (rotation 0→45°, 500ms easeOutCubic) + fade (350ms)
- **Tween profili:** `Tween.EASE_OUT + TRANS_CUBIC` (default linear değil)
- Toast: 1.5s bekle + 350ms fade

## 📐 Spatial Composition

- Üst bar: segmentli premium tool grupları (tools | brush | history | view | layers | file) — VSeparator hairline ayrımlar
- Alt bar: "TILES" letterspaced serif başlık + sağda mono hint + tile paleti
- About: ortalanmış kart (hairline altın border + soft shadow + diamond mark)
- Kanvas: izometrik harita ortalanmış, obsidyen matte çevre

## 🎭 Backgrounds & Visual Details

- Hairline altın border'lar (bar alt kenarları, kartlar, buton hover)
- Rotated ColorRect "pixel elmas" mark (font glyph'i değil — güvenli render)
- Grid: sıcak altın `rgba(201,169,97,.10)`
- Hover ghost: altın outline; erase ghost terracotta
- Splash: obsidyen + altın hairline + serif wordmark + mono hint

## 🧪 Doğrulama

- [x] `bash scripts/tools/verify.sh` → VERIFY PASS
- [x] Web smoke (agent-browser): tema uygulanıyor, layout tam pencere, splash animasyonu, About+dimmer, palette gold seçim, boyama
- [x] Fontlar OFL (Fraunces, JetBrains Mono) — PWA offline uyumlu bundle

## Not (implementation)

Godot 4.6'da `CanvasLayer` tema kalıtımını keser — tema `UI/TopBar`, `UI/BottomBar`, `UI/AboutPanel`'e doğrudan atanır (bkz. `editor_screen.gd:_ready`). Stretch `expand` mode'da tüm canvas (UI dahil) viewport'a göre ölçeklenir; butonlar 40px virtual → 32px screen.
