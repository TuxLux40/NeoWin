---
name: neowin
description: >
  NeoWin repo skill — work on the NeoWin KDE Plasma 6 Windows 11 theme. Covers
  everything needed to contribute to this repo: installer internals, Plasma Style
  (Utterly-Round SVGs), Aurorae window decorations (Willow Blur), icon theme
  (win11-kde), color schemes (NeoWinDark/Light), look-and-feel packages, sound
  theme, KWin effects, and the auto dark/light switching system. Also covers
  translating Windows 11 Fluent Design tokens (Mica, Acrylic, accent, elevation,
  corner radii, Segoe typography) into KDE constructs. Use this skill whenever
  the user is working in the NeoWin repo, mentions any NeoWin component by name,
  asks about the installer, wants to extend or fix the theme, asks about
  dark/light switching, color scheme invariants, or anything about making KDE
  look like Windows 11 in the context of this repo.
---

# NeoWin — KDE Plasma 6 Windows 11 Theme

NeoWin is a self-contained KDE Plasma 6 theme that replicates Windows 11 aesthetics.
Everything ships in this repo. One installer, no build system.

---

## Repo Architecture at a Glance

```
NeoWin/
├── install.sh                  # All operations go through here
├── icons/win11-kde/            # Icon theme (~34k files) → installed as "NeoWin"
├── aurorae/                    # 4 Willow Blur window decoration variants
│   ├── WillowDarkBlur/
│   ├── WillowDarkBlurAlt/
│   ├── WillowLightBlur/
│   └── WillowLightBlurAlt/
├── cursors/                    # WinSur cursor themes (dark + white)
├── plasma-theme/Utterly-Round/ # Plasma desktop theme (blur + transparency)
├── color-schemes/
│   ├── NeoWinDark.colors
│   └── NeoWinLight.colors
├── look-and-feel/
│   ├── neowin-dark/            # LAF package + lockscreen QML override
│   └── neowin-light/           # LAF package + lockscreen QML override
├── sounds/win11-kde/           # Win11 sound theme (freedesktop names)
├── panel-layout/               # Saved panel config (not auto-applied)
└── config/                     # Reference config snapshots
```

Install locations after `./install.sh install`:
- Icons → `~/.local/share/icons/NeoWin`
- Aurorae → `~/.local/share/aurorae/themes/Willow{Dark,Light}Blur{,Alt}/`
- Cursors → `~/.local/share/icons/WinSur-{dark,white}-cursors/`
- Plasma theme → `~/.local/share/plasma/desktoptheme/Utterly-Round/`
- Color schemes → `~/.local/share/color-schemes/NeoWin{Dark,Light}.colors`
- Look-and-feel → `~/.local/share/plasma/look-and-feel/neowin-{dark,light}/`
- Sounds → `~/.local/share/sounds/neowin/`

---

## Installer Commands

```bash
./install.sh install          # Copy assets + apply KDE config
./install.sh uninstall        # Remove all installed assets
./install.sh restore-panel    # Copy panel-layout/ → ~/.config/plasma-org.kde.plasma.desktop-appletsrc
./install.sh wallpaper        # Set Picture of the Day wallpaper (default: bing)
./install.sh wallpaper apod   # Use NASA APOD provider
./install.sh help
```

After `restore-panel`:
```bash
kquitapp6 plasmashell && kstart plasmashell
```

Force-refresh caches / reload KWin:
```bash
kbuildsycoca6 --noincremental
qdbus6 org.kde.KWin /KWin reconfigure
```

### Installer Internals

`install_assets()` — copies all theme assets to XDG dirs (see arch map above). Note: source dir is still named `icons/win11-kde/` but installed as `NeoWin` (legacy artifact). Runs `kbuildsycoca6 --noincremental` at end.

