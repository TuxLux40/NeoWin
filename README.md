# NeoWin

A complete Windows 11 style theme for KDE Plasma 6. Includes light and dark variants with automatic switching support.

## Components

| Component | Dark | Light |
|---|---|---|
| **Window Decoration** | Willow Dark Blur | Willow Light Blur |
| **Icons** | NeoWin (single theme, adapts via color scheme) | ← same |
| **Application Style** | Breeze | Breeze |
| **Plasma Style** | Utterly-Round (transparent + blur, follows color scheme) | ← same |
| **Color Scheme** | WillowDarkBlur | WillowLightBlur |
| **Cursors** | WinSur Dark | WinSur White |
| **Sound Theme** | Win11 (default), Win10, Win7, WinXP available | ← same |
| **Splash Screen** | None | None |

## Quick Start

```bash
git clone <this-repo> ~/git/NeoWin
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

- KDE Plasma 6
- Wayland or X11
- `kwriteconfig6` and `lookandfeeltool` (included with Plasma)

## Credits

- **Willow window decorations**: [Willow theme](https://github.com/pchannr/willow-aurorae)
- **Windows-Eleven icons**: [zayronxio](https://github.com/ArcticLinguistics/Windows-Eleven)
- **Utterly-Round plasma theme**: [HimDek](https://github.com/HimDek/Utterly-Round-Plasma-Style)
- **WinSur cursors**: WinSur cursor theme project

## License

Individual components retain their original licenses. See each component directory for details.
