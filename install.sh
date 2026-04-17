#!/usr/bin/env bash
# NeoWin: Windows 11 style KDE Plasma theme installer
# Uses KDE's built-in AutomaticLookAndFeel for dark/light switching
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG directories
ICON_DIR="${HOME}/.local/share/icons"
AURORAE_DIR="${HOME}/.local/share/aurorae/themes"
PLASMA_THEME_DIR="${HOME}/.local/share/plasma/desktoptheme"
COLOR_DIR="${HOME}/.local/share/color-schemes"
LAF_DIR="${HOME}/.local/share/plasma/look-and-feel"
CURSOR_DIR="${HOME}/.local/share/icons"
SOUND_DIR="${HOME}/.local/share/sounds"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect kwriteconfig version
find_kwriteconfig() {
    if command -v kwriteconfig6 &>/dev/null; then
        echo "kwriteconfig6"
    elif command -v kwriteconfig5 &>/dev/null; then
        echo "kwriteconfig5"
    else
        echo ""
    fi
}

install_assets() {
    info "Installing NeoWin theme assets..."

    # Icons
    info "Installing icon theme..."
    mkdir -p "${ICON_DIR}"
    rm -rf "${ICON_DIR}/NeoWin"
    cp -a "${SCRIPT_DIR}/icons/win11-kde" "${ICON_DIR}/NeoWin"
    ok "Icon theme installed"

    # Aurorae window decorations
    info "Installing Willow Blur window decorations..."
    mkdir -p "${AURORAE_DIR}"
    for theme in WillowDarkBlur WillowDarkBlurAlt WillowLightBlur WillowLightBlurAlt; do
        rm -rf "${AURORAE_DIR}/${theme}"
        cp -a "${SCRIPT_DIR}/aurorae/${theme}" "${AURORAE_DIR}/${theme}"
    done
    ok "Window decorations installed"

    # Cursors
    info "Installing WinSur cursor themes..."
    for cursor in WinSur-dark-cursors WinSur-white-cursors; do
        rm -rf "${CURSOR_DIR}/${cursor}"
        cp -a "${SCRIPT_DIR}/cursors/${cursor}" "${CURSOR_DIR}/${cursor}"
    done
    ok "Cursor themes installed"

    # Plasma desktop theme
    info "Installing Utterly-Round plasma theme..."
    mkdir -p "${PLASMA_THEME_DIR}"
    rm -rf "${PLASMA_THEME_DIR}/Utterly-Round"
    cp -a "${SCRIPT_DIR}/plasma-theme/Utterly-Round" "${PLASMA_THEME_DIR}/Utterly-Round"
    ok "Plasma theme installed"

    # Color schemes
    info "Installing color schemes..."
    mkdir -p "${COLOR_DIR}"
    cp -f "${SCRIPT_DIR}/color-schemes/NeoWinDark.colors" "${COLOR_DIR}/"
    cp -f "${SCRIPT_DIR}/color-schemes/NeoWinLight.colors" "${COLOR_DIR}/"
    ok "Color schemes installed"

    # Look-and-feel packages
    info "Installing look-and-feel packages..."
    mkdir -p "${LAF_DIR}"
    rm -rf "${LAF_DIR}/neowin-dark" "${LAF_DIR}/neowin-light"
    cp -a "${SCRIPT_DIR}/look-and-feel/neowin-dark" "${LAF_DIR}/"
    cp -a "${SCRIPT_DIR}/look-and-feel/neowin-light" "${LAF_DIR}/"
    ok "Look-and-feel packages installed"

    # Sound theme (default: win11)
    info "Installing sound themes..."
    mkdir -p "${SOUND_DIR}"
    rm -rf "${SOUND_DIR}/neowin"
    cp -a "${SCRIPT_DIR}/sounds/win11-kde" "${SOUND_DIR}/neowin"
    ok "Win11 sound theme installed as default"

    # Refresh icon cache
    info "Refreshing KDE caches..."
    if command -v kbuildsycoca6 &>/dev/null; then
        kbuildsycoca6 --noincremental 2>/dev/null || true
    elif command -v kbuildsycoca5 &>/dev/null; then
        kbuildsycoca5 --noincremental 2>/dev/null || true
    fi
    ok "Caches refreshed"

    echo ""
    ok "All assets installed successfully!"
}

