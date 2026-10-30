pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * "Keep system awake" state + idle inhibitor.
 *
 * 2026-10-30: Hyprland 0.56 does not surface wayland idle-inhibitors created on
 * layer-shell surfaces to idle daemons (the IdleInhibitor below alone never
 * stopped hypridle from locking/suspending/blanking). While enabled we therefore
 * also hold a logind idle/sleep inhibitor, which hypridle explicitly respects
 * (per-listener ignore_inhibit = false), so the toggle actually works.
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    Connections {
        target: Persistent
        function onReadyChanged() {
            root.applyPersistedInhibit();
        }
    }

    Component.onCompleted: {
        // The shell can also be hot-reloaded after Persistent is already ready,
        // in which case readyChanged never fires again.
        if (Persistent.ready)
            root.applyPersistedInhibit();
    }

    function applyPersistedInhibit() {
        if (!Persistent.isNewHyprlandInstance) {
            root.inhibit = Persistent.states.idle.inhibit;
        } else {
            Persistent.states.idle.inhibit = root.inhibit;
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    // logind idle/sleep inhibitor (honored by hypridle).
    Process {
        id: logindInhibitor
        running: root.inhibit
        command: [
            "systemd-inhibit",
            "--what=idle:sleep",
            "--mode=block",
            "--why=quickshell keep-awake",
            "sleep",
            "infinity"
        ]
    }

    // CLI control: qs -c ii ipc call idle <toggle|enable|disable|status>
    IpcHandler {
        target: "idle"

        function toggle(): void {
            root.toggleInhibit();
        }

        function enable(): void {
            root.toggleInhibit(true);
        }

        function disable(): void {
            root.toggleInhibit(false);
        }

        function status(): bool {
            return root.inhibit;
        }
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            // Just in case...
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
        }
    }
}
