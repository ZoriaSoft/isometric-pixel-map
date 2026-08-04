# ROADMAP — Isometric Pixel Map

## MVP (2 hafta)

### Faz 1 — Skeleton ✅
- [x] Bootstrap + landscape + `gl_compatibility`
- [x] Iso math + grid çizimi + pan/zoom
- [x] Web export preset + verify selftest
- [x] PNG export (software)

### Faz 2 — Editor core ✅
- [x] Palette + pen/erase/fill/undo
- [x] 2 layer (ground / props)
- [x] Seed demo map
- [x] Runtime pixel TileAtlas
- [x] Touch paint + pan

### Faz 3 — Ship ✅
- [x] JSON save/load (web Blob + file picker)
- [x] PNG export (atlas)
- [x] Public deploy: https://zo.pub/triangle/isometric-pixel-map
- [x] Loading splash + toasts + redo/zoom/pan polish
- [x] OG/meta tags
- [x] Show HN draft (`docs/SHOW_HN.md`)
- [ ] Size trim (wasm ~36MB engine fixed — optional later)

## Post-MVP
- ~~Next.js thin marketing shell (SEO/OG)~~ (optional)
- ~~Custom tile upload~~ (optional)
- Larger maps / brush size — ✅ brush size done (v0.3.0)
- ~~Share link (hash of map data)~~ — ✅ done (v0.3.0)
- Diff-based undo (for larger maps — current full-clone OK for 32×32)
- Custom tile upload
- Tile variations (random per-cell)
