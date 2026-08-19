# Isometric Pixel Map — MEMORY

## Son durum (2026-08-19)

**v0.7.1+15 — Grid size bug fix + mobil responsive**

### v0.7.1 değişiklikleri
- **Grid size bug fix (High):** "Maps → Grid size 48/64" mevcut haritayı bozuyordu (statik W/H → diziler eşleşmiyordu, OOB yazma). `MapData.w/h` artık örnek başına; `resized()` kırp/doldur; undo/redo/import/autosave boyut senkronlu. Yeni selftest `_test_grid_size_bug`.
- **Mobil responsive:** UI fiziksel pikselde layout (`stretch/mode=disabled` — mobilde butonlar ~13px'e küçülüyordu); TopBar FlowLeft + palet FlowContainer ile akışkan sarma; kompakt mod (<600px zoom/status, <480px title gizler); palet 44px dokunma hedefi; `_fit_zoom` haritayı viewport'a sığdırır.
- Live smoke: 375x667 layout ✓, boyama (32x16 tile değişimi) ✓, konsol temiz ✓
- Doğrulama: `verify.sh` VERIFY PASS (17 selftest)

### Live (ücretsiz)
https://zo.pub/triangle/isometric-pixel-map/index.html

### GitHub (public, MIT)
https://github.com/ZoriaSoft/isometric-pixel-map

### v0.7.0 değişiklikleri
- **"Pixel Atelier" tema** — Luxury/Refined chrome: sıcak obsidyen tuval (`#12100D`) + şampanya-altını accent (`#C9A961`); eski teal tamamen kaldırıldı
- **Fontlar:** Fraunces (serif display — brand/section, letterspaced small-caps) + JetBrains Mono (data); `assets/fonts/` bundled (OFL, lisans notu eklendi)
- **Brand mark:** elmas logo (ISO·MAP) + splash diamond spin-in animasyonu
- **Chrome restyle:** panel/buton/tooltip/lineedit — `theme_apply.gd` tek kaynak
- **Tema fix:** Godot 4.6 `CanvasLayer` tema kalıtımını kesiyor → tema `UI/TopBar`/`UI/BottomBar`/`UI/AboutPanel`'e doğrudan atandı; UI `CanvasLayer`'da tutuldu (stretch expand'de Control-tabanlı UI toolbar'ı kesiyordu)
- PWA theme-color + clear color `#12100D` senkron
- **QA:** xvfb screenshot pixel analizi — teal %0, obsidyen+altın aktif; verify PASS
- **Browser smoke (agent-browser):** tema uygulanıyor, toolbar tam genişlik, splash animasyonu, About+dimmer, palette altın seçim, boyama ✓

### Önceki (v0.6.1)
- **PWA** — manifest + service worker + ikonlar; canlıda doğrulandı
- **og:image** — 1200×630 share card + `summary_large_image`
- **Custom tile upload** — Tile+ PNG seçici, JSON'a `custom_tiles`, share link'te taşınır
- **Harita boyutu 32/48/64** — JSON `w/h`, legacy uyumlu
- **Tile varyasyonları** — ground tile'lar 3 deterministik varyant; PNG export eşleşir
- **Share link ZSTD** — 6944 → 142 karakter (~49×); legacy base64 linkler yüklenir

### Komutlar
```bash
bash scripts/tools/verify.sh
bash scripts/tools/export_web.sh
zopub sync isometric-pixel-map build/web
```

### Açık işler
- [ ] Show HN yayını (`docs/SHOW_HN.md` güncel) — live deploy sonrası
- [ ] Size trim (wasm ~36MB engine fixed — opsiyonel)
- [x] Web live smoke (yeni tema + PWA re-install) — agent-browser: tema/layout/splash/About/palette/boyama ✓

### Notlar
- DNA: `/home/workspace/Zoria-DNA/`
- Kardeş: `napkin-plan` (Canvas floor sketch) — cross-link var
- Selftest: `godot --headless --path . -s res://scripts/tools/rules_selftest.gd`
