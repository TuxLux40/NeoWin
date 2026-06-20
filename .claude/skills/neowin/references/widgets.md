# Plasma Widget (Plasmoid) Reference

Source: `/home/oliver/Projects/develop-kde-org/content/docs/plasma/widget/`

---

## Install location

```
~/.local/share/plasma/plasmoids/<com.yourname.widgetid>/
```
System widgets: `/usr/share/plasma/plasmoids/`. Use reverse-DNS naming.

---

## Package structure

```
com.yourname.mywidget/
├── metadata.json
└── contents/
    ├── ui/
    │   ├── main.qml               # required: widget representation
    │   ├── CompactRepresentation.qml  # optional: compact (panel) view
    │   ├── FullRepresentation.qml     # optional: expanded popup view
    │   └── configGeneral.qml         # optional: config page
    ├── config/
    │   └── config.qml             # declares config pages
    └── locale/                    # optional: translations
```

---

## metadata.json (KF6 / Plasma 6)

```json
{
    "KPlugin": {
        "Authors": [{"Email": "you@example.com", "Name": "Your Name"}],
        "Category": "Utilities",
        "Description": "What this widget does",
        "Id": "com.yourname.mywidget",
        "License": "GPL-2.0-or-later",
        "Name": "My Widget",
        "Version": "1.0"
    },
    "X-Plasma-API-Minimum-Version": "6.0",
    "KPackageStructure": "Plasma/Applet"
}
```

Remove any `Name[fr]` / `Description[zh_CN]` translated lines when forking. The `Id` must match the folder name exactly.

---

## main.qml skeleton

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Compact representation (shown in panel)
    compactRepresentation: Item {
        Kirigami.Icon {
            anchors.fill: parent
            source: "appointment-new"
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    // Full representation (shown in popup or on desktop)
    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.minimumHeight: Kirigami.Units.gridUnit * 8

        PlasmaComponents.Label {
            text: "Hello, Plasma!"
            anchors.centerIn: parent
        }
    }
}
```

---

## Key QML imports

| Import | Purpose |
|---|---|
| `org.kde.plasma.plasmoid` | `PlasmoidItem`, `Plasmoid` attached property |
| `org.kde.plasma.core as PlasmaCore` | `DataSource`, `Units`, theme colors |
| `org.kde.plasma.components as PlasmaComponents` | `Label`, `Button`, `CheckBox`, etc. |
| `org.kde.kirigami as Kirigami` | `Icon`, `Units`, layout helpers |
| `org.kde.plasma.extras as PlasmaExtras` | `PlaceholderMessage`, `ScrollArea` |

---

## Plasmoid attached properties (in QML)

```qml
// Accessed on any item via Plasmoid.<property>
Plasmoid.title           // widget title (read/write)
Plasmoid.icon            // widget icon name
Plasmoid.expanded        // whether popup is open (set true to open)
Plasmoid.configuration   // config object (auto-generated from config.qml)
Plasmoid.formFactor      // Planar | Vertical | Horizontal | MediaCenter
Plasmoid.location        // Desktop | TopEdge | BottomEdge | LeftEdge | RightEdge
```

---

## Widget configuration

1. Create `contents/config/config.qml`:
```qml
import org.kde.plasma.configuration
ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        source: "configGeneral.qml"
    }
}
```

2. Create `contents/ui/configGeneral.qml`:
```qml
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_myText: myTextInput.text  // cfg_ prefix = auto-persisted

    QQC2.TextField {
        id: myTextInput
        Kirigami.FormData.label: "Label text:"
    }
}
```

Config values are accessed via `Plasmoid.configuration.myText` in main.qml.

---

## Testing

```bash
# Quick test in a window
plasmawindowed com.yourname.mywidget

# Or: copy to plasmoids dir and add via right-click → Add Widgets
```

Restart to pick up metadata changes:
```bash
plasmashell --replace &
```

---

## Forking an existing widget (recommended starting point)

```bash
mkdir -p ~/.local/share/plasma/plasmoids
cp -r /usr/share/plasma/plasmoids/org.kde.plasma.analogclock \
       ~/.local/share/plasma/plasmoids/com.yourname.mywidget
cd ~/.local/share/plasma/plasmoids/com.yourname.mywidget

# Update metadata.json - set Id, Name, remove translations, delete metadata.desktop
sed -i 's/org.kde.plasma.analogclock/com.yourname.mywidget/' metadata.json
sed -i '/^\s*"Name\[/d; /^\s*"Description\[/d' metadata.json
rm -f metadata.desktop

plasmawindowed com.yourname.mywidget
```

---

## Useful docs

- Widget tutorial: `https://develop.kde.org/docs/plasma/widget/`
- Plasma QML API: `https://develop.kde.org/docs/plasma/widget/plasma-qml-api/`
- Kirigami docs: `https://develop.kde.org/docs/getting-started/kirigami/`
