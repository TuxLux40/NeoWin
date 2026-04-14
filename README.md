# NeoWin

A complete Windows 11 inspired theme for KDE Plasma 6. Includes light and dark variants for automatic day/night switching and a MacOS/Gnome Style panel layout.

## Components

| Component | Dark | Light |
|---|---|---|
| **Window Decoration** | Willow Dark Blur | Willow Light Blur |
| **Icons** | NeoWin (single theme, adapts via color scheme) | ← same |
| **Application Style** | Breeze | Breeze |
| **Plasma Style** | Utterly-Round (transparent + blur, follows color scheme) | ← same |
| **Color Scheme** | NeoWin Dark | NeoWin Light |
| **Cursors** | WinSur Dark | WinSur White |
| **Sound Theme** | Win11 (default), Win10, Win7, WinXP available | ← same |
| **Splash Screen** | None | None |

## Quick Start

```bash
git clone https://github.com/TuxLux40/NeoWin.git ~/git/NeoWin
cd ~/git/NeoWin
./install.sh install          # Install assets, apply config, enable auto switching
```

## Commands

```
./install.sh install              # Install all assets + configure KDE
./install.sh sounds               # List available sound packs
./install.sh sounds win7 Sonata   # Switch to Win7 Sonata sounds
./install.sh restore-panel        # Restore the saved panel layout
./install.sh uninstall            # Remove everything
```

## Sound Packs

Four sound packs are bundled. Win11 is installed by default.

| Pack | Description |
|---|---|
| `win11` | Windows 11 sounds, all 44 freedesktop events mapped |
| `win10` | Windows 10 sounds, 41 freedesktop events mapped |
| `win7` | Windows 7 sounds with 13 sub-schemes: Afternoon, Calligraphy, Characters, Cityscape, Delta, Festival, Garden, Heritage, Landscape, Quirky, Raga, Savanna, Sonata |
| `winxp` | Windows XP sounds, 26 freedesktop events mapped |

Switch sound packs anytime:

```bash
./install.sh sounds win10             # Switch to Win10 sounds
./install.sh sounds win7 Calligraphy  # Switch to Win7 Calligraphy scheme
./install.sh sounds winxp             # Switch to WinXP sounds
```

## Auto Dark/Light Switching

The installer enables KDE's built-in `AutomaticLookAndFeel` feature, which automatically switches between the dark and light variants. You can adjust the schedule in:

**System Settings → Colors & Themes → Behavior**

## Panel Layout

The saved panel layout includes:
- **Top panel**: App launcher (KickerDash with CachyOS icon), Virtual Desktop Pager, App Menu, spacers, Digital Clock, System Tray
- **Bottom panel**: Icon-only Task Manager

The panel layout is saved but **not applied automatically** during install (to avoid overwriting your current setup). Use `./install.sh restore-panel` to apply it, then restart Plasma shell:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Icon Theme Coverage

The NeoWin icon theme is based on [Windows-Eleven](https://github.com/ArcticLinguistics/Windows-Eleven) by zayronxio, with additional symlinks for complete KDE coverage:

- **6,600+ icons** across actions, apps, categories, devices, emblems, mimes, places, status
- All `org.kde.*` app names mapped (Dolphin, Konsole, Kate, Okular, Discover, Spectacle, etc.)
- Flatpak app IDs mapped (Firefox, Thunderbird, LibreOffice, VLC, etc.)
- Full sidebar coverage for Dolphin, Discover, System Settings
- `FollowsColorScheme=true` — symbolic icons automatically adapt to light/dark
- Falls back to Breeze → hicolor for any remaining gaps

## Requirements

- KDE Plasma 6 (Qt 6 / KF6)
- Wayland or X11
- `kwriteconfig6`, `kbuildsycoca6`, `lookandfeeltool` (or `plasma-apply-lookandfeel`), `qdbus6` — all shipped with Plasma 6

The installer automatically falls back to KF5 equivalents (`kwriteconfig5`, `kbuildsycoca5`, `qdbus`) if the KF6 tools are missing, so it also runs on Plasma 5 systems.

## Credits & Sources

NeoWin bundles several third-party theme components. Every source is listed below with its author, upstream URL, and upstream license. All bundled components are free software; none were modified beyond packaging (icon theme adds extra symlinks for app-ID coverage — see below).

| Component | Author | Source | License |
|---|---|---|---|
| **Willow Dark Blur / Dark Blur Alt** (aurorae) | doncsugar | [store.kde.org/p/2134749](https://store.kde.org/p/2134749) | GPL-3.0 |
| **Willow Light Blur / Light Blur Alt** (aurorae) | doncsugar | [store.kde.org/p/2134747](https://store.kde.org/p/2134747) | GPL-3.0 |
| **Utterly-Round** (plasma style) | Himprakash Deka (himdek) | [store.kde.org/p/1901768](https://store.kde.org/p/1901768) · [GitHub](https://github.com/HimDek/Utterly-Round-Plasma-Style) | GPL-2.0-or-later |
| **Windows-Eleven** (icon theme) | zayronXIO | [store.kde.org/p/1977340](https://store.kde.org/p/1977340) · [GitHub](https://github.com/ArcticLinguistics/Windows-Eleven) | AGPL-3.0 |
| **WinSur Dark Cursors** | yeyushengfan258 | [store.kde.org/p/1423341](https://store.kde.org/p/1423341) | GPL-3.0 |
| **WinSur White Cursors** | yeyushengfan258 | [store.kde.org/p/1381566](https://store.kde.org/p/1381566) | GPL-3.0 |
| **Windows 11/10/7/XP sound samples** | Microsoft Corp. | Various sources on the web | See disclaimer below |

### Sound samples disclaimer

The `.wav` files under `sounds/win11-kde/`, `sounds/win10/`, `sounds/win7/`, and `sounds/winxp/` are original Microsoft Windows sound assets, collected from various free download sites on the web. They are bundled here purely for personal, non-commercial use as a nostalgia feature for Linux desktops. No ownership is claimed over these files — Microsoft retains all rights to the audio itself. NeoWin only claims authorship of the *mapping* of those files to freedesktop sound-event names (the `index.theme` files and directory layout), which is covered by the repository license below. If Microsoft or any rights holder objects to their inclusion, open an issue and they will be removed.

## License

**First-party work** in this repository — `install.sh`, the `look-and-feel/neowin-{dark,light}/` packages, the `color-schemes/NeoWin{Dark,Light}.colors` files, the icon-theme app-ID symlinks added on top of Windows-Eleven, the sound-event mappings, `panel-layout/`, and all documentation — is licensed under the **GNU General Public License v3.0 or later** (`SPDX: GPL-3.0-or-later`). See [LICENSE](LICENSE) for the full text.

You are free to use, study, modify, and redistribute NeoWin under the terms of that license. Attribution to the upstream authors listed above is required by their individual licenses and must be preserved in any redistribution.

**Bundled components** retain their upstream licenses as listed in the table above — GPL-3.0, GPL-2.0-or-later, and AGPL-3.0 are all mutually compatible with GPL-3.0-or-later, so the combined repository can be redistributed as a whole under GPL-3.0-or-later. The Windows sound samples are the sole exception — see the disclaimer above.
