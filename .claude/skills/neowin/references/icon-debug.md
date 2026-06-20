# KDE Icon Debugging Reference

When an icon shows wrong or uses a breeze/hicolor fallback, the root cause is almost always one of:
1. Wrong name — the app is requesting a different string than you think
2. Wrong context — the file exists but in the wrong `Context=` directory for that size
3. Missing size — the icon exists at 48px but the app requests 16px and no 16px entry covers it
4. Broken symlink — the symlink exists in the declared directory but points to a missing target
5. Stale cache — `kbuildsycoca6` hasn't been re-run after the change

Work through these in order.

---

## Step 1 — Find the actual icon name requested

Never guess. Use one of these:

### kiconfinder6 (fast, installed-theme lookup)
```bash
kiconfinder6 <name>          # returns which file "wins" right now
kiconfinder6 --size 16 <name>   # with size hint (if flag supported)
```
If it returns a Breeze or hicolor path, the name is either wrong or the size/context is missing.

### Qt icon logging (find names live from a running app)
```bash
QT_LOGGING_RULES="kf.iconthemes.debug=true" dolphin 2>&1 | grep -i "<keyword>"
```
Replace `dolphin` with the problem app. This dumps every icon load request to stderr.
The output lines look like: `Looking for icon: "folder-recent" size 16`.

### Static analysis (grep compiled binaries or QML sources)
```bash
# For KIO workers
strings /usr/lib/qt6/plugins/kf6/kio/<worker>.so | grep icon

# For QML-based applets
grep -r "icon.name\|iconName\|QIcon::fromTheme" /usr/share/plasma/plasmoids/<id>/

# For C++ apps
strings /usr/bin/<app> | grep -E "^[a-z][a-z-]*$" | grep -E "icon|folder|document"
```

### user-places.xbel (for Dolphin/file-picker sidebar entries)
```bash
cat ~/.local/share/user-places.xbel | grep -B2 -A4 -i "icon"
```
The `<bookmark:icon name="..."/>` value is the exact name the Places sidebar uses.

---

## Step 2 — Check current resolution

```bash
kiconfinder6 <name>
```

Read the path returned:
- `~/.local/share/icons/NeoWin/status/22/<name>.svg` → NeoWin, status, 22px ✓
- `~/.local/share/icons/NeoWin/apps/scalable/<name>.svg` → NeoWin, wrong context (app icon used for status)
- `/usr/share/icons/breeze/<context>/<size>/<name>.svg` → breeze fallback — NeoWin doesn't have it
- `/usr/share/icons/hicolor/...` → last-resort fallback — nothing in theme covers it

If it returns the wrong context (e.g., `apps/scalable/` for a systray icon), check if a proper `status/` entry exists and add a symlink.

---

## Step 3 — Diagnose the context/size gap

### Context directories and what they serve

| Context | Directory | Sizes | Serves |
|---|---|---|---|
| Status/systray | `status/` + `status/symbolic/` | 16–24 + symbolic | Systray applets, power/network/audio indicators |
| Places | `places/` + `places/symbolic/` | 16–48 + symbolic | Dolphin sidebar, file picker side panel |
| Actions | `actions/` + `actions/symbolic/` | 16–24 + symbolic | Context menus, toolbars, buttons |
| Apps | `apps/scalable/` + `apps/symbolic/` | scalable | App icons, System Settings sidebar |
| Categories | `categories/` | 32 + symbolic | Discover category sidebar |
| Devices | `devices/` | 16–48 + symbolic | Storage, input devices |
| Mimetypes | `mimetypes/` | 16–48 + symbolic | File type icons |

**Plasma 6 rule**: for systray items, the applet always requests the `-symbolic` suffix and Plasma forces monochrome tinting. A non-symbolic icon in `status/` is NOT used for systray.

### Size coverage gaps

Check the `index.theme` declarations for the directory in question:
```bash
grep -A4 "\[status/symbolic\]" ~/.local/share/icons/NeoWin/index.theme
```

A `Type=Fixed, Size=16` entry only matches exactly 16px. If the app requests 22px and no Fixed 22px entry exists, and there's a `Type=Scalable, MinSize=22` entry elsewhere, the scalable one wins.