apply_config() {
    info "Applying NeoWin configuration..."

    local kw
    kw="$(find_kwriteconfig)"
    if [ -z "$kw" ]; then
        error "kwriteconfig not found — cannot apply settings"
        return 1
    fi

    # Apply dark look-and-feel as the active theme
    if command -v lookandfeeltool &>/dev/null; then
        lookandfeeltool --apply neowin-dark 2>/dev/null || true
    elif command -v plasma-apply-lookandfeel &>/dev/null; then
        plasma-apply-lookandfeel --apply neowin-dark 2>/dev/null || true
    fi

    # Enable KDE's built-in automatic dark/light switching
    $kw --file kdeglobals --group KDE --key AutomaticLookAndFeel --type bool true
    $kw --file kdeglobals --group KDE --key DefaultDarkLookAndFeel neowin-dark
    $kw --file kdeglobals --group KDE --key DefaultLightLookAndFeel neowin-light

    # Icon theme (shared between light and dark)
    $kw --file kdeglobals --group Icons --key Theme "NeoWin"
    # Widget style
    $kw --file kdeglobals --group KDE --key widgetStyle "Breeze"
    # Window decoration (dark default — KDE switches this with the look-and-feel)
    $kw --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae.v2"
    $kw --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__WillowDarkBlur"
    $kw --file kwinrc --group org.kde.kdecoration2 --key BorderSize "NoSides"
    $kw --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto "false"
    $kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "M"
    # Plasma theme
    $kw --file plasmarc --group Theme --key name "Utterly-Round"
    # Splash screen: none
    $kw --file ksplashrc --group KSplash --key Engine "none"
    $kw --file ksplashrc --group KSplash --key Theme "None"
    # Task switcher (Alt+Tab): cover switch
    $kw --file kwinrc --group TabBox --key LayoutName "coverswitch"
    # Blur
    $kw --file kwinrc --group Plugins --key blurEnabled --type bool true
    $kw --file kwinrc --group Effect-blur --key BlurStrength "13"
    # Night Color
    $kw --file kwinrc --group NightColor --key Active --type bool true
    # Sound theme
    $kw --file kdeglobals --group Sounds --key Theme "neowin"

    # Notify KWin to reload
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus &>/dev/null; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi

    ok "Configuration applied"
    ok "Automatic dark/light switching enabled via KDE settings"
    info "KDE will switch between neowin-dark and neowin-light automatically"
    info "Adjust the schedule in System Settings → Colors & Themes → Behavior"
}

restore_panel() {
    info "Restoring panel layout..."
    local target="${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"

    if [ -f "${SCRIPT_DIR}/panel-layout/plasma-org.kde.plasma.desktop-appletsrc" ]; then
        cp -f "${SCRIPT_DIR}/panel-layout/plasma-org.kde.plasma.desktop-appletsrc" "$target"
        ok "Panel layout restored (restart Plasma shell to apply: kquitapp6 plasmashell && kstart plasmashell)"
    else
        warn "Panel layout file not found"
    fi
}

wallpaper() {
    local provider="${1:-bing}"
    local qd=""
    if command -v qdbus6 &>/dev/null; then
        qd="qdbus6"
    elif command -v qdbus &>/dev/null; then
        qd="qdbus"
    else
        error "qdbus not found — cannot talk to plasmashell"
        return 1
    fi

    info "Setting wallpaper to Picture of the Day (provider: ${provider})..."
    $qd org.kde.plasmashell /PlasmaShell evaluateScript "
        var allDesktops = desktops();
        for (i = 0; i < allDesktops.length; i++) {
            d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.potd';
            d.currentConfigGroup = ['Wallpaper', 'org.kde.potd', 'General'];
            d.writeConfig('Provider', '${provider}');
            d.reloadConfig();
        }
    " 2>/dev/null || { error "plasmashell script failed — is Plasma running?"; return 1; }
    ok "Wallpaper set to ${provider} POTD on all desktops"
}

sounds() {
    local pack="${1:-}"

    if [ -z "$pack" ]; then
        echo "Available sound packs:"
        echo ""
        echo "  win11    Windows 11 sounds (default)"
        echo "  win10    Windows 10 sounds"
        echo "  win7     Windows 7 sounds (13 sub-schemes: Afternoon, Calligraphy, ...)"
        echo "  winxp    Windows XP sounds"
        echo ""
        echo "Usage: $(basename "$0") sounds <pack> [scheme]"
        echo ""
        echo "Examples:"
        echo "  $(basename "$0") sounds win11"
        echo "  $(basename "$0") sounds win7 Sonata"
        echo ""
        if [ -d "${SCRIPT_DIR}/sounds/win7" ]; then
            echo "Win7 schemes: $(ls -d "${SCRIPT_DIR}/sounds/win7"/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ', ' | sed 's/,$//')"
        fi
        return
    fi

    local src=""
    case "$pack" in
        win11)
            src="${SCRIPT_DIR}/sounds/win11-kde"
            ;;
        win10)
            src="${SCRIPT_DIR}/sounds/win10"
            ;;
        win7)
            local scheme="${2:-Sonata}"
            src="${SCRIPT_DIR}/sounds/win7/${scheme}"
            if [ ! -d "$src" ]; then
                error "Win7 scheme '${scheme}' not found"
                echo "Available: $(ls -d "${SCRIPT_DIR}/sounds/win7"/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ', ' | sed 's/,$//')"
                return 1
            fi
            ;;
        winxp)
            src="${SCRIPT_DIR}/sounds/winxp"
            ;;
        *)
            error "Unknown sound pack: $pack"
            return 1
            ;;
    esac

    info "Installing ${pack} sound pack..."
    rm -rf "${SOUND_DIR}/neowin"
    mkdir -p "${SOUND_DIR}/neowin/stereo"

    cp -a "${src}/index.theme" "${SOUND_DIR}/neowin/"
    cp -a "${src}/stereo" "${SOUND_DIR}/neowin/"
    # Override the theme name so KDE always sees "neowin"
    sed -i "s/^Name=.*/Name=NeoWin/" "${SOUND_DIR}/neowin/index.theme"

    ok "Sound pack '${pack}' installed"
    info "You may need to select 'neowin' in System Settings → Sounds if not already active"
}

