# Isometric Pixel Map — MEMORY

## Son durum (2026-08-04)

**v0.3.1+9 — bug fix + iyileştirme turu**

### Live (ücretsiz)
https://zo.pub/triangle/isometric-pixel-map

### GitHub (public, MIT)
https://github.com/ZoriaSoft/isometric-pixel-map

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