A `Type=Scalable, MinSize=22` entry will NOT serve 16px requests — anything below MinSize has a size-distance penalty. If the only entry for an icon is at 48/Scalable/MinSize=22 and the app requests 16px, the loader skips it and falls to the inheritance chain (Breeze).

**To cover 16px**: add the icon to a `Type=Fixed, Size=16` or `Type=Scalable, MinSize=16` directory.

---

## Step 4 — Fix the gap

### Pattern A: Add a symlink in the missing size directory
```bash
cd icons/win11-kde/status/16
ln -s ../22/some-icon.svg some-icon.svg   # relative symlink
```

### Pattern B: Add a symlink from the wrong context to the right one
```bash
# If battery-critical is landing in apps/scalable but should be in status/
cd icons/win11-kde/status/24
ln -s battery-caution.svg battery-critical.svg
```

### Pattern C: New icon name variant (e.g., missing -symbolic)
If the app requests `foo-symbolic` but only `foo.svg` exists:
```bash
cd icons/win11-kde/status/symbolic
ln -s ../22/foo.svg foo-symbolic.svg   # only valid if the SVG has ColorScheme-Text class
```
A symbolic icon MUST use `class="ColorScheme-Text" style="fill:currentColor"` internally, or it won't tint correctly. Never symlink a colored icon as a symbolic — the shape will show but the color will be wrong (hardcoded).

---

## Step 5 — Verify and apply

```bash
# 1. Confirm the symlink resolves
readlink -f icons/win11-kde/status/16/new-icon.svg

# 2. Install
rsync -a --delete icons/win11-kde/ ~/.local/share/icons/NeoWin/
kbuildsycoca6 --noincremental

# 3. Check resolution
kiconfinder6 new-icon

# 4. Restart the affected app (icons are often cached per-process)
```

---

## Known upstream behaviors (not fixable via icon theme)

### Systray icons are always monochrome
Plasma 6 requests `*-symbolic` names for all systray applets and forces `ColorScheme-Text` tinting. You can ship Win11-shaped symbolic SVGs in `status/symbolic/` — they will show the Win11 shape in monochrome. Colored systray icons are not possible without patching Plasma applet QML.

### Application Dashboard / power menu dark in light mode
The fullscreen app launcher (`org.kde.plasma.kickerdash`, which is `org.kde.plasma.kicker` in fullscreen mode) and the power/leave menu both inherit `colorSet: Kirigami.Theme.Complementary` from the panel containment. NeoWin's `[Colors:Complementary]` is intentionally dark in both light and dark modes (required for the panel and lock screen). Result: both popups always have a dark background. **Upstream fix required.** Workaround: none without patching applet QML or separating Complementary from panel containment colors.

### Dolphin sidebar icons not updating after changes
After adding icon symlinks and running `kbuildsycoca6`, the Dolphin process must be fully restarted — it caches icon handles per session. KDE's icon loader doesn't hot-reload per-process icon caches.

---

## Quick reference — common problem icon names

| What shows wrong | Likely names to check |
|---|---|
| Systray battery | `battery-level-N-symbolic` (N=0,10..100), `battery-level-N-charging-symbolic`, `battery-caution-symbolic` |
| Systray network | `network-wired-symbolic`, `network-wireless-connected-N-symbolic`, `network-offline-symbolic` |
| Systray volume | `audio-volume-high-symbolic`, `-medium-`, `-low-`, `-muted-symbolic` |
| Systray bluetooth | `bluetooth-active-symbolic`, `bluetooth-disabled-symbolic` |
| Systray brightness | `display-brightness-symbolic` |
| Systray notifications | `notification-symbolic` |
| Systray clipboard | `klipper-symbolic` |
| Dolphin "Recent Files" | `document-open-recent` (Places sidebar at 16px) |
| Dolphin "Recent Locations" | `folder-open-recent` (Places sidebar at 16px) |
| Trash in systray/sidebar | `user-trash-symbolic`, `user-trash-full-symbolic` |
| App launcher icon | `start-here-kde` or the `.desktop` Icon= field |
