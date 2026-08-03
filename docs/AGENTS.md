# Isometric Pixel Map — Agent Navigation

## Proje
- **Variant:** Godot 4.6 Web (landscape, `gl_compatibility`)
- **Truth:** `MEMORY.md` (root)
- **MVP:** Tarayıcıda iso tile boyama + PNG/JSON export

## Dosya haritası

| Konu | Yol |
|------|-----|
| Map model | `scripts/model/map_data.gd` |
| Palette ids | `scripts/model/palette.gd` |
| Global state | `scripts/autoload/Game.gd` |
| Grid draw/input | `scripts/view/iso_grid_view.gd` |
| Editor UI | `scripts/ui/editor_screen.gd`, `palette_bar.gd` |
| PNG | `scripts/export/png_exporter.gd` |
| Main scene | `scenes/Main.tscn` → `Editor.tscn` |
| Verify | `scripts/tools/verify.sh` |
| Web export | `scripts/tools/export_web.sh` |

## Kurallar
- Feature creep yok: OUT = OSM, multiplayer, custom tile upload, Next monorepo
- Version: `project.godot` `config/version` == `Game.APP_VERSION`
- i18n: `L.t()` — EN primary MVP
- Mor gradyan yasak
- Web: `thread_support=false`

## Komutlar
```bash
bash scripts/tools/verify.sh
bash scripts/tools/export_web.sh
python3 scripts/tools/serve_web.py 8770
```
