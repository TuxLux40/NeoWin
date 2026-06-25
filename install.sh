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
KVANTUM_DIR="${HOME}/.config/Kvantum"
BIN_DIR="${HOME}/.local/bin"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

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

# Read a single KDE config value; returns empty string if unavailable
_kread() {
    local file="$1" group="$2" key="$3"
    command -v kreadconfig6 &>/dev/null || { echo ""; return; }
    kreadconfig6 --file "$file" --group "$group" --key "$key" 2>/dev/null || echo ""
}

# Apply the look-and-feel package that matches the current daylight state.
# Trusts KWin NightLight's live `daylight` property as the single source of
# truth — it already reflects the user's real schedule (geoclue, manual
# location, or fixed times) including the active transition. We deliberately do
# NOT parse kwinrc [Times]: KDE may store the schedule under other keys, leaving
# stale values there (observed: [Times] SunsetStart=19:00 while KWin actually
# transitions at 21:00), which made the installer fight the kded autoswitcher.
# Falls back to neowin-dark only when there's no running KWin session to query.
_apply_laf_for_time() {
    local laf="neowin-dark" is_day="false"

    is_day=$(qdbus6 org.kde.KWin.NightLight /org/kde/KWin/NightLight \
        org.kde.KWin.NightLight.daylight 2>/dev/null || echo "false")

    [ "$is_day" = "true" ] && laf="neowin-light"

    lookandfeeltool --apply "$laf" 2>/dev/null || true

    # Switch Kvantum variant to match the LAF
    local kvantum_theme="NeoWinKvantumDark"
    [ "$is_day" = "true" ] && kvantum_theme="NeoWinKvantumLight"
    kvantummanager --set "$kvantum_theme" 2>/dev/null || true

    info "Applied ${laf} / ${kvantum_theme} for current time of day"
}

# Ensure Night Color is enabled and has a working schedule.
# Leaves the existing mode untouched if transitions are already scheduled.
# If mode=0 (automatic) and geoclue is not providing location, prompts for
# an alternative rather than silently leaving switching broken.
configure_night_color() {
    local kw="$1"
    $kw --file kwinrc --group NightColor --key Active --type bool true

    local mode scheduled=""
    mode=$(_kread kwinrc NightColor Mode)
    mode="${mode:-0}"

    scheduled=$(qdbus6 org.kde.KWin.NightLight /org/kde/KWin/NightLight \
        org.kde.KWin.NightLight.scheduledTransitionDateTime 2>/dev/null || echo "0")

    # Non-zero next transition means a working schedule exists — leave it alone
    if [ "${scheduled:-0}" != "0" ]; then
        ok "Night Color schedule is active"
        return
    fi

    # Non-zero mode means user explicitly configured location or fixed times;
    # trust it even if we can't confirm it works right now
    if [ "$mode" != "0" ]; then
        info "Night Color mode=${mode} — preserving existing configuration"
        return
    fi

    # mode=0 with no scheduled transition: automatic location detection failed
    warn "Night Color is in automatic mode but has no active schedule."
    warn "geoclue2 may not be installed — dark/light auto-switching won't work without it."
    echo ""
    echo "  [1] Install geoclue2  (automatic location — recommended)"
    echo "  [2] Fixed times       (sunrise 07:00, sunset 19:00 — adjust in System Settings)"
    echo "  [3] Skip              (configure manually: System Settings → Night Color)"
    echo ""

    local choice="3"
    if [ -t 0 ]; then
        read -rp "Choose [1/2/3]: " choice
    else
        info "Non-interactive — skipping Night Color setup; configure manually."
    fi

    case "${choice:-3}" in
        1)
            if command -v pacman &>/dev/null; then
                info "Installing geoclue..."
                sudo pacman -S --needed --noconfirm geoclue 2>/dev/null || true
            elif command -v apt-get &>/dev/null; then
                info "Installing geoclue2..."
                sudo apt-get install -y geoclue-2.0 2>/dev/null || true
            elif command -v dnf &>/dev/null; then
                info "Installing geoclue2..."
                sudo dnf install -y geoclue2 2>/dev/null || true
            else
                info "Install geoclue2 manually for your distro"
            fi
            ;;
        2)
            $kw --file kwinrc --group NightColor --key Mode 2
            $kw --file kwinrc --group Times --key SunriseStart "07:00:00"
            $kw --file kwinrc --group Times --key SunsetStart "19:00:00"
            ok "Night Color set to fixed times (sunrise 07:00, sunset 19:00)"
            info "Adjust in System Settings → Night Color"
            ;;
        *)
            info "Skipped — configure Night Color manually in System Settings"
            ;;
    esac
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

    # Remove any stale plasma theme colors file — Utterly-Round follows the KDE
    # color scheme natively; a colors file would override SVG backgrounds globally
    rm -f "${PLASMA_THEME_DIR}/Utterly-Round/colors"

    # Kvantum themes (both variants for auto light/dark switching)
    info "Installing NeoWin Kvantum themes..."
    mkdir -p "${KVANTUM_DIR}"
    rm -rf "${KVANTUM_DIR}/NeoWinKvantumDark" "${KVANTUM_DIR}/NeoWinKvantumLight"
    cp -a "${SCRIPT_DIR}/kvantum/NeoWinKvantumDark" "${KVANTUM_DIR}/"
    cp -a "${SCRIPT_DIR}/kvantum/NeoWinKvantumLight" "${KVANTUM_DIR}/"
    ok "Kvantum themes installed (dark + light)"

    install_kvantum_sync

    # Sound theme (default: win11)
    info "Installing sound themes..."
    mkdir -p "${SOUND_DIR}"
    rm -rf "${SOUND_DIR}/neowin"
    cp -a "${SCRIPT_DIR}/sounds/win11-kde" "${SOUND_DIR}/neowin"
    ok "Win11 sound theme installed as default"

    echo ""
    ok "All assets installed successfully!"
}

