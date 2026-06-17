# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

NeoWin is a self-contained KDE Plasma 6 theme repository that replicates a Windows 11 aesthetic on Linux. It bundles every asset needed to fully theme a KDE desktop — icons, window decorations, cursors, plasma style, color schemes, sound themes, and panel layout — into a single repo with a bash installer. The goal is: clone, run one command, get a polished Win11-style desktop with automatic light/dark switching.

## Owner's Environment

- **OS**: Arch Linux (CachyOS)
- **Desktop**: KDE Plasma 6, Wayland
- **Shell**: fish
- **Monitors**: 3 screens
- **Repo location**: `~/Projects/NeoWin/`

## Commands

All operations go through `./install.sh` (bash, `set -euo pipefail`). No build system, no tests, no linter.

```bash
./install.sh install              # Copy assets to ~/.local/share + apply KDE config
./install.sh uninstall            # Remove all installed assets
./install.sh sounds               # List sound packs
./install.sh sounds win11         # Switch to Win11 sounds (default)
./install.sh sounds win10         # Switch to Win10 sounds
./install.sh sounds win7 Sonata   # Switch to Win7 sub-scheme (default sub-scheme: Sonata)
./install.sh sounds winxp         # Switch to WinXP sounds
./install.sh restore-panel        # Copy panel-layout/ over ~/.config/plasma-org.kde.plasma.desktop-appletsrc
./install.sh wallpaper            # Set Picture of the Day wallpaper (default provider: bing)
./install.sh wallpaper apod       # Use NASA APOD provider instead
./install.sh help
```

After `restore-panel`, Plasma shell must restart:
```bash
kquitapp6 plasmashell && kstart plasmashell
```

To force-refresh caches / reload KWin manually:
```bash
kbuildsycoca6 --noincremental
qdbus6 org.kde.KWin /KWin reconfigure
```

## Installer Internals

`install.sh` has these functions: `install_assets`, `apply_config`, `sounds`, `restore_panel`, `wallpaper`, `reload_plasma`, `uninstall`.

**`install_assets`** copies into XDG dirs:
- `icons/win11-kde/` → `~/.local/share/icons/NeoWin` (on-disk dir renamed during copy; source dir keeps legacy name)
- `aurorae/Willow{Dark,Light}Blur{,Alt}/` → `~/.local/share/aurorae/themes/`
- `cursors/WinSur-{dark,white}-cursors/` → `~/.local/share/icons/`
- `plasma-theme/Utterly-Round` → `~/.local/share/plasma/desktoptheme/`
- `color-schemes/NeoWin{Dark,Light}.colors` → `~/.local/share/color-schemes/`
- `look-and-feel/neowin-{dark,light}/` → `~/.local/share/plasma/look-and-feel/`
- `sounds/win11-kde/` → `~/.local/share/sounds/neowin` (sound theme dir is always `neowin`, content swapped by `sounds` command)
- Runs `kbuildsycoca6 --noincremental` at the end.

**`apply_config`** writes via `kwriteconfig6` (falls back to `kwriteconfig5`):
- `kdeglobals [KDE] AutomaticLookAndFeel=true`, `DefaultDarkLookAndFeel=neowin-dark`, `DefaultLightLookAndFeel=neowin-light`
- `kdeglobals [Icons] Theme=NeoWin`, `[KDE] widgetStyle=Breeze`, `[Sounds] Theme=neowin`
- `kwinrc [org.kde.kdecoration2] library=org.kde.kwin.aurorae.v2`, `theme=__aurorae__svg__WillowDarkBlur`, `BorderSize=NoSides`, `BorderSizeAuto=false`, `ButtonsOnLeft=M`
- `kwinrc [TabBox] LayoutName=coverswitch` (Alt+Tab cover switch)
- `kwinrc [Plugins] blurEnabled=true`, `[Effect-blur] BlurStrength=13`, `[NightColor] Active=true`
- `plasmarc [Theme] name=Utterly-Round`
- `ksplashrc [KSplash] Engine=none`, `Theme=None`
- Calls `configure_night_color()` to validate the Night Color schedule (see Auto Dark/Light Switching below); only changes `Mode` if the schedule is broken (mode=0 + no transitions).
- Detects current `daylight` state via `qdbus6 org.kde.KWin.NightLight` and applies `neowin-light` or `neowin-dark` accordingly (falls back to dark if no session).
- Reloads KWin via `qdbus6 org.kde.KWin /KWin reconfigure`, then reloads the `lookandfeelautoswitcher` kded module so it re-evaluates immediately.
- The dark window decoration is written directly into `kwinrc`; on light switch KDE overrides it from the `neowin-light` LAF package.

