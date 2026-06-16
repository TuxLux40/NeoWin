# NeoWin Icon Mappings, Sources & Maintenance Guide

This document complements the Icon Architecture section in CLAUDE.md. It provides practical, non-vibe guidance for discovering icon names, adding mappings, auditing coverage, and avoiding the accumulation of ad-hoc chaos.

## Quick Start: Adding a Mapping (Symlink or New Icon)

1. **Discover the exact name(s) an app requests** (do not guess):
   - `kiconfinder6 document-open-recent` (shows which file/theme currently wins).
   - Install `plasma-sdk` and launch the **Icon Explorer** tool — browse Breeze by category to see real names used by Plasma/apps.
   - Runtime: `QT_LOGGING_RULES="kf.icon.*=true" dolphin` (or the target app) and trigger the UI element.
   - Static analysis: `strings /usr/lib/qt6/plugins/kf6/kio/recentlyused.so | grep -i recent` or similar on Dolphin/KIO binaries.
   - Source grep in KDE frameworks if you have them checked out.

2. **Decide on canonical location** (see contexts in `index.theme` and CLAUDE.md table):
   - Sidebar / Places panel → `places/`
   - Context menus, toolbars, actions → `actions/`
   - App launcher / taskbar / System Settings prefs → `apps/scalable/` (or `apps/symbolic/`)
   - Categories (Discover sidebar) → `categories/`
   - Always consider both the regular name **and** the `-symbolic` variant (Plasma 6 strongly prefers `-symbolic` for panels, menus, systray, etc.).

3. **Add the mapping** (preferred method):
   - Create a symlink in the appropriate size directories:
     ```bash
     cd icons/win11-kde/actions/16
     ln -s existing-good-win11-icon.svg edit-cut.svg
     # Repeat for 22, 24, symbolic, @2x variants as needed
     ```
   - For brand-new icons without a close match in the pack: add a proper Win11-style `.svg` (match the visual language, gradients, and FollowsColorScheme `.ColorScheme-Text` usage from existing files).

4. **Test immediately**:
   - `kiconfinder6 edit-cut`
   - `./install.sh install` (or the icon copy step) + `kbuildsycoca6 --noincremental`
   - Open the affected app and visually confirm (light + dark mode, symbolic contexts, HiDPI).

5. **Commit** the symlink(s) + update this file and CLAUDE.md if the gap was significant.

## Plasma 6 Symbolic Icons (Important)

Since Plasma 6, apps and Plasma itself often request `foo-symbolic` to get a monochrome version even at larger sizes. If your theme has mixed styles at different sizes, you **must** provide `-symbolic` versions (or symlinks pointing to your symbolic SVGs).

See: https://pointieststick.com/2023/08/12/how-all-this-icon-stuff-is-going-to-work-in-plasma-6/

## Priority Icon Name Lists (High-Impact Areas)

### Recent Files / History / Recently Used (KIO recentlyused, Dolphin sidebar, file pickers)
- `document-open-recent`
- `folder-open-recent`
- `folder-recent`
- `view-history`
- `edit-clear-history`
- `edit-undo-history`
- `recentdocuments` / protocol-specific variants

**Audit findings (June 2026 execution)**:
- Primary names (`document-open-recent`, `folder-open-recent`, `folder-recent`, `view-history`, `edit-clear-history`) all currently resolve to NeoWin.
- Significant duplication exists: the same recent icons are present (as real files or symlinks) in both `actions/` (mainly 16/22/24 + symbolic) **and** `places/` (including 48px and many @2x variants). This is the most likely root of the "works in file picker, not in Dolphin sidebar" symptom.
- Extra variant names used by the KIO recentlyused worker and Dolphin ("Recent Files", "Recent Locations", "recentdocuments", etc.) are not present as direct files — they rely on fallback/chopping rules.
- **Changes made in this session** (first concrete improvements):
  - Added symlinks in `places/` and `actions/` (plus symbolic variants):
    - `recentdocuments` → `document-open-recent`
    - `recentfiles` → `document-open-recent`
    - `recentlocations` → `folder-recent` (places) / `folder-open-recent` (actions)
  - These follow the exact same minimal symlink pattern used in previous successful fixes (e.g. 955a3f1d).
