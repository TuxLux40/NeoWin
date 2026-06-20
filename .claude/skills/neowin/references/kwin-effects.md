# KWin Declarative Effects Reference

Source: `/home/oliver/Projects/develop-kde-org/content/docs/plasma/kwineffect/_index.md`

---

## Package structure

```
my-effect/
└── package/
    ├── metadata.json
    └── contents/
        ├── ui/
        │   └── main.qml     # required entry point
        └── shaders/         # optional: GLSL shaders
```

---

## metadata.json

```json
{
    "KPackageStructure": "KWin/Effect",
    "KPlugin": {
        "Authors": [
            {
                "Email": "you@example.com",
                "Name": "Your Name"
            }
        ],
        "Category": "Appearance",
        "Description": "Short description of what the effect does",
        "EnabledByDefault": false,
        "Id": "my-effect",
        "License": "MIT",
        "Name": "My Effect"
    },
    "X-KDE-Ordering": 60,
    "X-Plasma-API": "declarativescript"
}
```

`X-KDE-Ordering` controls effect layering order (lower = runs earlier). `EnabledByDefault: false` means user must enable it in System Settings.

---

## Install & uninstall

```bash
# Install
kpackagetool6 --type KWin/Effect --install package/

# Uninstall
kpackagetool6 --type KWin/Effect --remove my-effect

# Reload after editing
qdbus org.kde.KWin /KWin reconfigureEffect my-effect
```

After install, enable in **System Settings → Desktop Effects**.

---

## main.qml skeleton

```qml
import QtQuick
import org.kde.kwin as KWinComponents

Item {
    id: effect

    // Called when effect is loaded
    Component.onCompleted: {
        // Connect to signals here
    }

    // React to window events
    Connections {
        target: KWinComponents.Workspace
        function onWindowAdded(window) {
            // window is a KWin::Window
            animateWindow(window)
        }
    }

    function animateWindow(window) {
        // Use KWin effect APIs here
    }
}
```

---

## KWin QML API highlights

```qml
import org.kde.kwin as KWinComponents

// Workspace singleton
KWinComponents.Workspace.activeWindow         // currently focused window
KWinComponents.Workspace.windows              // all windows
KWinComponents.Workspace.windowAdded          // signal
KWinComponents.Workspace.windowRemoved        // signal

// Window properties
window.resourceName        // app name
window.caption             // window title
window.frameGeometry       // QRect: x, y, width, height
window.minimized
window.maximized
window.fullScreen
window.onDesktopChanged    // signal

// Animate a property (built-in effect helper)
effect.animate(window, Effect.Opacity, 250, 0.0, 1.0)
// animate(window, attribute, duration_ms, to, from)
```

Available `Effect.*` attributes: `Opacity`, `Scale`, `Translation`, `Rotation`, `Saturation`, `Brightness`, `BlendMode`.

---

## GLSL shaders (optional)

Place `.glsl` / `.frag` / `.vert` files in `contents/shaders/`. Load from QML:

```qml
ShaderEffect {
    fragmentShader: Qt.resolvedUrl("../shaders/my-effect.frag")
}
```

---

## Debugging

```bash
# See KWin debug output
QT_LOGGING_RULES="kwin.effects*=true" kwin_wayland --replace 2>&1 | grep effect
```

Check System Settings → Desktop Effects for whether the effect appears and is enabled.

---

## Alternative: C++ KDecoration2

For window decorations written in C++ rather than SVG/QML, use the [KDecoration2 API](https://api.kde.org/plasma/kdecoration/html/index.html). This is a different path from Aurorae — it requires compiling a plugin and is significantly more complex.