**`sounds <pack> [scheme]`** wipes `~/.local/share/sounds/neowin`, copies `index.theme` + `stereo/` from the chosen source, then `sed`s `Name=...` → `Name=NeoWin` so KDE's sound theme ID stays constant. Invalid pack/scheme prints the available list and exits non-zero.

**`restore_panel`** copies `panel-layout/plasma-org.kde.plasma.desktop-appletsrc` over `~/.config/plasma-org.kde.plasma.desktop-appletsrc`. Not called from `install`.

**`wallpaper [provider]`** pokes plasmashell via `qdbus6 org.kde.plasmashell /PlasmaShell evaluateScript` to switch every desktop's wallpaper plugin to `org.kde.potd` (Picture of the Day) with the given provider (default `bing`; e.g. `apod`, `unsplash`, `noaa`, etc.). Requires Plasma to be running. Not called from `install`.

**`reload_plasma`** runs `kbuildsycoca6 --noincremental`, pings KWin with `qdbus6 /KWin reconfigure`, then `kquitapp6 plasmashell` + `kstart plasmashell` to force-reload everything. Called at the end of `install` so theme/icon/color changes show up without the user having to log out.

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
│   ├── NeoWinDark.colors       # Name=NeoWin Dark (WillowDarkBlur palette)
│   └── NeoWinLight.colors      # Name=NeoWin Light (WillowLightBlur palette)
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

## Icon Architecture

### How KDE Resolves Icons by Area

The icon loader searches ALL declared directories by name. `Context=` in `index.theme` is a hint for size preference, not a hard filter. An icon found in any declared directory at any matching size will be used.

| UI area | Context dir | Sizes | Icon names |
|---|---|---|---|
| Dolphin sidebar (Places) | `places/` | 16–48px | `user-home`, `folder-documents`, `folder-download`, `folder-music`, `folder-pictures`, `folder-videos`, `user-trash`, `user-desktop`, `network-server` |
| Discover category sidebar | `categories/` | 32px + symbolic | `applications-games`, `-graphics`, `-multimedia`, `-internet`, `-network`, `-system`, `-utilities`, `-office`, `-development`, `-education`, `-other`, `-science`, `-addons` |
| System Settings sidebar | `apps/scalable/` (fallthrough) | 22px | `preferences-desktop-font`, `preferences-desktop-display`, `preferences-desktop-mouse`, `preferences-system-network`, `preferences-system-login`, `preferences-system-windows`, `preferences-security`, `preferences-system`, etc. |
| App launcher / taskbar | `apps/scalable/` | scalable | App `.desktop` `Icon=` value — modern KDE uses `org.kde.*` names; legacy uses short names |
| Systray | `status/` | 16–22px | **Upstream limitation** — see below |

### Critical: `apps/scalable` Serves System Settings Icons

`apps/scalable` declares `MinSize=16, MaxSize=512`. This means every `preferences-*.svg` in that directory (90+ files) is served when System Settings requests them at 22px. **No separate `preferences/` context directory is needed.** Adding one would be redundant.

### Inheritance Chain

NeoWin → breeze → hicolor

Anything not in NeoWin falls back to Breeze. This is intentional for icons without a clear Windows equivalent.

### Intentional Breeze Fallbacks

| Icon | Area | Why no Windows mapping |
|---|---|---|
| `plasma` | Discover "Plasma Add-ons" category | KDE-specific, no Win11 equivalent |
| All systray applet icons | Systray | Plasma 6 hardcodes `-symbolic` + monochrome tint regardless of icon theme |
| `applications-accessories-symbolic` | Discover "Accessories" category | Mapped to `applications-utilities-symbolic` (closest match) |

### What Was Added vs What Already Existed

All Dolphin sidebar icons were already covered. Discover categories were mostly covered — only `applications-network` was missing (symlinked to `applications-internet`). System Settings sidebar icons were already covered via `apps/scalable/` MinSize=16 passthrough. Short-name aliases `dolphin` and `accessories-archive-manager` were missing and added.

