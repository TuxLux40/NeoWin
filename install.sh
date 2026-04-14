#!/usr/bin/env bash
# win11-kde: Windows 11 style KDE Plasma theme installer
# Supports: install, uninstall, switch-dark, switch-light, auto-switch
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG directories
ICON_DIR="${HOME}/.local/share/icons"
AURORAE_DIR="${HOME}/.local/share/aurorae/themes"
PLASMA_THEME_DIR="${HOME}/.local/share/plasma/desktoptheme"
COLOR_DIR="${HOME}/.local/share/color-schemes"
LAF_DIR="${HOME}/.local/share/plasma/look-and-feel"
CURSOR_DIR="${HOME}/.local/share/icons"

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
    local mode="${1:-dark}"
    info "Applying ${mode} mode configuration..."

    if [ "$mode" = "dark" ]; then
        local laf="win11-kde-dark"
        local color_scheme="Win11KDEDark"
        local cursor="WinSur-dark-cursors"
        local decoration="__aurorae__svg__WillowDarkBlur"
    else
        local laf="win11-kde-light"
        local color_scheme="Win11KDELight"
        local cursor="WinSur-white-cursors"
        local decoration="__aurorae__svg__WillowLightBlur"
    fi

    # Apply look-and-feel
    if command -v lookandfeeltool &>/dev/null; then
        lookandfeeltool --apply "$laf" 2>/dev/null || true
    elif command -v plasma-apply-lookandfeel &>/dev/null; then
        plasma-apply-lookandfeel --apply "$laf" 2>/dev/null || true
    fi

    # Apply individual settings via kwriteconfig
    if command -v kwriteconfig6 &>/dev/null; then
        local kw="kwriteconfig6"
    elif command -v kwriteconfig5 &>/dev/null; then
        local kw="kwriteconfig5"
    else
        warn "kwriteconfig not found, applying via config files directly"
        kw=""
    fi

    if [ -n "$kw" ]; then
        # Color scheme
        $kw --file kdeglobals --group General --key ColorScheme "$color_scheme"
        # Icon theme
        $kw --file kdeglobals --group Icons --key Theme "Win11-KDE"
        # Widget style
        $kw --file kdeglobals --group KDE --key widgetStyle "Breeze"
        # Cursor
        $kw --file kcminputrc --group Mouse --key cursorTheme "$cursor"
        # Window decoration
        $kw --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae.v2"
        $kw --file kwinrc --group org.kde.kdecoration2 --key theme "$decoration"
        $kw --file kwinrc --group org.kde.kdecoration2 --key BorderSize "NoSides"
        $kw --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto "false"
        $kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "M"
        # Plasma theme
        $kw --file plasmarc --group Theme --key name "Utterly-Round"
        # Splash screen: none
        $kw --file ksplashrc --group KSplash --key Engine "none"
        $kw --file ksplashrc --group KSplash --key Theme "None"
        # Blur
        $kw --file kwinrc --group Plugins --key blurEnabled "true"
        $kw --file kwinrc --group Effect-blur --key BlurStrength "13"
        # Night Color
        $kw --file kwinrc --group NightColor --key Active "true"
    fi

    # Notify KWin to reload
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus &>/dev/null; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi

    ok "Applied ${mode} mode"
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

switch_mode() {
    local mode="$1"
    info "Switching to ${mode} mode..."
    apply_config "$mode"
    ok "Switched to ${mode} mode. Some changes may require re-login."
}