install_kvantum_sync() {
    info "Installing Kvantum auto-sync service..."

    if ! command -v dbus-monitor &>/dev/null; then
        info "dbus-monitor not found — skipping Kvantum auto-sync service"
        return
    fi

    mkdir -p "${BIN_DIR}" "${SYSTEMD_USER_DIR}"
    cp -f "${SCRIPT_DIR}/kvantum-sync/neowin-kvantum-sync" "${BIN_DIR}/neowin-kvantum-sync"
    chmod +x "${BIN_DIR}/neowin-kvantum-sync"
    cp -f "${SCRIPT_DIR}/kvantum-sync/neowin-kvantum-sync.service" \
        "${SYSTEMD_USER_DIR}/neowin-kvantum-sync.service"

    systemctl --user daemon-reload 2>/dev/null || true
    if systemctl --user enable --now neowin-kvantum-sync.service 2>/dev/null; then
        ok "Kvantum auto-sync service enabled and started"
    else
        error "Could not enable neowin-kvantum-sync.service — run: systemctl --user enable --now neowin-kvantum-sync.service"
    fi
}

apply_config() {
    info "Applying NeoWin configuration..."

    if ! command -v kwriteconfig6 &>/dev/null; then
        error "kwriteconfig6 not found — cannot apply settings"
        return 1
    fi
    local kw="kwriteconfig6"

    # Enable KDE's built-in automatic dark/light switching
    $kw --file kdeglobals --group KDE --key AutomaticLookAndFeel --type bool true
    $kw --file kdeglobals --group KDE --key DefaultDarkLookAndFeel neowin-dark
    $kw --file kdeglobals --group KDE --key DefaultLightLookAndFeel neowin-light

    # Icon theme (shared between light and dark)
    $kw --file kdeglobals --group Icons --key Theme "NeoWin"
    # Widget style — Kvantum (provides Acrylic blur via translucent windows)
    $kw --file kdeglobals --group KDE --key widgetStyle "kvantum"
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
    # Night Color — ensure enabled; handle schedule if broken
    configure_night_color "$kw"
    # Sound theme
    $kw --file kdeglobals --group Sounds --key Theme "neowin"

    # Notify KWin to reload
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

    # Reload kded autoswitcher first so it registers the new LAF keys; it may
    # query daylight while KWin is still settling from the reconfigure above and
    # apply the wrong variant — _apply_laf_for_time runs after and wins.
    qdbus6 org.kde.kded6 /kded org.kde.kded6.unloadModule lookandfeelautoswitcher >/dev/null 2>&1 || true
    qdbus6 org.kde.kded6 /kded org.kde.kded6.loadModule lookandfeelautoswitcher >/dev/null 2>&1 || true

    # Apply the LAF + Kvantum variant that matches current time (authoritative last step)
    _apply_laf_for_time

    ok "Configuration applied"
    ok "Automatic dark/light switching enabled"
    info "KDE will switch between neowin-dark and neowin-light at sunrise/sunset"
    info "Adjust the schedule in System Settings → Night Color"
}