refresh() {
    info "Clearing caches and restarting Plasma..."

    # Wipe all render/lookup caches that hold stale theme/icon/color data
    rm -f "${HOME}/.cache/plasma_theme_"*.kcache 2>/dev/null || true
    rm -f "${HOME}/.cache/plasma-svgelements-"* 2>/dev/null || true
    rm -f "${HOME}/.cache/icon-cache.kcache" 2>/dev/null || true
    rm -f "${HOME}/.cache/ksycoca"*"_"* 2>/dev/null || true
    rm -rf "${HOME}/.cache/plasmashell" 2>/dev/null || true

    # Rebuild ksycoca (app/service registry)
    if command -v kbuildsycoca6 &>/dev/null; then
        kbuildsycoca6 --noincremental 2>/dev/null || true
    elif command -v kbuildsycoca5 &>/dev/null; then
        kbuildsycoca5 --noincremental 2>/dev/null || true
    fi

    # Reload KWin
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus &>/dev/null; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi

    # Restart plasmashell, waiting for clean exit before respawn
    if command -v kquitapp6 &>/dev/null && command -v kstart &>/dev/null; then
        kquitapp6 plasmashell 2>/dev/null || true
        # Wait up to 10s for plasmashell to actually exit
        for _ in {1..20}; do
            pgrep -x plasmashell >/dev/null || break
            sleep 0.5
        done
        pkill -9 -x plasmashell 2>/dev/null || true
        setsid kstart plasmashell </dev/null >/dev/null 2>&1 &
        disown 2>/dev/null || true
        ok "Plasma shell restarted"
    else
        warn "kquitapp6/kstart not found — restart plasmashell manually"
    fi

    ok "Refresh complete"
}

uninstall() {
    info "Uninstalling NeoWin theme..."

    rm -rf "${ICON_DIR}/NeoWin"
    for theme in WillowDarkBlur WillowDarkBlurAlt WillowLightBlur WillowLightBlurAlt; do
        rm -rf "${AURORAE_DIR}/${theme}"
    done
    rm -rf "${CURSOR_DIR}/WinSur-dark-cursors" "${CURSOR_DIR}/WinSur-white-cursors"
    rm -rf "${PLASMA_THEME_DIR}/Utterly-Round"
    rm -f "${COLOR_DIR}/NeoWinDark.colors" "${COLOR_DIR}/NeoWinLight.colors"
    rm -rf "${LAF_DIR}/neowin-dark" "${LAF_DIR}/neowin-light"
    rm -rf "${SOUND_DIR}/neowin"

    if command -v kbuildsycoca6 &>/dev/null; then
        kbuildsycoca6 --noincremental 2>/dev/null || true
    fi

    ok "NeoWin theme uninstalled"
    warn "You may need to select a different theme in System Settings"
}

usage() {
    cat << EOF
NeoWin — Windows 11 style KDE Plasma theme

Usage: $(basename "$0") <command>

Commands:
  install              Install all theme assets, apply config, enable auto dark/light
  refresh              Clear caches and restart Plasma (apply theme changes live)
  restore-panel        Restore saved panel layout
  wallpaper [provider] Set Picture of the Day wallpaper on all desktops (default: bing)
  sounds [pack]        List or switch sound packs (win11, win10, win7, winxp)
  uninstall            Remove all installed theme assets
  help                 Show this help message

Examples:
  $(basename "$0") install              # Install everything and configure KDE
  $(basename "$0") wallpaper            # Bing Picture of the Day on all desktops
  $(basename "$0") wallpaper apod       # NASA APOD instead
  $(basename "$0") sounds               # List available sound packs
  $(basename "$0") sounds win7 Sonata   # Switch to Win7 Sonata sounds
  $(basename "$0") restore-panel        # Restore the saved panel layout
  $(basename "$0") uninstall            # Remove all NeoWin assets

Dark/light switching is handled natively by KDE (System Settings → Colors & Themes).
The installer configures AutomaticLookAndFeel with the dark and light variants.
EOF
}

# Main
case "${1:-help}" in
    install)
        install_assets
        apply_config
        refresh
        echo ""
        info "Run '$(basename "$0") restore-panel' to restore the saved panel layout"
        info "Run '$(basename "$0") sounds' to see available sound packs"
        ;;
    refresh|reload)
        refresh
        ;;
    restore-panel)
        restore_panel
        ;;
    wallpaper)
        wallpaper "${2:-}"
        ;;
    sounds)
        sounds "${2:-}" "${3:-}"
        ;;
    uninstall)
        uninstall
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        error "Unknown command: $1"
        usage
        exit 1
        ;;
esac
