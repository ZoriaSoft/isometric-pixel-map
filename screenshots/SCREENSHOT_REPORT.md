# Screenshot QA — isometric-pixel-map v0.7.0+14

Tarih: 2026-08-17 · Runner: Xvfb 1280×720 (viewport 1280×720)

## Ekran

| Dosya | İçerik |
|---|---|
| `screenshots/01_editor_v070.png` | Editor: top bar (ISO·MAP brand) + tuval (seed harita) + bottom bar (palet/hint) |

## Pixel analizi (PIL)

- `#12100D` (sıcak obsidyen tuval) %54 — yeni clear color ✓
- `#1A1612` (panel bar) %3.2 — yeni chrome ✓
- Yeşil tile'lar (çim/ağaç) %~25 — seed harita ✓
- **Eski teal accent: %0.00** — v0.6 tema tamamen gitti ✓
- Gold (#C9A961) seçili öğelerde küçük alan — beklenen (hover/active state)

## Verdict

- ✅ verify selftest PASS (templates, new tiles, brush, share link, sizes, custom tiles)
- ✅ Script/parse hatası yok (xvfb run temiz; ALSA uyarıları ses kartı yokluğu — zararsız)
- ✅ Palet/layout pixel analizi DESIGN.md v0.7.0 ile uyumlu
- ⚠️ Görsel tam doğrulama yapılamadı (agent modeli vision desteklemiyor) — kullanıcı web live'da smoke edecek
