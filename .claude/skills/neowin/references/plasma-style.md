# Plasma Style (Desktop Theme) Reference

Source: `/home/oliver/Projects/develop-kde-org/content/docs/plasma/theme/`

---

## File structure

```
~/.local/share/plasma/desktoptheme/<id>/
├── metadata.json          # required: name, id, version
├── plasmarc               # optional: blur, contrast, fallback theme
├── colors                 # optional: color scheme
├── dialogs/
│   └── background.svg     # popup/dialog backgrounds, KRunner
├── widgets/
│   ├── panel-background.svg
│   ├── background.svg
│   ├── button.svg
│   ├── tooltip.svg
│   ├── tasks.svg
│   ├── arrows.svg
│   └── ...
├── icons/                 # optional icon overrides
├── opaque/                # optional: X11-only, no compositing
├── translucent/           # optional: blur-capable variants
└── wallpapers/            # optional: bundled wallpaper packages
```

All SVG files are optional — missing files fall back to the `default` (Breeze) theme.

---

## Background SVG format (most SVGs use this)

Every background SVG is a 9-slice frame. Plasma looks for elements by their `id` attribute:

| Position element IDs | Notes |
|---|---|
| `topleft`, `top`, `topright` | Top row of the frame |
| `left`, `center`, `right` | Middle row |
| `bottomleft`, `bottom`, `bottomright` | Bottom row |

- Corners and edges are painted at native size (can be bitmaps).
- `center` is **scaled** by default (use an actual SVG path, not a raster).
- Edges (`top`, `right`, `bottom`, `left`) are **tiled** by default.

### Cardinal direction prefixes

Some SVGs have multiple frames for different panel positions. Use prefixes `north-`, `east-`, `south-`, `west-` before position IDs — e.g. `west-topleft`, `north-center`.

### Shadow and mask frames

- `shadow-<position>`: for drop shadows (supports gradients and alpha)
- `mask-<position>`: mask elements must be solid black

### Hint elements

Add invisible elements with these IDs to control rendering:

| Hint ID | Effect |
|---|---|
| `hint-stretch-borders` | Stretch edges instead of tiling them |
| `hint-tile-center` | Tile center instead of scaling it |
| `hint-no-border-padding` | Content fills full area including borders |
| `hint-apply-color-scheme` | Colorize entire SVG with system window background color |
| `hint-compose-over-border` | Draw center at full size, composed under borders |
| `hint-top-shadow`, `hint-right-shadow`, `hint-bottom-shadow`, `hint-left-shadow` | Set shadow padding size |

---

## Key SVG files

### widgets/panel-background.svg
Panel backgrounds. Uses cardinal direction prefixes (`north-`, `south-`, `east-`, `west-`) for panel positions. Special elements:
- `[dir]-shadow-<position>`: panel shadow
- `[dir]-hint-<direction>-shadow`: shadow padding
- `[dir]-mask-<position>`: compositing mask

### dialogs/background.svg
Used for: Plasma widget popups on panel, Add Widget pane, KRunner. Standard 9-slice frame.

### widgets/background.svg
Background for Plasma widgets on the desktop. Standard 9-slice frame.

### widgets/button.svg
Buttons throughout Plasma. Frames with prefixes: `normal`, `pressed`, `hover`, `focus`. Each uses the standard 9-slice.

### widgets/tooltip.svg
Tooltip popup background. Standard 9-slice.

### widgets/tasks.svg
Task manager buttons. Prefixes for states: `normal`, `focus`, `hover`, `minimized`, `attention`.

---

## Color scheme integration

### Option 1: Bulk colorization (simple)
Add any element with `id="hint-apply-color-scheme"` in the SVG. Plasma converts the SVG to monochrome and tints it with the system window background color.
- Best for monochromatic themes.
- Less control over exact colors.

### Option 2: CSS classes (flexible)
Embed a `<style id="current-color-scheme">` block inside `<defs>`. Plasma substitutes color values before rendering:

```xml
<defs>
  <style id="current-color-scheme" type="text/css">
    .ColorScheme-Text { color: #232629; }
    .ColorScheme-Background { color: #eff0f1; }
  </style>
</defs>
```

Apply to elements with `class="ColorScheme-Text" fill="currentColor"`.

Available class names:
- `ColorScheme-Text` / `ColorScheme-Background`
- `ColorScheme-Highlight` (follows user accent color)
- `ColorScheme-ViewText` / `ColorScheme-ViewBackground` / `ColorScheme-ViewHover` / `ColorScheme-ViewFocus`
- `ColorScheme-ButtonText` / `ColorScheme-ButtonBackground` / `ColorScheme-ButtonHover` / `ColorScheme-ButtonFocus`

For gradients: wrap `<gradient>` in a `<g class="ColorScheme-X">` since `<stop>` elements don't accept classes.

---

## The `colors` file

Follows KDE color scheme INI format. Key sections a Plasma Style uses:

```ini
[Colors:Window]
ForegroundNormal=35,38,41          # text on standard backgrounds
BackgroundNormal=239,240,241       # default widget background
DecorationHover=61,174,230         # highlight/selection color

[Colors:Button]
ForegroundNormal=35,38,41
BackgroundNormal=239,240,241
ForegroundActive=61,174,230        # button hover tint

[Colors:View]
ForegroundNormal=35,38,41
ForegroundInactive=127,140,141     # placeholder text
ForegroundLink=41,128,185
DecorationFocus=61,174,230
DecorationHover=61,174,230

[Colors:Tooltip]
ForegroundNormal=35,38,41
ForegroundInactive=127,140,141
BackgroundNormal=49,54,59

[Colors:Complementary]
# Used in logout screen, lock screen — independent from normal plasmoids
ForegroundNormal=239,240,241
BackgroundNormal=35,38,41
```

To create the file: make a color scheme in System Settings → Appearance → Colors, save it, then copy from `~/.local/share/color-schemes/<name>.colors` (omit `[ColorEffects:*]` sections).

---

## plasmarc (optional)

```ini
[Settings]
FallbackTheme=breeze

[BlurBehindEffect]
enabled=true

[ContrastEffect]
enabled=false
contrast=0.3
intensity=1.9
saturation=1.9
```

Contrast/blur tuning tool: https://niccolo.venerandi.com/backstage/files/ownopacity/main.html

---

## Testing workflow

1. Copy theme to `~/.local/share/plasma/desktoptheme/<id>/`
2. Select in System Settings → Appearance → Plasma Style
3. After editing SVGs, clear cache and restart:
   ```bash
   rm -r ~/.cache/plasma*
   plasmashell --replace &
   ```
4. Bump `Version` in `metadata.json` between edits to force cache refresh.
5. Test with compositing off (X11 only): `Alt+Shift+F12` toggles it. Check your `opaque/` folder SVGs.

---

## Inkscape tips

- Set element IDs via **Object → Object Properties** (not the layer name).
- Disable stroke scaling when resizing (Inkscape default scales strokes, causing thin lines in Plasma).
- Embed raster images: **File → Document Properties → Images → Embed All** (linked images don't work in Plasma).
- Use the [KSvg Inkscape extension](https://invent.kde.org/frameworks/ksvg/-/tree/master/src/tools/inkscape%20extensions) to rename element IDs in bulk.

---

## Sanity check for background SVGs

Prevent gap/line artifacts:
- `topleft`, `top`, `topright` → same height
- `topright`, `right`, `bottomright` → same width  
- `bottomleft`, `bottom`, `bottomright` → same height
- `topleft`, `left`, `bottomleft` → same width