setup_auto_switch() {
    local light_hour="${1:-07}"
    local dark_hour="${2:-20}"

    info "Setting up automatic dark/light switching (light at ${light_hour}:00, dark at ${dark_hour}:00)..."

    local script_path="${HOME}/.local/bin/win11-kde-auto-switch.sh"
    mkdir -p "$(dirname "$script_path")"

    cat > "$script_path" << 'AUTOSWITCH'
#!/usr/bin/env bash
# Automatic dark/light mode switching for Win11-KDE
INSTALL_DIR="PLACEHOLDER_INSTALL_DIR"

current_hour=$(date +%H)
light_hour=PLACEHOLDER_LIGHT
dark_hour=PLACEHOLDER_DARK

if [ "$current_hour" -ge "$light_hour" ] && [ "$current_hour" -lt "$dark_hour" ]; then
    "$INSTALL_DIR/install.sh" switch-light
else
    "$INSTALL_DIR/install.sh" switch-dark
fi
AUTOSWITCH

    sed -i "s|PLACEHOLDER_INSTALL_DIR|${SCRIPT_DIR}|" "$script_path"
    sed -i "s|PLACEHOLDER_LIGHT|${light_hour}|" "$script_path"
    sed -i "s|PLACEHOLDER_DARK|${dark_hour}|" "$script_path"
    chmod +x "$script_path"

    # Create systemd user timers
    local timer_dir="${HOME}/.config/systemd/user"
    mkdir -p "$timer_dir"

    # Light mode timer
    cat > "${timer_dir}/win11-kde-light.timer" << EOF
[Unit]
Description=Switch Win11-KDE to light mode

[Timer]
OnCalendar=*-*-* ${light_hour}:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

    cat > "${timer_dir}/win11-kde-light.service" << EOF
[Unit]
Description=Switch Win11-KDE to light mode

[Service]
Type=oneshot
Environment=DISPLAY=:0
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus
ExecStart=${script_path}
EOF

    # Dark mode timer
    cat > "${timer_dir}/win11-kde-dark.timer" << EOF
[Unit]
Description=Switch Win11-KDE to dark mode

[Timer]
OnCalendar=*-*-* ${dark_hour}:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

    cat > "${timer_dir}/win11-kde-dark.service" << EOF
[Unit]
Description=Switch Win11-KDE to dark mode

[Service]
Type=oneshot
Environment=DISPLAY=:0
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus
ExecStart=${script_path}
EOF

    # Enable timers
    systemctl --user daemon-reload
    systemctl --user enable --now win11-kde-light.timer 2>/dev/null || warn "Could not enable light timer"
    systemctl --user enable --now win11-kde-dark.timer 2>/dev/null || warn "Could not enable dark timer"

    ok "Auto-switch configured: light at ${light_hour}:00, dark at ${dark_hour}:00"
    info "Timers status:"
    systemctl --user list-timers 'win11-kde-*' 2>/dev/null || true
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

    # Remove auto-switch
    systemctl --user disable --now win11-kde-light.timer 2>/dev/null || true
    systemctl --user disable --now win11-kde-dark.timer 2>/dev/null || true
    rm -f "${HOME}/.config/systemd/user/win11-kde-"*
    rm -f "${HOME}/.local/bin/win11-kde-auto-switch.sh"
    systemctl --user daemon-reload 2>/dev/null || true

    if command -v kbuildsycoca6 &>/dev/null; then
        kbuildsycoca6 --noincremental 2>/dev/null || true
    fi

    ok "Win11-KDE theme uninstalled"
    warn "You may need to select a different theme in System Settings"
}

usage() {
    cat << EOF
Win11-KDE Theme Installer

Usage: $(basename "$0") <command> [options]

Commands:
  install              Install all theme assets and apply dark mode
  install-light        Install all theme assets and apply light mode
  switch-dark          Switch to dark mode (assets must be installed)
  switch-light         Switch to light mode (assets must be installed)
  restore-panel        Restore saved panel layout
  auto-switch [L] [D]  Set up automatic switching (L=light hour, D=dark hour; default 07 20)
  uninstall            Remove all installed theme assets
  help                 Show this help message

Examples:
  $(basename "$0") install              # Install and apply dark mode
  $(basename "$0") switch-light         # Switch to light mode
  $(basename "$0") auto-switch 08 21    # Light at 08:00, dark at 21:00
  $(basename "$0") auto-switch          # Light at 07:00, dark at 20:00
EOF
}

# Main
case "${1:-help}" in
    install)
        install_assets
        apply_config dark
        echo ""
        info "Run '$(basename "$0") auto-switch' to enable automatic dark/light switching"
        info "Run '$(basename "$0") restore-panel' to restore the saved panel layout"
        ;;
    install-light)
        install_assets
        apply_config light
        ;;
    switch-dark)
        switch_mode dark
        ;;
    switch-light)
        switch_mode light
        ;;
    restore-panel)
        restore_panel
        ;;
    auto-switch)
        setup_auto_switch "${2:-07}" "${3:-20}"
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
