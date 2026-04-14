#!/usr/bin/env bash
# win11-kde: Windows 11 style KDE Plasma theme installer
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
    info "Installing Win11-KDE theme assets..."

    # Icons
    info "Installing icon theme..."
    mkdir -p "${ICON_DIR}"
    rm -rf "${ICON_DIR}/Win11-KDE"
    cp -a "${SCRIPT_DIR}/icons/win11-kde" "${ICON_DIR}/Win11-KDE"
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
    cp -f "${SCRIPT_DIR}/color-schemes/Win11KDEDark.colors" "${COLOR_DIR}/"
    cp -f "${SCRIPT_DIR}/color-schemes/Win11KDELight.colors" "${COLOR_DIR}/"
    ok "Color schemes installed"

    # Look-and-feel packages
    info "Installing look-and-feel packages..."
    mkdir -p "${LAF_DIR}"
    rm -rf "${LAF_DIR}/win11-kde-dark" "${LAF_DIR}/win11-kde-light"
    cp -a "${SCRIPT_DIR}/look-and-feel/win11-kde-dark" "${LAF_DIR}/"
    cp -a "${SCRIPT_DIR}/look-and-feel/win11-kde-light" "${LAF_DIR}/"
    ok "Look-and-feel packages installed"

    # Sound theme
    info "Installing Win11-KDE sound theme..."
    mkdir -p "${SOUND_DIR}"
    rm -rf "${SOUND_DIR}/win11-kde"
    cp -a "${SCRIPT_DIR}/sounds/win11-kde" "${SOUND_DIR}/win11-kde"
    ok "Sound theme installed"

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
    info "Applying Win11-KDE configuration..."

    local kw
    kw="$(find_kwriteconfig)"
    if [ -z "$kw" ]; then
        error "kwriteconfig not found — cannot apply settings"
        return 1
    fi

    # Apply dark look-and-feel as the active theme
    if command -v lookandfeeltool &>/dev/null; then
        lookandfeeltool --apply win11-kde-dark 2>/dev/null || true
    elif command -v plasma-apply-lookandfeel &>/dev/null; then
        plasma-apply-lookandfeel --apply win11-kde-dark 2>/dev/null || true
    fi

    # Enable KDE's built-in automatic dark/light switching
    $kw --file kdeglobals --group KDE --key AutomaticLookAndFeel --type bool true
    $kw --file kdeglobals --group KDE --key DefaultDarkLookAndFeel win11-kde-dark
    $kw --file kdeglobals --group KDE --key DefaultLightLookAndFeel win11-kde-light

    # Icon theme (shared between light and dark)
    $kw --file kdeglobals --group Icons --key Theme "Win11-KDE"
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
    # Blur
    $kw --file kwinrc --group Plugins --key blurEnabled --type bool true
    $kw --file kwinrc --group Effect-blur --key BlurStrength "13"
    # Night Color
    $kw --file kwinrc --group NightColor --key Active --type bool true
    # Sound theme
    $kw --file kdeglobals --group Sounds --key Theme "win11-kde"

    # Notify KWin to reload
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus &>/dev/null; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi

    ok "Configuration applied"
    ok "Automatic dark/light switching enabled via KDE settings"
    info "KDE will switch between win11-kde-dark and win11-kde-light automatically"
    info "You can adjust the schedule in System Settings → Colors & Themes → Behavior"
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

uninstall() {
    info "Uninstalling Win11-KDE theme..."

    rm -rf "${ICON_DIR}/Win11-KDE"
    for theme in WillowDarkBlur WillowDarkBlurAlt WillowLightBlur WillowLightBlurAlt; do
        rm -rf "${AURORAE_DIR}/${theme}"
    done
    rm -rf "${CURSOR_DIR}/WinSur-dark-cursors" "${CURSOR_DIR}/WinSur-white-cursors"
    rm -rf "${PLASMA_THEME_DIR}/Utterly-Round"
    rm -f "${COLOR_DIR}/Win11KDEDark.colors" "${COLOR_DIR}/Win11KDELight.colors"
    rm -rf "${LAF_DIR}/win11-kde-dark" "${LAF_DIR}/win11-kde-light"
    rm -rf "${SOUND_DIR}/win11-kde"

    if command -v kbuildsycoca6 &>/dev/null; then
        kbuildsycoca6 --noincremental 2>/dev/null || true
    fi

    ok "Win11-KDE theme uninstalled"
    warn "You may need to select a different theme in System Settings"
}

usage() {
    cat << EOF
Win11-KDE Theme Installer

Usage: $(basename "$0") <command>

Commands:
  install              Install all theme assets, apply config, enable auto dark/light
  restore-panel        Restore saved panel layout
  uninstall            Remove all installed theme assets
  help                 Show this help message

Examples:
  $(basename "$0") install              # Install everything and configure KDE
  $(basename "$0") restore-panel        # Restore the saved panel layout
  $(basename "$0") uninstall            # Remove all Win11-KDE assets

Dark/light switching is handled natively by KDE (System Settings → Colors & Themes).
The installer configures AutomaticLookAndFeel with the dark and light variants.
EOF
}

# Main
case "${1:-help}" in
    install)
        install_assets
        apply_config
        echo ""
        info "Run '$(basename "$0") restore-panel' to restore the saved panel layout"
        ;;
    restore-panel)
        restore_panel
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
