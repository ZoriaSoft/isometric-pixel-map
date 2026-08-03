# DECISIONS (ADR)

## ADR-0001 — Godot-only Web, Next.js ertelendi
**Tarih:** 2026-08-03  
**Durum:** Accepted  
**Karar:** MVP tamamen Godot 4.6 Web (`gl_compatibility`, `thread_support=false`). Next static yok.  
**Neden:** 2 haftada WASM + Next embed (COOP/COEP, iframe, çift build) maliyetli. Mevcut okey/kelimelik web pipeline kanıtlı. "Gamified landing" = seed harita + anında boyama.  
**Sonuç:** Post-MVP'de isteğe bağlı Next shell.

## ADR-0002 — 32×32, 2 layer, PNG+JSON
**Tarih:** 2026-08-03  
**Durum:** Accepted  
**Karar:** Sabit 32×32 grid; `ground` + `props`; export PNG + JSON v1.  
**Neden:** Viral 60 sn demo için hızlı; fill/undo maliyeti sınırlı.

## ADR-0003 — Procedural tiles önce, atlas sonra
**Tarih:** 2026-08-03  
**Durum:** Accepted  
**Karar:** İlk sürüm renkli diamond + basit prop vektörleri; gerçek pixel atlas Faz 2/3 polish.  
**Neden:** Oyun döngüsünü (boya/export) asset üretiminden ayırır.
