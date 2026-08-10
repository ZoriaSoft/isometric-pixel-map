# Changelog

## [0.6.0+12] — 2026-08-10

### Added
- **Custom tile upload** — "Tile+" button opens a PNG picker (web: file input, desktop: file dialog); the image is registered as a paintable tile, persisted in JSON (`custom_tiles`) and carried through share links

## [0.5.0+11] — 2026-08-10

### Added
- **Map sizes 32/48/64** — New-map menu now has a "Grid size" submenu; size is stored in JSON (`w`/`h`) so loaded maps keep their own size (legacy 32×32 files unaffected)
- **Tile variants** — ground tiles (grass/dirt/sand/path/stone/wood/snow/lava) render with 3 deterministic per-cell variants, so large maps no longer look tiled. PNG export matches the on-screen variant selection

## [0.4.0+10] — 2026-08-10

### Fixed
- **Share link broke on full maps** — raw base64 hash hit the 6000-char limit at ~6.9KB for a full 32×32 map, so Share failed with "Map too large". Hash is now ZSTD-compressed (`z1` prefix): full map dropped to **142 chars** (~49× smaller). Legacy plain-base64 links from v0.3.0 still load.

## [0.3.1+9] — 2026-08-04

### Fixed
- **Flood fill truncated on large regions** — pop-count guard capped fills at ~25% of the map; rewritten with seen-on-push + filled-count guard (now fills full 32×32 correctly)
- **Invalid JSON silently wiped the map** — `from_json` returned an empty map instead of null; corrupt autosave / bad file / invalid share hash now rejected properly
- **Web right-click panning opened browser context menu** — canvas-level `contextmenu` suppression added via WebBridge

### Improved
- **Brush footprint ghost** — hover outline now shows the full brush area (3×/5×), not just a single cell; FILL tool still shows 1-cell target
- **Selftest coverage** — added `_test_fill_full_map` (real Game code path, 1024 cells) and `_test_bad_json` (garbage/non-map input → null)
- Deduped redundant `selection_changed` emit in `Game.set_layer`

## [0.3.0+8] — 2026-08-04

### Added
- **Brush size** (1×/3×/5×) — cycle with `B` key or toolbar button
- **7 new tiles:** Snow, Lava, Bridge (ground); Bush, Tent, Barrel, Lamp (props)
- **Share link** — copy map as URL hash (`#m=<base64>`), paste link to reload
- **New shortcuts:** `B` brush, `Ctrl+S` save, `Ctrl+E` PNG, `Ctrl+N` new map
- `Escape` closes about panel or resets tool to pen

### Changed
- **PNG export 10-50× faster** — `Image.blend_rect` replaces per-pixel GDScript alpha blending
- **Tile atlas polish** — richer tree foliage, steeper house roof, organic rock shape, water dual-wave, stone cracks, wood grain detail
- **Grid lines softer** — white 8% alpha (was black 12%)
- **Hover outline** — accent teal outline on hovered cell
- **Splash shorter** — 0.6s total (was 1.05s)
- Desert alias now maps to Coast (was Blank)

### Removed
- `Audio.gd` autoload — dead infrastructure, never called
- `sfx_volume`/`music_volume` from settings

### Fixed
- Flood fill magic number `1000` → `MapData.W` (collision-safe for larger grids)
- `export_preview.gd` unnecessary `res://` write attempt on export builds
- `serve_web.py` unnecessary COOP/COEP headers (thread_support=false)
- `palette_bar.gd` misleading comment about layer polling

## [0.2.3+7] — 2026-08-03

### Changed
- **Header redesign** (honest design review P0/P1): grouped tools/history/view/layers/file
- Compact tool buttons (P/E/F) with tooltips; PNG as primary CTA
- Distinct tool vs layer vs grid toggle styles
- Shorter status + hint; About cheatsheet + dimmer
- Palette dims inactive-layer tiles

## [0.2.2+6] — 2026-08-03

### Changed
- Templates trimmed to **6 job-driven starters** only (no scenic filler)
- Catalog shows **use-case** text (who needs this map)
- Retired desert + lake as separate fillers; coast covers water; crossroads added for overworld

## [0.2.1+5] — 2026-08-03

### Added
- Map templates via Maps ▾ menu + `MapTemplates` catalog + selftest

## [0.2.0+4] — 2026-08-03

### Added
- Dark teal **UI theme** + active tool/layer highlight
- Grid toggle (button + `G`)
- MIT `LICENSE`, public README, `CONTRIBUTING.md`
- Open-source / free messaging in About

### Changed
- Version bump for public GitHub + free web release polish

## [0.1.2+3] — 2026-08-03

### Added
- Stable **WebBridge** (Blob download + file picker callback)
- Redo, zoom +/− buttons; Space+drag pan; pinch zoom
- Toast feedback (save/load/export)
- Richer demo village seed + tree art
- OG/Twitter meta in web export
- `docs/SHOW_HN.md` draft post

## [0.1.1+2] — 2026-08-03

### Added
- Runtime pixel-art **TileAtlas** (ground + props sprites)
- Loading splash fade-in
- Touch paint / multi-touch pan
- Palette buttons with tile previews
- PNG export matches atlas look

### Fixed
- `TileAtlas` class registration (`seed` reserved name)

## [0.1.0+1] — 2026-08-03

### Added
- Godot 4.6 Web-first project bootstrap
- 32×32 isometric map model (ground + props)
- Editor: pen, erase, fill, undo, pan/zoom, palette
- Demo Village seed map
- JSON save/load + PNG software export
- Web export preset (`thread_support=false`)
- Headless selftest (`scripts/tools/verify.sh`)