restore_panel() {
    info "Restoring panel layout..."
    local target="${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"

    if [ -f "${SCRIPT_DIR}/panel-layout/plasma-org.kde.plasma.desktop-appletsrc" ]; then
        cp -f "${SCRIPT_DIR}/panel-layout/plasma-org.kde.plasma.desktop-appletsrc" "$target"
        ok "Panel layout restored — restart Plasma: plasmashell --replace &"
    else
        error "Panel layout file not found: ${SCRIPT_DIR}/panel-layout/plasma-org.kde.plasma.desktop-appletsrc"
    fi
}

wallpaper() {
    local provider="${1:-bing}"

    if ! command -v qdbus6 &>/dev/null; then
        error "qdbus6 not found — cannot talk to plasmashell"
        return 1
    fi

    info "Setting wallpaper to Picture of the Day (provider: ${provider})..."
    qdbus6 org.kde.plasmashell /PlasmaShell evaluateScript "
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

refresh() {
    warn "Plasma shell will restart. Save your work now."
    echo ""

    # Plasma SVG render cache — the only cache that needs manual clearing.
    # Everything else (color schemes, decorations, cursors) has no disk cache.
    rm -rf "${HOME}/.cache/plasma"* 2>/dev/null || true

    # Rebuild icon/service database so new icon files are discoverable
    kbuildsycoca6 --noincremental 2>/dev/null || true

    # Reload KWin in-process: picks up new decorations without killing the
    # compositor. Never restart KWin on Wayland — it kills all Wayland windows.
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

    # Kvantum has no reload signal — kill every user app that has the style
    # plugin loaded so they restart with the new theme. Skip session-critical
    # services that would break the desktop if killed.
    local kvantum_lib
    kvantum_lib=$(find /usr/lib /usr/lib64 2>/dev/null \
        -name 'kvantum.so' -path '*/styles/*' 2>/dev/null | head -1)
    if [ -n "$kvantum_lib" ] && command -v lsof &>/dev/null; then
        local skip_procs
        # compositor, shell, auth, wallet, lock screen, portals — all untouchable
        skip_procs="plasmashell|kwin_wayland|kwin_x11|kded6|kwalletd6"
        skip_procs+="|kscreenlocker_greet|polkit-kde-agent-1"
        skip_procs+="|plasma-xdg-desktop-portal-kde|xdg-desktop-portal"
        local killed=()
        while IFS= read -r pid; do
            local name
            name=$(cat "/proc/${pid}/comm" 2>/dev/null) || continue
            [[ "$name" =~ ^($skip_procs)$ ]] && continue
            kill "$pid" 2>/dev/null && killed+=("$name")
        done < <(lsof "$kvantum_lib" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)
        [ ${#killed[@]} -gt 0 ] && ok "Killed Kvantum apps (reopen to get new style): ${killed[*]}"
    fi

    # Restart the KDE portal so file pickers in VS Code / Electron apps pick up
    # the new Kvantum style. Correct systemd unit name is plasma-xdg-desktop-portal-kde.
    systemctl --user restart plasma-xdg-desktop-portal-kde 2>/dev/null || true

    # Apply LAF + Kvantum variant for current time before plasmashell exits,
    # so config is on disk when the new shell reads it
    _apply_laf_for_time

    # Restart plasmashell last — official method per KDE docs
    plasmashell --replace >/dev/null 2>&1 &
    disown 2>/dev/null || true
    ok "Plasma shell restarting"
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
    rm -rf "${KVANTUM_DIR}/NeoWinKvantumDark" "${KVANTUM_DIR}/NeoWinKvantumLight"

    # Kvantum auto-sync service
    systemctl --user disable --now neowin-kvantum-sync.service 2>/dev/null || true
    rm -f "${SYSTEMD_USER_DIR}/neowin-kvantum-sync.service"
    rm -f "${BIN_DIR}/neowin-kvantum-sync"
    systemctl --user daemon-reload 2>/dev/null || true

    kbuildsycoca6 --noincremental 2>/dev/null || true

    ok "NeoWin theme uninstalled — select a different theme in System Settings"
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
  uninstall            Remove all installed theme assets
  help                 Show this help message

Examples:
  $(basename "$0") install              # Install everything and configure KDE
  $(basename "$0") wallpaper            # Bing Picture of the Day on all desktops
  $(basename "$0") wallpaper apod       # NASA APOD instead
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
