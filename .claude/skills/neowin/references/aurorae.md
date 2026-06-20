# Aurorae Window Decoration Reference

Source: `/home/oliver/Projects/develop-kde-org/content/docs/plasma/aurorae/index.md`

---

## Install location

```
~/.local/share/aurorae/themes/<ThemeName>/
```
System themes: `/usr/share/aurorae/themes/`. After copying, select in System Settings → Window Decorations.

---

## Package structure

```
MyDecoration/
├── metadata.desktop          # theme info (name, author, etc.)
├── MyDecorationrc            # layout + style config (name = folder name + "rc")
├── decoration.svg            # window frame (required)
├── close.svg                 # close button
├── maximize.svg              # maximize button
├── minimize.svg              # minimize button
├── restore.svg               # restore (from maximized) button
├── alldesktops.svg           # optional: "show on all desktops" toggle
├── keepabove.svg             # optional
├── keepbelow.svg             # optional
├── shade.svg                 # optional
├── help.svg                  # optional
└── appmenu.svg               # optional (Plasma 6.3+)
```

Folder name, config file base name, and `X-KDE-PluginInfo-Name` in `metadata.desktop` must all match.

---

## metadata.desktop

```ini
[Desktop Entry]
Name=My Decoration
Comment=A custom KWin window decoration
X-KDE-PluginInfo-Name=MyDecoration
X-KDE-PluginInfo-Author=Your Name
X-KDE-PluginInfo-Email=you@example.com
X-KDE-PluginInfo-Website=https://yoursite.example
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=GPL
```

---

## decoration.svg

The window frame is a FrameSvg (9-slice). The minimum required prefix is `decoration`:

```
decoration-topleft   decoration-top    decoration-topright
decoration-left      decoration-center decoration-right
decoration-bottomleft decoration-bottom decoration-bottomright
```

### Additional frame prefixes

| Prefix | When used |
|---|---|
| `decoration-inactive` | Unfocused windows |
| `decoration-maximized` | Maximized windows (only `center` drawn) |
| `decoration-maximized-inactive` | Maximized + unfocused |
| `decoration-opaque` | Active, compositing disabled (X11 only) |
| `decoration-opaque-inactive` | Inactive, compositing disabled |

If a prefix is missing, falls back to the base `decoration` frame.

### Inner borders

Optional frames `innerborder` and `innerborder-inactive` for a border at the margin to the window content. Center element is invisible; only border elements are shown. Not drawn on maximized windows.

### Blur mask

To enable blur behind the decoration, add a `mask` FrameSvg (`mask-topleft`, `mask-top`, etc.) with the same padding as the decoration frames. Without it, blur is disabled.

---

## Button SVGs

Each button file must have at minimum an `active` element (just the `center` is required — borders are not supported for buttons).

### States per button

| Element prefix | When shown |
|---|---|
| `active` | Focused window, normal state |
| `inactive` | Unfocused window |
| `hover` | Mouse over, focused window |
| `hover-inactive` | Mouse over, unfocused window |
| `pressed` | Button being clicked |
| `pressed-inactive` | Button clicked on unfocused window |
| `deactivated` | Button action not available |
| `deactivated-inactive` | Not available + unfocused |

Fallback chain: if `inactive` is missing, active is used for all inactive states. If only `active` and `hover` exist, inactive windows show `active` for normal/press/deactivated and have no hover effect.

### Toggle buttons

`alldesktops`, `keepabove`, `keepbelow`, `shade` stay in `pressed(-inactive)` state when toggled on.

---

## MyDecorationrc (configuration file)

### [General] section

```ini
[General]
TitleAlignment=Center          # Left | Center | Right
TitleVerticalAlignment=Center  # Top | Center | Bottom
Animation=0                    # hover/active change animation in ms
ActiveTextColor=0,0,0,255      # RGBA
InactiveTextColor=128,128,128,255
UseTextShadow=false
ActiveTextShadowColor=255,255,255,255
InactiveTextShadowColor=255,255,255,255
TextShadowOffsetX=0
TextShadowOffsetY=0
HaloActive=false
HaloInactive=false
LeftButtons=MS                 # M=menu, S=alldesktops
RightButtons=HIAX              # H=help, I=minimize, A=maximize, X=close
Shadow=true
DecorationPosition=0           # 0=top, 1=left, 2=right, 3=bottom
```

Button letter codes: `X`=close, `I`=minimize, `A`=maximize, `S`=alldesktops, `F`=keepabove, `B`=keepbelow, `L`=shade, `H`=help, `M`=menu, `N`=appmenu.

### [Layout] section

```ini
[Layout]
BorderLeft=5
BorderRight=5
BorderBottom=5
BorderTop=0
TitleEdgeTop=5
TitleEdgeBottom=5
TitleEdgeLeft=5
TitleEdgeRight=5
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=0
TitleEdgeRightMaximized=0
TitleBorderLeft=5
TitleBorderRight=5
TitleHeight=20
ButtonWidth=20
ButtonWidthClose=20            # per-button overrides (optional)
ButtonWidthMaximizeRestore=20
ButtonWidthMinimize=20
ButtonHeight=20
ButtonSpacing=5
ButtonMarginTop=0
ExplicitButtonSpacer=10
PaddingTop=0                   # shadow padding; required if Shadow=true
PaddingBottom=0
PaddingLeft=0
PaddingRight=0
```

Layout diagram:
```
 _______________________________________________________________
|               PaddingTop                                      |
|  _________________________________________________________  |
| |          TitleEdgeTop                                   | |
| |TitleEdgeLeft  [Buttons] [title] [Buttons]  TitleEdgeRight| |
| |          TitleEdgeBottom                                | |
| |BorderLeft                              BorderRight      | |
| |          BorderBottom                                   | |
|               PaddingBottom                               | |
|_______________________________________________________________|
```

---

## Publishing

Zip the theme folder and upload to [KDE Store](https://store.kde.org/browse/) → Linux/Unix Desktops → Desktop Themes → KDE Plasma → Plasma Window Decorations.