`apply_config()` — writes via `kwriteconfig6`:
- `kdeglobals [KDE] AutomaticLookAndFeel=true`, `DefaultDarkLookAndFeel=neowin-dark`, `DefaultLightLookAndFeel=neowin-light`
- `kdeglobals [Icons] Theme=NeoWin`, `[KDE] widgetStyle=Breeze`, `[Sounds] Theme=neowin`
- `kwinrc [org.kde.kdecoration2] library=org.kde.kwin.aurorae.v2`, `theme=__aurorae__svg__WillowDarkBlur`, `BorderSize=NoSides`, `BorderSizeAuto=false`, `ButtonsOnLeft=M`
- `kwinrc [TabBox] LayoutName=coverswitch`
- `kwinrc [Plugins] blurEnabled=true`, `[Effect-blur] BlurStrength=13`, `[NightColor] Active=true`
- `plasmarc [Theme] name=Utterly-Round`
- `ksplashrc [KSplash] Engine=none`, `Theme=None`
- Calls `configure_night_color()` to validate Night Color schedule
- Detects current `daylight` state via `qdbus6 org.kde.KWin.NightLight` → applies `neowin-light` or `neowin-dark`
- Reloads KWin + `lookandfeelautoswitcher` kded module

`restore_panel()` — copies `panel-layout/plasma-org.kde.plasma.desktop-appletsrc` → `~/.config/`. Not called from `install`.

`wallpaper [provider]` — pokes plasmashell via `qdbus6` to switch all desktops to `org.kde.potd`. Requires Plasma running.

`reload_plasma` — `kbuildsycoca6 --noincremental` + KWin reconfigure + `kquitapp6 plasmashell` + `kstart plasmashell`.

---

## Auto Dark/Light Switching

**Mechanism (Plasma 6.1+):** kded6 plugin `lookandfeelautoswitcher.so` subscribes to KWin NightLight's `daylight` D-Bus property. On transition it calls `lookandfeeltool` to swap the entire LAF package atomically.

Config keys in `kdeglobals [KDE]`:
- `AutomaticLookAndFeel=true`
- `DefaultDarkLookAndFeel=neowin-dark`
- `DefaultLightLookAndFeel=neowin-light`

**Critical dependency:** KWin NightLight must have a working schedule. If NightLight has no scheduled transitions (`scheduledTransitionDateTime=0`), the autoswitcher never fires and the theme is stuck.

Night Color modes (`kwinrc [NightColor] Mode`):
- `0` — Automatic location via geoclue2 (requires `geoclue` package)
- `1` — Manual location (lat/lon in `kwinrc [Location]`)
- `2` — Fixed times (`kwinrc [Times] SunriseStart` / `SunsetStart`)
- `3` — Always on (no switching)

`Mode=0` without geoclue2 installed = `daylight` stays `false` permanently. Installer detects this and prompts.

---

## Color Architecture

Two independent color systems in KDE Plasma — they do NOT talk to each other.

### Layer A — Kirigami/Qt widget colors (text, labels, buttons)
Source: always the active KDE color scheme (`NeoWinLight/Dark.colors`). The plasma theme's `colors` file does NOT affect this layer.

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
Source: plasma theme `colors` file if present; otherwise falls back to active KDE color scheme.
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
| Panel background color | B | `Utterly-Round` SVG → `[Colors:Window] BackgroundNormal` |
| Panel clock / systray text | A | `[Colors:Complementary] ForegroundNormal` |
| Desktop widget text | A | `[Colors:Window] ForegroundNormal` |
| Desktop widget background | B | `Utterly-Round` SVG → `[Colors:Window] BackgroundNormal` |
| App window text & bg | A | `[Colors:Window]` |
| File manager lists | A | `[Colors:View]` |
| Toolbar / header areas | A | `[Colors:Header]` |
| Tooltips | A | `[Colors:Tooltip]` |
| Window titlebar text/bg | Aurorae SVG + `[WM]` | `[WM] activeForeground / activeBackground` |
| Auto dark/light trigger | kded plugin | `kdeglobals AutomaticLookAndFeel` + Night Color |

---