### What NOT to Do

- Do not add a `preferences/` context directory — it's redundant, `apps/scalable` already covers it
- Do not add icons for systray applets in `status/` to fix colors — Plasma 6 forces monochrome tinting regardless
- Do not remove the `FollowsColorScheme=true` from `index.theme` — it enables symbolic icons to adapt to light/dark automatically

### Sources & Databases for Icon Work

When extending or auditing the icon theme, use these authoritative references instead of guessing or vibe-coding:

- **freedesktop.org standards** (the foundation everything builds on):
  - Icon Naming Specification: https://specifications.freedesktop.org/icon-naming-spec/latest/
  - Icon Theme Specification: https://specifications.freedesktop.org/icon-theme-spec/latest/
- **KDE/Plasma official guidance**:
  - https://develop.kde.org/docs/features/additional-features/icons/
  - Human Interface Guidelines (icons section): https://develop.kde.org/hig/icons/
  - Critical Plasma 6 changes (symbolic `-symbolic` suffix, everything now comes from the system icon theme): https://pointieststick.com/2023/08/12/how-all-this-icon-stuff-is-going-to-work-in-plasma-6/
- **Reference implementation (what names Plasma + stock apps actually request today)**:
  - Install `plasma-sdk` and use the **Icon Explorer** tool to browse Breeze by category/name.
  - Source: https://invent.kde.org/plasma/breeze-icons (or the GitHub mirror).
- **Upstream for NeoWin's icon base**:
  - https://github.com/zayronxio/windows-eleven-skin (the `icons/` subdirectory is the origin of `icons/win11-kde/`).
  - Store page: https://store.kde.org/p/1977340
- **Practical discovery on your machine**:
  - `kiconfinder6 <name>` — tells you exactly which file (and theme) currently wins.
  - Runtime logging: `QT_LOGGING_RULES="kf.icon.*=true" <app>`
  - Static analysis: `strings` on KIO plugins, Dolphin, etc. (e.g. `recentlyused.so`).
- **Other Win11-style icon sources** (for filling real gaps):
  - Other community ports on store.kde.org / opendesktop (search "windows 11" icon theme).
  - Related work by zayronXIO (MacOS-style icon sets for visual reference).
  - **Never** mass-copy Breeze SVGs. Symlink to the closest good Win11-style asset you already have, or create a minimal adaptation that matches the existing style (gradients, ColorScheme classes, etc.).

See the companion file `icons/MAPPINGS.md` for a practical quick-start workflow and current priority name lists.

### Icon Maintenance & Audit Process

Previous AI-assisted sessions produced many ad-hoc symlinks and some duplication. Going forward we use a repeatable process:

1. **Identify the real name** an app or widget is requesting (use the sources above — never assume).
2. **Check current resolution**: `kiconfinder6 <name>` (note whether it comes from NeoWin or falls back to breeze).
3. **Add the mapping** using the documented symlink pattern in the correct context directory (see `index.theme` + the table earlier in this section). Also handle the `-symbolic` variant and `@2x` scales when relevant.
4. **Test**:
   - Re-run `kiconfinder6`.
   - `./install.sh install` (or just the icon copy step) + `kbuildsycoca6 --noincremental`.
   - Exercise the UI element in the real app (Dolphin sidebar + context menu, file picker, System Settings, etc.) in both light and dark mode.
5. **Document** the addition in `icons/MAPPINGS.md` and (if significant) here in CLAUDE.md.
6. **Audit periodically** with the Icon Explorer + targeted `kiconfinder6` runs against the priority lists in MAPPINGS.md.

See `icons/MAPPINGS.md` for the current quick-start commands, duplication policy, and high-priority name lists (Recent/History, core context-menu actions, etc.).

---

## Color Architecture

Understanding this model prevents circular bugs. There are **two independent color systems** in KDE Plasma that do not talk to each other.

### Layer A — Kirigami/Qt widget colors (text, labels, buttons in QML)

**Source: always the active KDE color scheme** (`kdeglobals` → `NeoWinLight/Dark.colors`).
The plasma theme's `colors` file does **not** affect this layer.

Which group from the color scheme is used depends on the containment's `colorSet`:

