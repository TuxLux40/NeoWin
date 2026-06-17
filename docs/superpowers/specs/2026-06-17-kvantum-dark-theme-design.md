# NeoWin Kvantum Dark Theme — Design Spec

**Date:** 2026-06-17  
**Branch:** feature/kvantum  
**Scope:** Dark mode only; light mode deferred

## Goal

Replace Breeze as the Qt widget style with a Kvantum theme that matches Windows 11 Fluent Design — dark palette, Acrylic blur on windows and menus, Win11 blue accent.

## Files

```
kvantum/
└── NeoWinKvantumDark/
    ├── NeoWinKvantumDark.kvconfig   Win11 colors + blur settings
    └── NeoWinKvantumDark.svg        Widget shapes (based on KvAdaptaDark)
```

Installed to `~/.config/Kvantum/NeoWinKvantumDark/` at install time.

## Color Palette (Win11 dark, from Fluent Design spec)

| Role | Hex | Source |
|---|---|---|
| Window background | `#202020` | App background (dark) |
| Base (lists/inputs) | `#2C2C2C` | Surface layer |
| Alt base | `#272727` | Alternate row |
| Button/control fill | `#3D3D3D` | Control fill |
| Accent | `#0078D4` | Win11 system accent |
| Text primary | `#E3E3E3` | White @ 89% |
| Text secondary | `#C0C0C0` | White @ 75% |
| Disabled text | `#5C5C5C` | White @ 36% |
| Link | `#60CDFF` | Hyperlink (dark) |

## Blur / Transparency

- `translucent_windows=true` + `blurring=true` — 85% opaque windows, blur behind
- `popup_blurring=true` + `reduce_menu_opacity=20` — menus 80% opaque + blur
- `blur_translucent=true` — also applies to apps like Konsole with built-in transparency
- KWin `blurEnabled=true` (already set by NeoWin installer) provides the actual blur render

## Integration

- `install_assets()` copies `kvantum/NeoWinKvantumDark/` → `~/.config/Kvantum/`
- `apply_config()` installs `kvantum` package if missing (pacman/apt), then `kvantummanager --set NeoWinKvantumDark`, then writes `widgetStyle=kvantum`
- `look-and-feel/neowin-dark/contents/defaults` → `widgetStyle=kvantum` (persists through auto-switch to dark)
- `uninstall()` removes `~/.config/Kvantum/NeoWinKvantumDark/`
- neowin-light LAF unchanged for now (auto-switch to light reverts to Breeze temporarily)

## SVG Strategy

Base: copy of KvAdaptaDark.svg. Win11 corner radii (4px small, 8px large) require SVG edits — deferred until the color/blur result is validated visually.
