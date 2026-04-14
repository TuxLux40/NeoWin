<div align="center">

# NeoWin

**A complete Windows 11 inspired theme for KDE Plasma 6.**

Light and dark variants for automatic day/night switching, plus a MacOS/Gnome style panel layout.

[![License: GPL v3+](https://img.shields.io/badge/License-GPLv3+-blue.svg)](LICENSE)
[![KDE Plasma 6](https://img.shields.io/badge/KDE-Plasma%206-1d99f3.svg)](https://kde.org/plasma-desktop/)
[![Qt 6](https://img.shields.io/badge/Qt-6-41cd52.svg)](https://www.qt.io/)
[![Wayland & X11](https://img.shields.io/badge/session-Wayland%20%7C%20X11-lightgrey.svg)](#requirements)

[Quick Start](#quick-start) · [Components](#components) · [Sound Packs](#sound-packs) · [License](#license)

</div>

---

## Components

All bundled components are free software; none were modified beyond packaging (the icon theme adds extra app-ID symlinks for full KDE coverage — see [Icon Theme Coverage](#icon-theme-coverage)).

| Component | Dark | Light | Author | Source | License |
|---|---|---|---|---|---|
| **Window Decoration** | Willow Dark Blur | Willow Light Blur | doncsugar | [2134749](https://store.kde.org/p/2134749) · [2134747](https://store.kde.org/p/2134747) | GPL-3.0 |
| **Icons** | NeoWin (adapts via color scheme) | ← same | zayronXIO | [1977340](https://store.kde.org/p/1977340) · [GitHub](https://github.com/ArcticLinguistics/Windows-Eleven) | AGPL-3.0 |
| **Application Style** | Breeze | Breeze | KDE | shipped with Plasma | LGPL-2.0+ |
| **Plasma Style** | Utterly-Round (transparent + blur, follows color scheme) | ← same | himdek (Himprakash Deka) | [1901768](https://store.kde.org/p/1901768) · [GitHub](https://github.com/HimDek/Utterly-Round-Plasma-Style) | GPL-2.0-or-later |
| **Color Scheme** | NeoWin Dark | NeoWin Light | TuxLux40 | this repo | GPL-3.0-or-later |
| **Cursors** | WinSur Dark | WinSur White | yeyushengfan258 | [1423341](https://store.kde.org/p/1423341) · [1381566](https://store.kde.org/p/1381566) | GPL-3.0 |
| **Sound Theme** | Win11 (default), Win10, Win7, WinXP available | ← same | Microsoft Corp. | various free download sites | see [disclaimer](#sound-samples-disclaimer) |
| **Splash Screen** | None | None | — | — | — |

---

## Quick Start

```bash
git clone https://github.com/TuxLux40/NeoWin.git ~/git/NeoWin
cd ~/git/NeoWin
./install.sh install          # Install assets, apply config, enable auto switching
```

> [!TIP]
> After install, tweak the dark/light schedule in **System Settings → Colors & Themes → Behavior**.

---

## Commands

```
./install.sh install              # Install all assets + configure KDE
./install.sh sounds               # List available sound packs
./install.sh sounds win7 Sonata   # Switch to Win7 Sonata sounds
./install.sh restore-panel        # Restore the saved panel layout
./install.sh uninstall            # Remove everything
```

---

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

---

## Auto Dark/Light Switching

The installer enables KDE's built-in `AutomaticLookAndFeel` feature, which automatically switches between the dark and light variants. You can adjust the schedule in:

> **System Settings → Colors & Themes → Behavior**

---

## Panel Layout

The saved panel layout includes:
- **Top panel**: App launcher (KickerDash with CachyOS icon), Virtual Desktop Pager, App Menu, spacers, Digital Clock, System Tray
- **Bottom panel**: Icon-only Task Manager

> [!NOTE]
> The panel layout is saved but **not applied automatically** during install to avoid overwriting your current setup. Run `./install.sh restore-panel` to apply it, then restart Plasma shell:
>
> ```bash
> kquitapp6 plasmashell && kstart plasmashell
> ```

---

## Icon Theme Coverage

The NeoWin icon theme is based on [Windows-Eleven](https://github.com/ArcticLinguistics/Windows-Eleven) by zayronxio, with additional symlinks for complete KDE coverage:

- **6,600+ icons** across actions, apps, categories, devices, emblems, mimes, places, status
- All `org.kde.*` app names mapped (Dolphin, Konsole, Kate, Okular, Discover, Spectacle, etc.)
- Flatpak app IDs mapped (Firefox, Thunderbird, LibreOffice, VLC, etc.)
- Full sidebar coverage for Dolphin, Discover, System Settings
- `FollowsColorScheme=true` — symbolic icons automatically adapt to light/dark
- Falls back to Breeze → hicolor for any remaining gaps

---

## Requirements

| Requirement | Notes |
|---|---|
| **Desktop** | KDE Plasma 6 (Qt 6 / KF6) |
| **Session** | Wayland or X11 |
| **Tools** | `kwriteconfig6`, `kbuildsycoca6`, `lookandfeeltool` (or `plasma-apply-lookandfeel`), `qdbus6` — all shipped with Plasma 6 |

The installer automatically falls back to KF5 equivalents (`kwriteconfig5`, `kbuildsycoca5`, `qdbus`) if the KF6 tools are missing, so it also runs on Plasma 5 systems.

---

## License

**First-party work** in this repository — `install.sh`, the `look-and-feel/neowin-{dark,light}/` packages, the `color-schemes/NeoWin{Dark,Light}.colors` files, the icon-theme app-ID symlinks added on top of Windows-Eleven, the sound-event mappings, `panel-layout/`, and all documentation — is licensed under the **GNU General Public License v3.0 or later** (`SPDX: GPL-3.0-or-later`). See [LICENSE](LICENSE) for the full text.

You are free to use, study, modify, and redistribute NeoWin under the terms of that license. Attribution to the upstream authors listed in the Components table is required by their individual licenses and must be preserved in any redistribution.

**Bundled components** retain their upstream licenses as listed in the Components table — GPL-3.0, GPL-2.0-or-later, LGPL-2.0+, and AGPL-3.0 are all mutually compatible with GPL-3.0-or-later, so the combined repository can be redistributed as a whole under GPL-3.0-or-later.

### Sound samples disclaimer

> [!IMPORTANT]
> The `.wav` files under `sounds/win11-kde/`, `sounds/win10/`, `sounds/win7/`, and `sounds/winxp/` are original Microsoft Windows sound assets, collected from various free download sites on the web. They are bundled here purely for personal, non-commercial use as a nostalgia feature for Linux desktops. No ownership is claimed over these files — Microsoft retains all rights to the audio itself. NeoWin only claims authorship of the *mapping* of those files to freedesktop sound-event names (the `index.theme` files and directory layout), which is covered by the repository license above. If Microsoft or any rights holder objects to their inclusion, open an issue and they will be removed.