| Context | colorSet | Color scheme group |
|---|---|---|
| Lock screen clock | `Complementary` | `[Colors:Complementary]` |
| Panel plasmoids (clock, systray text) | `Complementary` (inherited) | `[Colors:Complementary]` |
| Desktop plasmoids (clock widget text) | `Window` | `[Colors:Window]` |
| App window chrome | `Window` | `[Colors:Window]` |
| App lists / file managers | `View` | `[Colors:View]` |
| Toolbars / app headers | `Header` | `[Colors:Header]` |
| Tooltips | `Tooltip` | `[Colors:Tooltip]` |
| Selected text / items | `Selection` | `[Colors:Selection]` |

### Layer B — KSvg/SVG rendering (panel background, widget frames, borders)

**Source: plasma theme `colors` file if present; otherwise falls back to the active KDE color scheme.**
KSvg substitutes CSS classes in SVG files:

| CSS class in SVG | Maps to |
|---|---|
| `.ColorScheme-Background` | `Colors:Window.BackgroundNormal` |
| `.ColorScheme-Text` | `Colors:Window.ForegroundNormal` |
| `.ColorScheme-Highlight` | `Colors:Selection.BackgroundNormal` |
| `.ColorScheme-HighlightedText` | `Colors:Selection.ForegroundNormal` |

Utterly-Round's metadata declares `"follows all color scheme"` — its SVG files use these CSS classes throughout, so they adapt automatically without a `colors` file.

### Full What-Controls-What Map

| Visual element | Layer | Driven by |
|---|---|---|
| Lock screen clock text | A | `NeoWinLight/Dark.colors [Colors:Complementary] ForegroundNormal` |
| Panel background color | B | `Utterly-Round` SVG → `[Colors:Window] BackgroundNormal` from active scheme |
| Panel clock / systray text | A | `[Colors:Complementary] ForegroundNormal` |
| Desktop widget text | A | `[Colors:Window] ForegroundNormal` |
| Desktop widget background | B | `Utterly-Round` SVG → `[Colors:Window] BackgroundNormal` from active scheme |
| App window text & bg | A | `[Colors:Window]` |
| File manager lists | A | `[Colors:View]` |
| Toolbar / header areas | A | `[Colors:Header]` |
| Tooltips | A | `[Colors:Tooltip]` |
| Window titlebar text/bg | Aurorae SVG + `[WM]` | `[WM] activeForeground / activeBackground` in color scheme |
| Auto dark/light trigger | kded plugin | `kdeglobals AutomaticLookAndFeel` + Night Color |

### NeoWin Invariants — DO NOT CHANGE THESE

**`[Colors:Complementary]` must be identical in both light and dark schemes** (dark bg + white text):
- Lock screen renders on an always-dark blurred wallpaper — needs white text regardless of mode
- Panel plasmoids inherit Complementary — same requirement
- NeoWinLight and NeoWinDark both set: `BackgroundNormal=42,46,50` / `ForegroundNormal=252,252,252`
- Never "fix" this to a light bg in NeoWinLight — it will break the panel or lock screen