- Recommendation (still valid): Choose a canonical home (probably `places/` for the larger "Recent" sidebar use-case + good colored versions), then use symlinks from `actions/` where needed. Remove or replace lower-quality duplicates in a follow-up cleanup pass.

### Status / Systray Icons (battery, weather)

**Audit findings (June 2026)**:
- `battery-critical` and `battery-charging` were missing from `status/` entirely and fell back to `apps/scalable/battery.svg`. Fixed:
  - `battery-critical` → `battery-caution` (sizes 16, 22, 24)
  - `battery-charging` → `battery-full-charging` (sizes 16, 22, 24)
- Weather icons missing from `status/` and falling back to `apps/scalable/weather.svg`. Fixed:
  - `weather-partly-cloudy` → `weather-many-clouds` (sizes 16, 22)
  - `weather-thunderstorm` → `weather-storm` (sizes 16, 22)
  - `weather-thunderstorm-night` → `weather-storm-night` (sizes 16, 22)
  - `weather-tornado` → `weather-storm` (sizes 16, 22; no dedicated tornado icon exists)
  - `weather-hurricane` → `weather-storm` (sizes 16, 22; no dedicated hurricane icon exists)
- Note: Plasma 6 systray shows `-symbolic` variants (monochrome tinted). The above fixes the colored icon names used by Plasma's battery widget in non-systray contexts and by some third-party apps.

### Core Context Menu & Action Icons (most visible inconsistency)
Standard freedesktop + heavy KDE usage:
- `edit-cut`, `edit-copy`, `edit-paste`, `edit-delete`, `edit-rename`
- `document-properties`, `document-new`, `document-open`, `document-save`
- `folder-new`, `go-up`, `go-home`, `go-previous`, `go-next`
- `preferences-system`, `preferences-desktop-*`
- `application-exit`, `help-contents`, `view-refresh`
- Common extensions: `overflow-menu`, `sidebar-show/hide`, `tab-new`, `window-close`, `zoom-in/out`

Many of these should live primarily in `actions/` (all sizes + symbolic).

### Other High-Value Areas
- App launchers & `.desktop` Icon= values (especially `org.kde.*` modern names + legacy short names)
- Discover categories (`applications-*`)
- System Settings sidebar (mostly covered via `apps/scalable` MinSize passthrough — do **not** add a `preferences/` context)
- KIO / file dialog specific (recent, places, mime types)

## Duplication & Cleanup Policy

- The base Windows-Eleven pack already contains a very large number of symlinks (~19k observed).
- **Do not** mass-copy the same SVG into multiple contexts just "to be sure".
- Use symlinks for cross-context needs.
- When you discover a duplicate (same visual in `actions/16/foo.svg` and `places/16/foo.svg`), decide on a canonical home and replace the copy with a symlink where possible.
- Recent ad-hoc additions (2026-05 era) were mostly small targeted symlinks — this is the correct pattern going forward.

## Recommended Sources & Databases

See the expanded section in CLAUDE.md (Icon Architecture → Sources & Databases). Key ones:

- freedesktop Icon Naming Spec: https://specifications.freedesktop.org/icon-naming-spec/latest/
- KDE docs: https://develop.kde.org/docs/features/additional-features/icons/ and HIG icons page.
- Plasma 6 icon changes: https://pointieststick.com/2023/08/12/how-all-this-icon-stuff-is-going-to-work-in-plasma-6/
- Reference names: Breeze icons (via `plasma-sdk` Icon Explorer or https://invent.kde.org/plasma/breeze-icons)
- Upstream base for this theme: https://github.com/zayronxio/windows-eleven-skin (icons/ subdirectory)
- Runtime tools on your machine: `kiconfinder6`, Icon Explorer (plasma-sdk), `strings` on KIO/Dolphin plugins, QT logging.

## Maintenance Tips

- Every time you add mappings, run a quick audit with `kiconfinder6` on the affected names before and after `./install.sh`.
- When Plasma or apps add new icon requests, they usually fall back gracefully (name chopping), but symbolic variants often need explicit help.
- Keep this file and the CLAUDE.md section in sync.
- If a mapping requires a brand-new SVG (not just a symlink), note the source/adaptation in the commit and here.

This process replaces previous "vibe" additions with a repeatable, auditable workflow.

Last updated: following the approved icon mapping plan (2026).