## NeoWin Color Invariants — DO NOT CHANGE

**`[Colors:Complementary]` must be identical in both light and dark schemes** (dark bg + white text):
- Lock screen renders on always-dark blurred wallpaper — needs white text regardless of mode
- Panel plasmoids inherit Complementary — same requirement
- Both `NeoWinLight.colors` and `NeoWinDark.colors`: `BackgroundNormal=42,46,50` / `ForegroundNormal=252,252,252`
- Never "fix" this to a light bg in NeoWinLight — it will break the panel or lock screen

**Do not add a `colors` file to `plasma-theme/Utterly-Round/`:**
- Utterly-Round's SVGs adapt to the KDE color scheme automatically (FollowsColorScheme)
- A `colors` file overrides ALL SVG CSS class colors simultaneously for both modes
- Adding one with dark backgrounds makes the panel dark in light mode too
- `install.sh` removes any stale `colors` file from the installed theme on every run

**Lock screen always uses a dedicated QML override shipped in the LAF packages:**
- Both `neowin-light` and `neowin-dark` ship `contents/lockscreen/` (full snapshot of Plasma shell lockscreen QMLs + 1-line patch in `LockScreenUi.qml`: `Kirigami.Theme.textColor: "#fcfcfc"` after setting `colorSet: Complementary`)
- This guarantees white clock text on dark blurred background in both modes
- Maintenance: when Plasma updates lockscreen QML, diff stock files and re-apply the tiny patch

### Common Changes

**Changing accent color:**
Edit `DecorationFocus`, `DecorationHover`, `ForegroundActive` in all `[Colors:*]` groups in both color schemes. Current: `0,120,212` (Windows 11 blue) in light, `61,174,233` in dark.

**Making the panel look different:**
Panel background comes from `plasma-theme/Utterly-Round/widgets/panel-background.svgz` via `.ColorScheme-Background` → `[Colors:Window].BackgroundNormal`. Edit the SVG directly, or change `BackgroundNormal` in `[Colors:Window]` (affects all window backgrounds too).

**Changing desktop widget appearance:**
Same path as panel — `widgets/background.svgz` uses same CSS classes. Text color from `[Colors:Window].ForegroundNormal`.

---

## Icon Theme Architecture

Source: `icons/win11-kde/` — based on Windows-Eleven by zayronxio. Installed as `NeoWin`.

Inheritance chain: NeoWin → breeze → hicolor

`FollowsColorScheme=true` in `index.theme` makes symbolic icons adapt to light/dark automatically.

### How KDE Resolves Icons by Area

| UI area | Context dir | Sizes | Icon names |
|---|---|---|---|
| Dolphin sidebar (Places) | `places/` | 16–48px | `user-home`, `folder-documents`, `folder-download`, etc. |
| Discover category sidebar | `categories/` | 32px + symbolic | `applications-games`, `-graphics`, `-multimedia`, etc. |
| System Settings sidebar | `apps/scalable/` (fallthrough) | 22px | `preferences-desktop-*`, `preferences-system-*`, etc. |
| App launcher / taskbar | `apps/scalable/` | scalable | App `.desktop` `Icon=` value |
| Systray | `status/` | 16–22px | Always `-symbolic` names, always monochrome in Plasma 6 |

`apps/scalable` declares `MinSize=16, MaxSize=512` — every `preferences-*.svg` in that directory is served at 22px for System Settings. No separate `preferences/` context directory needed.

### Adding or Fixing Icons

1. Find the real name: `kiconfinder6 <name>` or `QT_LOGGING_RULES="kf.iconthemes.debug=true" <app> 2>&1 | grep -i "<keyword>"`
2. Check current resolution: `kiconfinder6 <name>` — note whether it comes from NeoWin or breeze
3. Add symlink in the correct context directory
4. Install: `rsync -a --delete icons/win11-kde/ ~/.local/share/icons/NeoWin/ && kbuildsycoca6 --noincremental`
5. Restart the affected app (icons are cached per-process)
6. Document in `icons/MAPPINGS.md`

