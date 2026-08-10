# Isometric Pixel Map — MEMORY

## Son durum (2026-08-10)

**v0.6.0+12 — custom tile upload**

### Live (ücretsiz)
https://zo.pub/triangle/isometric-pixel-map

### GitHub (public, MIT)
https://github.com/ZoriaSoft/isometric-pixel-map

### v0.6.0 değişiklikleri
- **Custom tile upload** — "Tile+" butonu PNG seçici açar (web: file input, desktop: file dialog); görsel paintable tile olarak kaydedilir, JSON'a (`custom_tiles`) yazılır, share link'te taşınır (selftest doğrular)
- Custom tile'lar 100+ id alır; yeni harita yüklenince temizlenir (`Palette.clear_custom` / `TileAtlas.clear_custom`)
- Tarayıcı smoke: yeni build hata vermiyor (taze session)

### v0.5.0 değişiklikleri
- **Harita boyutu 32/48/64** — New-map menüsünde "Grid size" alt menüsü; boyut JSON'a `w/h` olarak yazılır, yüklenen harita kendi boyutunu korur (eski 32×32 dosyalar etkilenmez)
- **Tile varyasyonları** — ground tile'lar (grass/dirt/sand/path/stone/wood/snow/lava) 3 deterministik per-cell varyant render eder; büyük haritalar artık "döşeme" gibi görünmez. PNG export ekranla aynı varyantı kullanır
- **Undo diff gerekmedi:** 64×64'te bile 48 snapshot × 32KB = ~1.5MB — tam clone yeterli
- Performans: 64×64 PNG export 238ms (32×32: 67ms) — kabul edilebilir

### v0.4.0 değişiklikleri
- **Share link tam dolu haritada patlıyordu:** ham base64 hash ~6.9KB olup 6000-char limitini aşıyordu → ZSTD sıkıştırma (`z1` önek): tam dolu harita **6944 → 142 karakter** (~49× küçük). Legacy plain-base64 linkler (v0.3.0) hâlâ yüklenir (selftest doğrular)
- Tarayıcı smoke test (agent-browser): WebGL render ✓, klavye input ✓, PNG export ✓ (title-based filename), JSON save ✓

### v0.3.1 düzeltmeleri
- **Flood fill kesilme hatası:** pop-count guard büyük bölgeleri %25'te durduruyordu → seen-on-push + filled-count guard ile tam 32×32 fill
- **Geçersiz JSON sessizce haritayı siliyordu:** `from_json` artık null döndürüyor; bozuk autosave / kötü dosya / geçersiz share hash reddediliyor
- **Web sağ-tık menü engeli:** RMB pan yaparken tarayıcı context menu'su bastırıldı
- **Brush footprint ghost:** hover outline artık fırça boyutunu (3×/5×) gösteriyor
- **Selftest:** `_test_fill_full_map` (1024 hücre, gerçek Game kod yolu) + `_test_bad_json` eklendi

### Komutlar
```bash
bash scripts/tools/verify.sh
bash scripts/tools/export_web.sh
zopub sync isometric-pixel-map build/web
```
