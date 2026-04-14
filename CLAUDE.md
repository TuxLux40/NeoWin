# NeoWin — Project Context

## What This Is

NeoWin is a self-contained KDE Plasma 6 theme repository that replicates a Windows 11 aesthetic on Linux. It bundles every asset needed to fully theme a KDE desktop — icons, window decorations, cursors, plasma style, color schemes, sound themes, and panel layout — into a single repo with a bash installer. The goal is: clone, run one command, get a polished Win11-style desktop with automatic light/dark switching.

## Owner's Environment

- **OS**: Arch Linux (CachyOS)
- **Desktop**: KDE Plasma 6, Wayland
- **Shell**: fish
- **Monitors**: 3 screens
- **Repo location**: `~/git/NeoWin/`

## Repo Structure

```
NeoWin/
├── install.sh                  # Main installer (install, uninstall, sounds, restore-panel)
├── README.md
├── CLAUDE.md                   # This file
├── .gitignore
├── icons/win11-kde/            # Icon theme (~34k files, based on Windows-Eleven)
│   └── index.theme             # Name=NeoWin, FollowsColorScheme=true, Inherits=breeze,hicolor
├── aurorae/                    # Willow Blur window decorations (4 variants)
│   ├── WillowDarkBlur/
│   ├── WillowDarkBlurAlt/
│   ├── WillowLightBlur/
│   └── WillowLightBlurAlt/
├── cursors/                    # WinSur cursor themes
│   ├── WinSur-dark-cursors/
│   └── WinSur-white-cursors/
├── plasma-theme/Utterly-Round/ # Plasma desktop theme (blur + transparency)
├── color-schemes/              # WillowBlur color schemes
│   ├── Win11KDEDark.colors     # Name=Win11 KDE Dark (WillowDarkBlur colors)
│   └── Win11KDELight.colors    # Name=Win11 KDE Light (WillowLightBlur colors)
├── look-and-feel/              # KDE look-and-feel packages for auto switching
│   ├── neowin-dark/            # Id=neowin-dark, wires up dark cursor/colors/decoration
│   └── neowin-light/           # Id=neowin-light, wires up light cursor/colors/decoration
├── sounds/                     # 4 Windows sound packs, all mapped to freedesktop names
│   ├── win11-kde/              # Win11 sounds (44 events), installed as default
│   ├── win10/                  # Win10 sounds (41 events)
│   ├── win7/                   # Win7 sounds (13 sub-schemes × 20 events each)
│   └── winxp/                  # WinXP sounds (26 events)
├── panel-layout/               # Saved panel config (top bar + bottom taskbar)
└── config/                     # Reference config snapshots (kwinrc, plasmarc, kdeglobals)
```

## How It Works

### Install Flow
`./install.sh install` does two things:
1. **install_assets()** — copies all theme files to XDG directories under `~/.local/share/`
2. **apply_config()** — uses `kwriteconfig6` to set all KDE config keys and applies the dark look-and-feel as default

### Auto Dark/Light Switching
Uses KDE's native `AutomaticLookAndFeel` mechanism:
- `kdeglobals [KDE] AutomaticLookAndFeel=true`
- `kdeglobals [KDE] DefaultDarkLookAndFeel=neowin-dark`
- `kdeglobals [KDE] DefaultLightLookAndFeel=neowin-light`

KDE switches the entire look-and-feel package (cursors, colors, window decoration) based on the Night Color schedule in System Settings.

### Sound Theme System
Each sound pack has an `index.theme` and a `stereo/` directory with `.wav` files named after freedesktop sound event names (e.g., `dialog-error.wav`, `desktop-login.wav`). The `sounds` command swaps which pack is installed under `~/.local/share/sounds/neowin/`.

### Icon Theme
Based on [Windows-Eleven](https://github.com/ArcticLinguistics/Windows-Eleven) by zayronxio. Extended with symlinks for:
- All `org.kde.*` app IDs (Dolphin, Konsole, Kate, Okular, Discover, etc.)
- Flatpak app IDs (Firefox, Thunderbird, LibreOffice, VLC, etc.)
- KDE sidebar/category icons for full coverage in Dolphin, Discover, System Settings

`FollowsColorScheme=true` makes symbolic/monochrome icons adapt to light/dark automatically. Falls back to `breeze → hicolor` for any missing icons.

## Design Decisions

- **Breeze as application style**: Win11 doesn't have a faithful Qt widget style, and Breeze is the most stable/complete. The Windows look comes from icons + decorations + colors + plasma theme.
- **Utterly-Round for plasma theme**: Chosen for its blur/transparency support, which matches Win11's acrylic/mica aesthetic.
- **Willow Blur for window decorations**: Closest to Win11's rounded window titlebars with blur effect.
- **WillowBlur color schemes**: Used instead of Breeze colors because they complement the Willow window decorations.
- **Single icon theme for both modes**: The icon theme uses `FollowsColorScheme=true` so one theme works for both light and dark without duplication.
- **No splash screen**: Intentional — cleaner boot experience.
- **Panel layout not auto-applied**: Avoids overwriting user's existing panel setup. Must be explicitly restored with `restore-panel`.

## Known Quirks / Gotchas

- The icon directory is still named `icons/win11-kde/` on disk (historical artifact), but `index.theme` sets `Name=NeoWin` so KDE sees it as "NeoWin".
- Color scheme files are named `Win11KDEDark.colors` / `Win11KDELight.colors` — the internal `Name=` field is what KDE displays.
- Win7 sound pack has 13 sub-schemes (Afternoon, Calligraphy, Characters, Cityscape, Delta, Festival, Garden, Heritage, Landscape, Quirky, Raga, Savanna, Sonata). Each has original `.wav` files plus a `stereo/` dir with freedesktop-mapped names.
- The repo is ~239MB due to bundled assets (icons are the biggest chunk at ~143MB).
- `config/` directory contains reference snapshots, not actively used by the installer.

## Goals & Intentions

1. **Portable theme backup**: Clone this repo on any KDE Plasma 6 system, run `install.sh install`, and get the exact same desktop appearance.
2. **Complete coverage**: Every visible UI element should be themed — no fallback to generic KDE defaults that break the aesthetic.
3. **Clean light/dark switching**: Both variants should look polished, not just "dark mode with wrong icons."
4. **Sound customization**: Multiple Windows-era sound packs bundled so users can pick their favorite nostalgia.
5. **Minimal dependencies**: Only requires standard KDE tools (`kwriteconfig6`, `lookandfeeltool`, `kbuildsycoca6`). No Python, no extra packages.

## What Could Be Improved

- Rename `icons/win11-kde/` directory to `icons/neowin/` for consistency (requires re-commit of ~34k files).
- Rename color scheme files from `Win11KDE*` to `NeoWin*`.
- Add a `--dry-run` flag to the installer.
- Add wallpapers (currently not bundled — user uses Bing POTD via KDE widget).
- GTK theme integration (user has a separate `~/.themes/Windows10` GTK theme that needed fixes).
- Upstream the icon symlink additions back to the Windows-Eleven project.
- Add screenshots to README.
