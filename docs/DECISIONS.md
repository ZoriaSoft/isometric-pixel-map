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

## ADR-0004 — Job-driven map templates (no filler)
**Tarih:** 2026-08-03  
**Durum:** Accepted  
**Karar:** Built-in maps = exactly 6, each tied to a user job: Blank, Settlement, Wilderness, Crossroads, Coast, Stronghold. Scenic-only maps (desert ruins, extra lakes) rejected.  
**Neden:** Tool users are jam/indie/mockup/worldbuilding — not tourists. Every template must answer “what am I starting to design?”  
**Not:** “All industries” is not the goal; **all primary jobs of this tool’s audience** is.
