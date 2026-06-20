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

# Read a single KDE config value; returns empty string if unavailable
_kread() {
    local file="$1" group="$2" key="$3" tool
    tool="kreadconfig6"
    command -v "$tool" &>/dev/null || tool="kreadconfig5"
    command -v "$tool" &>/dev/null || { echo ""; return; }
    "$tool" --file "$file" --group "$group" --key "$key" 2>/dev/null || echo ""
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
    local laf="neowin-dark" is_day="false" qd=""
    command -v qdbus6 &>/dev/null && qd="qdbus6"
    command -v qdbus &>/dev/null && [ -z "$qd" ] && qd="qdbus"

    if [ -n "$qd" ]; then
        is_day=$($qd org.kde.KWin.NightLight /org/kde/KWin/NightLight \
            org.kde.KWin.NightLight.daylight 2>/dev/null || echo "false")
    fi

    [ "$is_day" = "true" ] && laf="neowin-light"

    if command -v lookandfeeltool &>/dev/null; then
        lookandfeeltool --apply "$laf" 2>/dev/null || true
    elif command -v plasma-apply-lookandfeel &>/dev/null; then
        plasma-apply-lookandfeel --apply "$laf" 2>/dev/null || true
    fi

    # Switch Kvantum variant to match the LAF
    local kvantum_theme="NeoWinKvantumDark"
    [ "$is_day" = "true" ] && kvantum_theme="NeoWinKvantumLight"
    if command -v kvantummanager &>/dev/null; then
        kvantummanager --set "$kvantum_theme" 2>/dev/null || true
    fi

    info "Applied ${laf} / ${kvantum_theme} for current time of day"
}

# Ensure Night Color is enabled and has a working schedule.
# Leaves the existing mode untouched if transitions are already scheduled.
# If mode=0 (automatic) and geoclue is not providing location, prompts for
# an alternative rather than silently leaving switching broken.
configure_night_color() {
    local kw="$1"
    $kw --file kwinrc --group NightColor --key Active --type bool true

    local mode scheduled="" qd=""
    mode=$(_kread kwinrc NightColor Mode)
    mode="${mode:-0}"
    command -v qdbus6 &>/dev/null && qd="qdbus6"

    if [ -n "$qd" ]; then
        scheduled=$($qd org.kde.KWin.NightLight /org/kde/KWin/NightLight \
            org.kde.KWin.NightLight.scheduledTransitionDateTime 2>/dev/null || echo "0")
    fi

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
        warn "Non-interactive mode — skipping Night Color setup; configure manually."
    fi

    case "${choice:-3}" in
        1)
            if command -v pacman &>/dev/null; then
                info "Installing geoclue..."
                sudo pacman -S --needed --noconfirm geoclue 2>/dev/null \
                    || warn "Install failed — run manually: sudo pacman -S geoclue"
            elif command -v apt-get &>/dev/null; then
                info "Installing geoclue2..."
                sudo apt-get install -y geoclue-2.0 2>/dev/null \
                    || warn "Install failed — run manually: sudo apt-get install geoclue-2.0"
            elif command -v dnf &>/dev/null; then
                info "Installing geoclue2..."
                sudo dnf install -y geoclue2 2>/dev/null \
                    || warn "Install failed — run manually: sudo dnf install geoclue2"
            else
                warn "Unknown package manager — install geoclue2 manually for your distro"
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

# Install + enable the Kvantum auto-sync user service. KDE's look-and-feel
# autoswitcher switches the color scheme/decoration at sunrise/sunset but cannot
# switch the Kvantum theme; this watcher keeps Kvantum in sync with daylight.
install_kvantum_sync() {
    info "Installing Kvantum auto-sync service..."

    if ! command -v dbus-monitor &>/dev/null; then
        warn "dbus-monitor not found — skipping Kvantum auto-sync service."
        warn "Kvantum won't follow automatic dark/light switches without it."
        return
    fi

    mkdir -p "${BIN_DIR}" "${SYSTEMD_USER_DIR}"
    cp -f "${SCRIPT_DIR}/kvantum-sync/neowin-kvantum-sync" "${BIN_DIR}/neowin-kvantum-sync"
    chmod +x "${BIN_DIR}/neowin-kvantum-sync"
    cp -f "${SCRIPT_DIR}/kvantum-sync/neowin-kvantum-sync.service" \
        "${SYSTEMD_USER_DIR}/neowin-kvantum-sync.service"

    if command -v systemctl &>/dev/null; then
        systemctl --user daemon-reload 2>/dev/null || true
        if systemctl --user enable --now neowin-kvantum-sync.service 2>/dev/null; then
            ok "Kvantum auto-sync service enabled and started"
        else
            warn "Could not enable service via systemd — start manually:"
            warn "  systemctl --user enable --now neowin-kvantum-sync.service"
        fi
    else
        warn "systemctl not found — service installed but not enabled."
    fi
}

