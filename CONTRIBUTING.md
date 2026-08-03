# Contributing

Thanks for helping polish **Isometric Pixel Map**.

## Quick rules

1. Run `bash scripts/tools/verify.sh` before opening a PR.
2. Keep the MVP spirit: browser tool, no accounts/cloud unless discussed.
3. Prefer small PRs (one feature or one fix).
4. Match existing GDScript style; no purple gradient UI.

## Dev setup

- Godot **4.6.x**
- Open `project.godot` or `godot --path .`

## Useful scripts

| Script | Purpose |
|--------|---------|
| `scripts/tools/verify.sh` | Version sync + headless selftest |
| `scripts/tools/export_web.sh` | Web release build → `build/web` |
| `scripts/tools/serve_web.py` | Local static server for export |

## Ideas that fit well

- New palette tiles / atlas art
- UX polish (mobile, shortcuts)
- JSON format docs / sample maps
- Accessibility (button sizes, contrast)

## Ideas that need discussion first

- Multiplayer / accounts
- Huge map sizes
- AI generation
- Next.js marketing monorepo