For detailed icon debugging workflow: read `references/icon-debug.md`.

### What NOT To Do

- Do not add a `preferences/` context directory — redundant, `apps/scalable` already covers it
- Do not add icons for systray applets in `status/` to fix colors — Plasma 6 forces monochrome tinting regardless
- Do not remove `FollowsColorScheme=true` from `index.theme`

---

## Upstream Limitations (won't fix in NeoWin)

- **Systray icons are monochrome by Plasma design.** Volume/network/bluetooth/brightness widgets hardcode `*-symbolic` icon names and force `ColorScheme-Text` tinting. Fixing requires patching Plasma widget sources upstream.
- **Willow Blur aurorae titlebar flicker on Wayland.** KWin recomputes blur region on every titlebar repaint. KWin+aurorae+blur interaction. Workaround: switch to a non-blur aurorae theme.
- **Desktop clock text unreadable on dark wallpaper in light mode** without widget background. Desktop plasmoids use `colorSet: Kirigami.Theme.Window` → `[Colors:Window].ForegroundNormal = 26,26,26` in NeoWinLight. Workaround: enable widget background.
- **Application Dashboard and power/leave menu always dark in light mode.** Both inherit `colorSet: Kirigami.Theme.Complementary` from panel containment. NeoWin's Complementary is intentionally dark in both modes. Cannot be made light without patching applet QML.

---

# KDE Theming Reference

## Quick Orientation

| What to theme | Type |
|---|---|
| Panel, desktop, tooltips, widgets, clock face | **Plasma Style** |
| Window titlebar + close/min/max buttons | **Aurorae decoration** |
| A new widget/applet on the desktop | **Plasma Widget (QML)** |
| Visual compositor effect (slide, fade, etc.) | **KWin Effect** |
| Wallpaper accent color | **Wallpaper metadata** |

---

## Plasma Styles

Read `references/plasma-style.md` for the full reference. Core workflow below.

### Install location
```
~/.local/share/plasma/desktoptheme/<theme-id>/
```
System themes live in `/usr/share/plasma/desktoptheme/`. Always work in the user location.

### Scaffold a new theme

Fastest start is forking Breeze:
```bash
cp -r /usr/share/plasma/desktoptheme/default ~/.local/share/plasma/desktoptheme/mytheme
```
Then edit `metadata.json` — the `Id` must match the folder name.

Minimum files from scratch:
```
mytheme/
├── metadata.json          # required
├── colors                 # optional but strongly recommended
├── plasmarc               # optional (blur/contrast/fallback)
├── widgets/
│   └── panel-background.svg
└── dialogs/
    └── background.svg
```

### metadata.json (Plasma 6 / KDE Frameworks 6+)
```json
{
    "KPlugin": {
        "Authors": [{"Name": "You", "Email": "you@example.com"}],
        "Name": "My Theme",
        "Description": "A short description",
        "Id": "mytheme",
        "Version": "0.1",
        "License": "GPL"
    },
    "X-Plasma-API": "5.0"
}
```
Bump `Version` every time you change SVGs so Plasma refreshes its cache.

### Testing & cache clearing
```bash
rm -r ~/.cache/plasma*
plasmashell --replace &
```
Or select the theme in **System Settings → Appearance → Plasma Style**.

### Color scheme integration

To make SVGs follow system colors, add a `hint-apply-color-scheme` element anywhere in the SVG. For fine-grained control, embed a `<style id="current-color-scheme">` block and use `ColorScheme-Text`, `ColorScheme-Highlight`, etc. as CSS classes with `fill="currentColor"`.

---

## Aurorae Window Decorations

Read `references/aurorae.md` for layout config reference. Core workflow:

### Install location
```
~/.local/share/aurorae/themes/<ThemeName>/
```

