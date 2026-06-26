# Icon Map Requests

Fill a row per icon you want changed. I handle the KDE side (finding the real
icon name, sizes, `-symbolic`, `@2x`, symlinks, deploy, screenshot).

## How it works

1. You add a row to the table below.
2. **"Where I see it"** — plain words. App + the spot in the UI.
   (e.g. "Dolphin sidebar → Recent Files", "System Settings → Mouse icon".)
3. **"Source image"** — absolute path to the picture you want used.
   `.ico`, `.png`, or `.svg` all fine. Bigger is better (256px+).
   Paste the path like before: `/home/oliver/Projects/WindowsIcons/Icons/folders/recent.ico`
4. Leave **"Icon name"** blank — I detect it with `kiconfinder6`. Fill it only if you already know it.
5. **"Light/Dark"** — `same` if one image works for both. If you want a
   different image in dark mode, put the dark file path in **Notes**.

When a batch is ready, tell me and I map + verify them all in one pass.

## Requests

| # | Where I see it | Source image (path) | Icon name (optional) | Light/Dark | Notes |
|---|----------------|---------------------|----------------------|------------|-------|
| 1 | Dolphin sidebar → Recent Files | _currently: WindowsIcons objects/recent.ico (placeholder)_ | document-open-recent | same | want a better one; clock badge looks ok but art is meh |
| 2 | Dolphin sidebar → Recent Locations | _currently: WindowsIcons folders/recent.ico (placeholder)_ | folder-open-recent / folder-recent | same | want a better one |
| 3 | Dolphin right-click → Copy | _(find one)_ | edit-copy | same | reverted to baseline, awaiting replacement |
| 4 | Dolphin right-click → Cut | _(find one)_ | edit-cut | same | reverted |
| 5 | Dolphin right-click → Paste | _(find one)_ | edit-paste / edit-paste-in-place | same | reverted |
| 6 | Dolphin right-click → Delete | _(find one)_ | edit-delete | same | reverted |
| 7 | Dolphin right-click → Move to Trash | _(find one)_ | user-trash | same | reverted |
| 8 | Dolphin → Rename | _(find one)_ | edit-rename | same | reverted |
| 9 | Dolphin toolbar → New / Create New | _(find one)_ | document-new | same | reverted |
| 10 | Dolphin → Properties | _(find one)_ | document-properties | same | reverted |
| 11 | Dolphin → Edit (open in editor) | _(find one)_ | document-edit | same | reverted |
| 12 | Dolphin toolbar → Refresh | _(find one)_ | view-refresh | same | reverted |
| 13 |  |  |  |  |  |
| 14 |  |  |  |  |  |

## What makes a good source image

- **Square** (same width/height). Non-square gets letterboxed.
- **Transparent background** (PNG/ICO/SVG with alpha). Avoid a baked-in color.
- **≥256px** for raster (`.ico`/`.png`). SVG is ideal — stays crisp at every size.
- If it's a multi-size `.ico`, I use the largest embedded image.

## Notes / status

- Source-icon stash so far: `~/Projects/WindowsIcons/Icons/` (objects, folders, …).
- Drop new files anywhere and paste the path — no need to pre-sort them.
- Gotchas + the resolution mechanics are in [MAPPINGS.md](MAPPINGS.md)
  ("Case Study: Recent Files / Recent Locations").
