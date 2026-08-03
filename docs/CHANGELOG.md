# Changelog

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