### Package structure
```
MyDecoration/
├── metadata.desktop
├── MyDecorationrc        # must be <FolderName>rc
├── decoration.svg        # window frame (9-slice: topleft/top/topright/…/center)
├── close.svg
├── maximize.svg
├── minimize.svg
└── restore.svg           # optional
```

### metadata.desktop
```ini
[Desktop Entry]
Name=My Decoration
Comment=A custom window decoration
X-KDE-PluginInfo-Name=MyDecoration
X-KDE-PluginInfo-Author=You
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL
```

### decoration.svg element IDs

The window frame uses a 9-slice FrameSvg. Required elements (prefix = `decoration`):
- `decoration-topleft`, `decoration-top`, `decoration-topright`
- `decoration-left`, `decoration-center`, `decoration-right`
- `decoration-bottomleft`, `decoration-bottom`, `decoration-bottomright`

Additional prefixes: `decoration-inactive` (dimmed windows), `decoration-maximized` (maximized state).

### Button SVGs

Each button SVG needs at minimum an `active` element (the center). Optional states: `inactive`, `hover`, `hover-inactive`, `pressed`, `deactivated`.

Supported buttons: `close`, `minimize`, `maximize`, `restore`, `alldesktops`, `keepabove`, `keepbelow`, `shade`, `help`.

---

## Plasma Widgets (Plasmoids)

Read `references/widgets.md` for QML API reference.

### Install location
```
~/.local/share/plasma/plasmoids/<com.yourname.widgetid>/
```
Use reverse-DNS naming, e.g. `com.github.yourname.myClock`.

### Scaffold from an existing widget (recommended)
```bash
cp -r /usr/share/plasma/plasmoids/org.kde.plasma.analogclock \
       ~/.local/share/plasma/plasmoids/com.yourname.mywidget
# Edit Id and Name in metadata.json, remove Name[xx] translation lines
```

### Minimum structure
```
com.yourname.mywidget/
├── metadata.json
└── contents/
    └── ui/
        └── main.qml
```

### Testing
```bash
plasmawindowed com.yourname.mywidget
```

---

## KWin Declarative Effects

Read `references/kwin-effects.md` for the QML API.

### Structure
```
my-effect/
└── package/
    ├── metadata.json
    └── contents/
        └── ui/
            └── main.qml   # entry point
```

### Install
```bash
kpackagetool6 --type KWin/Effect --install package/
```

---

## Wallpaper Accent Colors

In the wallpaper's `metadata.json`, add:
```json
{
    "KPlugin": {"Id": "mywallpaper", "Name": "My Wallpaper", "License": "CC-BY-SA-4.0"},
    "X-KDE-PlasmaImageWallpaper-AccentColor": "#3daee9"
}
```
Use `{"Light": "#color", "Dark": "#color"}` for light/dark-aware variants.

---

## Debugging Icon Issues

Read `references/icon-debug.md` for the full diagnostic workflow.

**Quick triage:**
1. `kiconfinder6 <name>` — is it resolving to NeoWin at all?
2. Check the path context — `apps/scalable/` for a systray icon means wrong directory
3. Check the size — if only a 48px entry exists and the app requests 16px, add a 16px entry
4. Restart the affected app after any fix (`kbuildsycoca6 --noincremental` alone is not enough)

---

## Common KDE Theming Gotchas

- **Plasma Style SVGs not updating?** Clear `~/.cache/plasma*` and restart plasmashell. Also bump `Version` in `metadata.json`.
- **Element IDs must be exact.** Wrong IDs silently fall back to Breeze. Check IDs in Inkscape via Object → Object Properties.
- **Prior to KF6:** themes used `metadata.desktop` instead of `metadata.json`, and `plasmarc` was merged into `metadata.desktop`. Stick with `metadata.json` for new themes.
- **`hint-apply-color-scheme`** makes Plasma colorize the SVG; omit it if you want pixel-perfect custom colors.
- **Border tiling vs stretching:** borders are tiled by default; add a `hint-stretch-borders` element if you want them stretched.
- **Center element:** scaled by default; add `hint-tile-center` to tile instead.
- **Aurorae:** if a button SVG is missing entirely, that button won't appear — there's no Breeze fallback for buttons.
- **Systray icons are always monochrome** in Plasma 6 — the applet forces `-symbolic` names + `ColorScheme-Text` tinting. Colored icons in `status/` are not used for systray.
- **App launcher / power menu dark in light mode** — inherits `colorSet: Complementary` from the panel containment. Cannot be fixed without patching applet QML.

