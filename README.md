# Win11-KDE

A complete Windows 11 style theme for KDE Plasma 6. Includes light and dark variants with automatic switching support.

## Components

| Component | Dark | Light |
|---|---|---|
| **Window Decoration** | Willow Dark Blur | Willow Light Blur |
| **Icons** | Win11-KDE (single theme, adapts via color scheme) | ← same |
| **Application Style** | Breeze | Breeze |
| **Plasma Style** | Utterly-Round (transparent + blur, follows color scheme) | ← same |
| **Color Scheme** | Win11 KDE Dark (WillowDarkBlur) | Win11 KDE Light (WillowLightBlur) |
| **Cursors** | WinSur Dark | WinSur White |
| **Splash Screen** | None | None |

## Quick Start

```bash
git clone <this-repo> ~/git/win11-kde
cd ~/git/win11-kde
./install.sh install          # Install assets, apply config, enable auto switching
```

## Commands

```
./install.sh install              # Install all assets + configure KDE
./install.sh restore-panel        # Restore the saved panel layout
./install.sh uninstall            # Remove everything
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

The Win11-KDE icon theme is based on [Windows-Eleven](https://github.com/ArcticLinguistics/Windows-Eleven) by zayronxio, with additional symlinks for complete KDE coverage:

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