**Lock screen always uses a dedicated QML override shipped in the LAF packages**
- Even with correct `[Colors:Complementary]`, the stock `LockScreenUi.qml` + Breeze `Clock.qml` can fail to pick up light `textColor` for custom light LAFs (inheritance / timing / greeter context issues observed after the 2026-05 color scheme fix).
- Both `neowin-light` and `neowin-dark` now ship `contents/lockscreen/` (full snapshot of the Plasma shell's lockscreen QMLs + 1-line patch in `LockScreenUi.qml` that does `Kirigami.Theme.textColor: "#fcfcfc"` right after setting `colorSet: Complementary`).
- This guarantees white clock text on the dark blurred background in *both* modes. The patch is the only NeoWin change; other files are verbatim copies for a self-contained override.
- Maintenance: when Plasma updates the lockscreen QML, diff the stock files and re-apply the tiny patch (and update this note with the Plasma version tested).

**Do not add a `colors` file to `plasma-theme/Utterly-Round/`:**
- Utterly-Round's SVGs adapt to the KDE color scheme automatically (FollowsColorScheme)
- A `colors` file overrides **all** SVG CSS class colors simultaneously for both modes
- Adding one with dark backgrounds makes the panel dark in light mode too
- `install.sh` removes any stale `colors` file from the installed theme on every run

### Common Changes Guide

**Changing accent color:**
Edit `DecorationFocus`, `DecorationHover`, `ForegroundActive` in all `[Colors:*]` groups in both `NeoWinLight.colors` and `NeoWinDark.colors`. Current: `0,120,212` (Windows 11 blue) in light, `61,174,233` in dark.

**Making the panel look different:**
The panel background comes from `plasma-theme/Utterly-Round/widgets/panel-background.svgz` via `.ColorScheme-Background` → `[Colors:Window].BackgroundNormal` in the active scheme. To change panel background: edit the SVG directly, or change `BackgroundNormal` in `[Colors:Window]` (affects all window backgrounds too).

**Changing desktop widget appearance:**
Same path as panel — `widgets/background.svgz` uses the same CSS classes. Text color comes from `[Colors:Window].ForegroundNormal` in the KDE color scheme.

**Adding a new plasmoid and its text looks wrong:**
Find which `colorSet` the plasmoid or its containment sets, then adjust the corresponding `[Colors:*]` group in the color schemes.

**What NOT to do:**
- Do not add `plasma-theme/Utterly-Round/colors` — it breaks light mode by darkening panel backgrounds
- Do not change `[Colors:Complementary]` in NeoWinLight to light values — breaks lock screen clock and panel text
- Do not set `[Colors:Window].ForegroundNormal` to white in NeoWinLight — breaks all app window text

---

## How It Works

### Install Flow
`./install.sh install` does two things:
1. **install_assets()** — copies all theme files to XDG directories under `~/.local/share/`
2. **apply_config()** — uses `kwriteconfig6` to set all KDE config keys, then applies the correct look-and-feel for the current time of day

### Auto Dark/Light Switching

**Mechanism (Plasma 6.1+):** A kded6 plugin (`lookandfeelautoswitcher.so`) subscribes to KWin NightLight's `daylight` D-Bus property. When it changes (sunrise/sunset transition), the plugin calls `lookandfeeltool` to swap the entire look-and-feel package — cursors, colors, window decoration — atomically.

Config keys written to `kdeglobals [KDE]`:
- `AutomaticLookAndFeel=true`
- `DefaultDarkLookAndFeel=neowin-dark`
- `DefaultLightLookAndFeel=neowin-light`

**Critical dependency: KWin NightLight must have a working schedule.** The autoswitcher only fires when `daylight` transitions between `true` and `false`. If NightLight has no scheduled transitions (`scheduledTransitionDateTime=0`), the autoswitcher never fires and the theme is stuck. This happens when Night Color is in `Mode=0` (automatic location) but geoclue2 is not installed or not providing location data.

**What `apply_config` does on install/reinstall:**
1. Writes the `AutomaticLookAndFeel` keys
2. Calls `configure_night_color()` to check if NightLight has a working schedule:
   - If transitions are already scheduled → leaves Night Color untouched
   - If mode is non-zero (user set up location or fixed times) → leaves it untouched
   - If mode=0 with no transitions (geoclue broken) → prompts: install geoclue2, use fixed times 07:00/19:00, or skip
3. Queries `org.kde.KWin.NightLight.daylight` via D-Bus and applies `neowin-light` or `neowin-dark` to match current time (falls back to dark if no session)
4. Reloads the `lookandfeelautoswitcher` kded module so it re-evaluates immediately

**Night Color modes** (stored in `kwinrc [NightColor] Mode`):
- `0` — Automatic location via geoclue2 (requires `geoclue` package)
- `1` — Manual location (lat/lon in `kwinrc [Location]`, KWin computes sunrise/sunset)
- `2` — Fixed times (values in `kwinrc [Times] SunriseStart` / `SunsetStart`)
- `3` — Always on (night color active all the time, no switching)

Configure via System Settings → Colors & Themes → Night Color. The installer does **not** store or hardcode location data.

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
- Color scheme files: `NeoWinDark.colors` / `NeoWinLight.colors`. Internal `[General] ColorScheme=` key must match the filename stem (that's the ID KDE writes into `kdeglobals`); `Name=` is the display label.
- Win7 sound pack has 13 sub-schemes (Afternoon, Calligraphy, Characters, Cityscape, Delta, Festival, Garden, Heritage, Landscape, Quirky, Raga, Savanna, Sonata). Each has original `.wav` files plus a `stereo/` dir with freedesktop-mapped names.
- Sound event names in `stereo/` map freedesktop event names → Windows `.wav` files. When swapping a pack, verify semantic alignment (e.g. `power-unplug` → Windows Hardware Remove, **not** Ringout; `device-added` → Hardware Insert). Historically some packs had ring-out stolen for power-unplug — check against the `originals/` dir when adding a new pack.
- The repo is ~239MB due to bundled assets (icons are the biggest chunk at ~143MB).
- `config/` directory contains reference snapshots, not actively used by the installer.
- Auto dark/light switching requires a working Night Color schedule. `Mode=0` (automatic location) needs `geoclue` installed; without it, `daylight` stays `false` permanently and the autoswitcher never fires. Installer detects and prompts for this. Use `Mode=1` (manual lat/lon) or `Mode=2` (fixed times) as alternatives — both work without geoclue.
- Lock screen clock color: see the "Lock screen always uses a dedicated QML override" section above (color scheme Complementary + LAF-shipped LockScreenUi.qml patch). The color-only attempt (commit 42548c4a) was insufficient on its own.

## Upstream Limitations (won't fix here)

- **Systray icons are monochrome by Plasma design.** Volume/network/bluetooth/brightness widgets in Plasma 6 hardcode `*-symbolic` icon names and force `ColorScheme-Text` tinting — colored icons bundled in NeoWin are not used for those widgets. Weather widget is an exception because it renders OpenWeatherMap PNGs directly. Fixing this would require patching Plasma widget sources upstream.
- **Willow Blur aurorae titlebar flicker on Wayland.** The four bundled Willow variants all use the Blur suffix; KWin recomputes the behind-blur region on every titlebar repaint, which can cause flicker/jitter. This is a KWin+aurorae+blur interaction, not something NeoWin can patch. Workaround: switch to a non-blur aurorae theme (none bundled; would need to be added) or a different decoration engine.
- **Desktop clock/widget text unreadable on dark wallpaper in light mode without widget background.** Desktop plasmoids use `colorSet: Kirigami.Theme.Window`, which maps to `[Colors:Window].ForegroundNormal = 26,26,26` in NeoWinLight — dark text. Without a widget background, this renders directly over the wallpaper. If the wallpaper is dark, the text is unreadable. Setting `ForegroundNormal` to white would break all app window text (same color group). The correct fix would require the clock widget QML to switch to `Kirigami.Theme.Complementary` (always white fg) when background is disabled — that's an upstream Plasma change. Workaround: enable the widget background.
- **Application Dashboard and power/leave menu always dark even in light mode.** Both inherit `colorSet: Kirigami.Theme.Complementary` from the panel containment. NeoWin's `[Colors:Complementary]` is intentionally dark in both modes (required for panel text and lock screen — see NeoWin Invariants). Cannot be made light without patching the applet QML or splitting Complementary into panel-context vs popup-context. In Win11 these popups are light in light mode — this is a known visual fidelity gap. Upstream fix required; workaround: none. Dark mode is always correct; this only affects the light mode experience.

## Goals & Intentions

1. **Portable theme backup**: Clone this repo on any KDE Plasma 6 system, run `install.sh install`, and get the exact same desktop appearance.
2. **Complete coverage**: Every visible UI element should be themed — no fallback to generic KDE defaults that break the aesthetic.
3. **Clean light/dark switching**: Both variants should look polished, not just "dark mode with wrong icons."
4. **Sound customization**: Multiple Windows-era sound packs bundled so users can pick their favorite nostalgia.
5. **Minimal dependencies**: Only requires standard KDE tools (`kwriteconfig6`, `lookandfeeltool`, `kbuildsycoca6`). No Python, no extra packages.

## What Could Be Improved

- Rename `icons/win11-kde/` directory to `icons/neowin/` for consistency (requires re-commit of ~34k files).
- Add a `--dry-run` flag to the installer.
- Bundle actual wallpaper images (installer's `wallpaper` cmd just wires up KDE's POTD plugin; no static images shipped).
- GTK theme integration (user has a separate `~/.themes/Windows10` GTK theme that needed fixes).
- Upstream the icon symlink additions back to the Windows-Eleven project.
- Add screenshots to README.