---

# Windows 11 Fluent Design → KDE Theming Guide

This maps the official Windows 11 design language to concrete KDE Plasma theming values.
In the context of NeoWin, these tokens define the target aesthetic — CLAUDE.md documents where
each one is already implemented and what's still aspirational.

---

## Design Principles

Windows 11 prioritizes these qualities — match them when designing the KDE theme:

| Win11 Principle | What it means for your KDE theme |
|---|---|
| **Effortless** | Clean, uncluttered panels. Minimal decoration. |
| **Calm** | Neutral base palette. Subtle shadows. Color used sparingly. |
| **Personal** | Follow system accent color. Support light/dark switching. |
| **Familiar** | Keep standard KDE interaction patterns — don't surprise the user. |
| **Complete** | Consistent corner radii, shadows, and spacing everywhere. |

---

## Color System

### Light / Dark Modes

Windows 11 uses two modes. Map them to KDE color schemes:

| Win11 concept | KDE equivalent |
|---|---|
| Light mode | A color scheme with `[Colors:Window] BackgroundNormal=#FFFFFF` and dark text |
| Dark mode | A color scheme with `[Colors:Window] BackgroundNormal=#202020` and light text |
| Default follow-system | Ship two `.colors` files; user selects in System Settings |

**Key principle:** Darker backgrounds = less important. Lighter surfaces = higher visual priority. In KDE Plasma Style SVGs, the panel/widget background should be the mid-tone; dialogs/popups should float above with a lighter (light mode) or slightly lighter-dark (dark mode) fill.

### Accent Color

- Win11 default accent: **#0078D4** (Windows Blue)
- Accent is used **sparingly** — only on active/focused/selected states
- In the KDE `colors` file, set `[Colors:Selection] BackgroundNormal=#0078D4`
- Buttons, toggles, progress bars, checked states use accent
- Avoid accent on backgrounds or decorative elements

### Recommended Palette (light mode baseline)

```
App background (Mica base):    #F3F3F3  (warm off-white)
Card / elevated surface:       #FFFFFF
Panel / sidebar:               #F9F9F9
Stroke / border:               rgba(0,0,0,0.08)  → approx #EBEBEB
Primary text:                  #1A1A1A
Secondary text:                #616161
Disabled text:                 #A0A0A0
Accent:                        #0078D4
Accent hover:                  #006CBE
Accent pressed:                #005FAD
```

Dark mode equivalents:
```
App background (Mica base):    #202020
Card / elevated surface:       #2C2C2C
Panel / sidebar:               #272727
Stroke / border:               rgba(255,255,255,0.08)
Primary text:                  #FFFFFF
Secondary text:                #ABABAB
Accent:                        #60CDFF  (Win11 dark-mode accent blue)
```

---

## Elevation & Shadows

Win11 uses elevation values + stroke-width to communicate layering. Shadow intensity varies by theme.

| Surface | Elevation value | Stroke width | KDE mapping |
|---|---|---|---|
| Window | 128 | 1 | Aurorae decoration shadow |
| Dialog | 128 | 1 | `dialogs/background.svg` shadow glow |
| Flyout / Menu | 32 | 1 | `widgets/tooltip.svg`, popup background |
| Tooltip | 16 | 1 | `widgets/tooltip.svg` |
| Card | 8 | 1 | Contained widget backgrounds |
| Control (rest/hover) | 2 | 1 | Button/input borders |
| Control (pressed) | 1 | 1 | Pressed state — shadow collapses |
| Flat layer | 1 | 1 | Base layer, no visual shadow |