apply_config() {
    info "Applying NeoWin configuration..."

    local kw
    kw="$(find_kwriteconfig)"
    if [ -z "$kw" ]; then
        error "kwriteconfig not found — cannot apply settings"
        return 1
    fi

    # Enable KDE's built-in automatic dark/light switching
    $kw --file kdeglobals --group KDE --key AutomaticLookAndFeel --type bool true
    $kw --file kdeglobals --group KDE --key DefaultDarkLookAndFeel neowin-dark
    $kw --file kdeglobals --group KDE --key DefaultLightLookAndFeel neowin-light

    # Icon theme (shared between light and dark)
    $kw --file kdeglobals --group Icons --key Theme "NeoWin"
    # Kvantum: install if missing, then activate NeoWin dark theme
    if ! command -v kvantummanager &>/dev/null; then
        info "Installing Kvantum..."
        if command -v pacman &>/dev/null; then
            sudo pacman -S --needed --noconfirm kvantum 2>/dev/null \
                || warn "Kvantum install failed — run: sudo pacman -S kvantum"
        elif command -v apt-get &>/dev/null; then
            sudo apt-get install -y qt5-style-kvantum qt6-style-kvantum 2>/dev/null \
                || warn "Kvantum install failed — run: sudo apt-get install qt5-style-kvantum"
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y kvantum 2>/dev/null \
                || warn "Kvantum install failed — run: sudo dnf install kvantum"
        else
            warn "Unknown package manager — install Kvantum manually for your distro"
        fi
    fi
    if command -v kvantummanager &>/dev/null; then
        ok "Kvantum ready (variant set by _apply_laf_for_time below)"
    else
        warn "kvantummanager not found — activate NeoWinKvantumDark or NeoWinKvantumLight manually in Kvantum Manager"
    fi
    # Widget style
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
    local qd=""
    command -v qdbus6 &>/dev/null && qd="qdbus6"
    command -v qdbus &>/dev/null && [ -z "$qd" ] && qd="qdbus"
    if [ -n "$qd" ]; then
        $qd org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi

    # Reload kded autoswitcher first so it registers the new LAF keys; it may
    # query daylight while KWin is still settling from the reconfigure above and
    # apply the wrong variant — _apply_laf_for_time runs after and wins.
    if [ -n "$qd" ]; then
        $qd org.kde.kded6 /kded org.kde.kded6.unloadModule lookandfeelautoswitcher >/dev/null 2>&1 || true
        $qd org.kde.kded6 /kded org.kde.kded6.loadModule lookandfeelautoswitcher >/dev/null 2>&1 || true
    fi
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


refresh() {
    info "Clearing caches and restarting Plasma..."

    # Wipe all render/lookup caches that hold stale theme/icon/color data
    rm -f "${HOME}/.cache/plasma_theme_"*.kcache 2>/dev/null || true
    # KDE6 renamed plasma-svgelements-* to ksvg-elements (single file, no suffix)
    rm -f "${HOME}/.cache/plasma-svgelements-"* 2>/dev/null || true
    rm -f "${HOME}/.cache/ksvg-elements" 2>/dev/null || true
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

    # Kvantum reads its SVG once per process at startup — kill running Qt apps so
    # they pick up the new style on next open. Services that auto-restart are bounced.
    local qt_apps=(
        dolphin systemsettings kcmshell6 kate kwrite okular
        gwenview ark filelight kfind spectacle partitionmanager
        kmail kontact korganizer akregator kaddressbook
        yakuake konsole
    )
    local killed=()
    for app in "${qt_apps[@]}"; do
        if pgrep -x "$app" >/dev/null 2>&1; then
            pkill -x "$app" 2>/dev/null || true
            killed+=("$app")
        fi
    done
    [ ${#killed[@]} -gt 0 ] && ok "Killed Qt apps (reopen to see new style): ${killed[*]}"

    # Bounce Qt-using KDE services that hold Kvantum style in memory
    pkill -x kded6 2>/dev/null || true
    setsid kded6 </dev/null >/dev/null 2>&1 &
    disown 2>/dev/null || true

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
    rm -rf "${KVANTUM_DIR}/NeoWinKvantumDark" "${KVANTUM_DIR}/NeoWinKvantumLight"

    # Kvantum auto-sync service
    if command -v systemctl &>/dev/null; then
        systemctl --user disable --now neowin-kvantum-sync.service 2>/dev/null || true
    fi
    rm -f "${SYSTEMD_USER_DIR}/neowin-kvantum-sync.service"
    rm -f "${BIN_DIR}/neowin-kvantum-sync"
    command -v systemctl &>/dev/null && systemctl --user daemon-reload 2>/dev/null || true

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