**Rule:** Higher elevation → larger, softer shadow. Lower elevation → tight or no shadow.

### Translating to Aurorae / Plasma SVG

For **window shadows** (Aurorae):
- Use KWin shadow blur. Recommended for Win11 feel: `ShadowOffset=32`, blur spread `~64px`
- Shadow color: `rgba(0,0,0,0.15)` light mode / `rgba(0,0,0,0.35)` dark mode
- In `<ThemeName>rc`: `ShadowColor=0,0,0` with low opacity

For **flyout/dialog shadows** in Plasma Style SVGs:
- Add a soft drop-shadow filter to the SVG `background` element
- Use a `<filter>` with `feDropShadow` — stdDeviation around 8–16px, dy=4, opacity=0.12

**Layering system** — Win11 uses two explicit layers:
1. **Base layer** — navigation, commands, menus (slightly off-white / slightly lighter dark)
2. **Content layer** — main content area (pure white / slightly elevated dark)

Map this to Plasma Style by giving the panel a slightly tinted background vs widget content areas a purer white/dark.

---

## Geometry (Corner Radii)

Win11 is consistent about this. Apply these radii everywhere in SVGs and QML:

| Context | Corner radius | Win11 examples → KDE target |
|---|---|---|
| Top-level overlays | **8px** | Windows, dialogs, flyouts, menus → Aurorae decoration, `dialogs/background.svg`, `widgets/tooltip.svg` |
| In-page controls | **4px** | Buttons, inputs, checkboxes, lists → button SVGs, input borders |
| Bar elements | **4px** | Progress bars, sliders, scrollbars |
| Touching elements | **0px** | Split buttons, attached flyouts → no rounding on shared edge |
| Maximized / snapped | **0px** | Windows docked to edges |

In Aurorae's `<ThemeName>rc`:
```ini
[General]
# No direct corner radius setting — bake it into decoration.svg
# The 8px rounded frame goes in the SVG corner elements
```

In `decoration.svg`, draw the `decoration-topleft` / `decoration-topright` corners with an 8px arc. The `decoration-bottomleft` / `decoration-bottomright` corners also 8px when not maximized.

For Plasma Style widget SVGs, round the `center` element's path to 8px for dialog backgrounds, 4px for panel-background.

---

## Materials: Mica & Acrylic in KDE

Win11 uses two named materials:

### Mica
- Samples the desktop wallpaper color — blends app with the environment
- Used for the **main app window background** (not transient surfaces)
- Distinguishes focused vs unfocused windows
- **KDE equivalent:** Enable KWin's blur effect + a semi-transparent Plasma Style background
  - In `plasmarc`: `[Wallpaper] BlurRadius=64`
  - Set `background-color: rgba(255,255,255,0.7)` in the Plasma Style SVG (light mode)
  - Dark: `rgba(32,32,32,0.8)`
  - Aurorae decoration: set `Blur=1` in `<ThemeName>rc`

### Acrylic
- Blurs content **behind** a transient surface (flyout, menu, notification)
- More transparent/blurry than Mica
- **KDE equivalent:** `widgets/tooltip.svg` and `dialogs/background.svg` with KWin blur
  - Lower opacity: `rgba(255,255,255,0.6)` light / `rgba(28,28,28,0.75)` dark
  - Requires KWin blur effect enabled (`kcmshell6 kwincompositing`)
  - In `plasmarc` add: `[ContrastEffect] enabled=true\nintensity=0.65\ncontrast=0.45\nsat=1.7`

---

## Typography

Win11 uses **Segoe UI Variable** exclusively. For KDE:

| Win11 role | Font / size | KDE color scheme key |
|---|---|---|
| Display (large titles) | Segoe UI Variable / 68pt | — |
| Title Large | Segoe UI Variable / 40pt | — |
| Title | Segoe UI Variable / 28pt | `[WM] ActiveFont` |
| Subtitle | Segoe UI Variable SemiBold / 20pt | — |
| Body (default) | Segoe UI Variable / 14pt | System font setting |
| Body Strong | Segoe UI Variable SemiBold / 14pt | — |
| Caption | Segoe UI Variable / 12pt | — |

**Practical advice for KDE:**
- Set the system font to **Segoe UI** (if installed) or **Inter** / **Noto Sans** as a fallback
- Font weight for labels: Regular (400); bold labels use SemiBold (600)
- Never use anything below 12pt in a Windows-style theme

---

## Iconography

| Win11 system | KDE equivalent |
|---|---|
| **Segoe Fluent Icons** (system glyphs) | Plasma system icons — use a Windows-style icon theme |
| Single-line style (1px stroke, minimal) | Look for icon themes like `Win11-icon-theme` or `Fluent` on KDE Store |
| App icons: simple, single-metaphor | Use `.ico` → PNG converted at 16/22/32/48/256px sizes |
| Icon sizes: 16, 20, 24, 32, 48 | KDE standard sizes: 16, 22, 32, 48, 64, 128 |

For a Windows-feel icon set (NeoWin already ships `win11-kde` based on Windows-Eleven):
- Source repo: https://github.com/zayronxio/windows-eleven-skin
- Set in System Settings → Appearance → Icons

---

## Putting It Together: KDE Component Mapping

| Windows 11 element | KDE theming target | Notes |
|---|---|---|
| Window frame + titlebar | Aurorae decoration | 8px corners in SVG, Win11-style close/min/max button shapes |
| Close button (red ×) | `close.svg` in Aurorae | Win11 uses a subtle ×, red only on hover |
| Window shadow | Aurorae `ShadowOffset`/blur | Soft, large spread (~64px), low opacity |
| Panel | `widgets/panel-background.svg` | Acrylic-style semi-transparent |
| Taskbar | Panel + plasmoid styling | Centered taskbar, rounded buttons |
| Start menu / launcher | Kickoff / Application Launcher | Hard to make pixel-perfect; use community plasmoids |
| Context menus | `widgets/tooltip.svg` or menu | 8px corners, acrylic, 32-elevation shadow |
| Tooltips | `widgets/tooltip.svg` | 4px corners, 16-elevation shadow |
| Dialogs | `dialogs/background.svg` | 8px corners, 128-elevation shadow, modal scrim |
| Scrollbar | `widgets/scrollbar.svg` | Thin (6–8px) when at rest, wider on hover |
| Notification | `widgets/tooltip.svg` variant | Match flyout style |

---

## Quick Recipe: Minimal Win11 KDE Theme

1. **Fork Breeze** as base: `cp -r /usr/share/plasma/desktoptheme/default ~/.local/share/plasma/desktoptheme/win11-fluent`
2. **Set colors** in the `colors` file: accent `#0078D4`, backgrounds as above
3. **Round SVG corners** in `panel-background.svg` and `dialogs/background.svg` to 8px
4. **Enable blur** in `plasmarc` for panel and dialogs
5. **Create Aurorae decoration** with 8px frame corners, soft shadow, thin buttons
6. **Set font** to Segoe UI Variable or Inter
7. **Install Fluent icon theme** from KDE Store
8. **Enable KWin blur + translucency** effects in compositor settings

---

## Common Fluent Design Pitfalls

- **Don't over-blur** — Mica is subtle. Heavy blur looks more macOS than Windows.
- **Don't over-round** — Win11 uses 8px max on frames. Very large radii (16px+) look wrong.
- **Accent sparingly** — only interactive/active states. Win11 does NOT use accent as a panel background color.
- **Shadows need contrast** — On dark mode, increase shadow opacity (0.35+) or shadows vanish.
- **Stroke matters** — All Win11 surfaces have a 1px border. Add a subtle `rgba(0,0,0,0.08)` stroke to SVG backgrounds in light mode.
- **KWin blur requires compositing** — if disabled, fallback to a solid semi-transparent color.
