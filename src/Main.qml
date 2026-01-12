/*
 * Plugin logic, instance available at pluginApi.mainInstance
 * Wraps supergfxctl in sgfx
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

import QtQuick
import Quickshell.Io
import Quickshell.Services.Notifications

import qs.Commons

import "lib"
import "lib/SemVer.js"

QtObject {
    id: root

    property QtObject pluginApi: null
    readonly property string pluginId: pluginApi?.pluginId
    readonly property string pluginVersion: pluginApi?.manifest.version ?? "???"

    readonly property QtObject pluginSettings: QtObject {
        readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings ?? {}
        readonly property var _user: root.pluginApi?.pluginSettings ?? {}

        property bool debug: _user.debug ?? _manifest.debug ?? false

        // rog-control-center
        readonly property QtObject rogcc: QtObject {
            readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings.rogcc ?? {}
            readonly property var _user: root.pluginApi?.pluginSettings.rogcc ?? {}

            property bool listenToNotifications: _user.listenToNotifications ?? _manifest.listenToNotifications ?? false
        }

        readonly property QtObject supergfxctl: QtObject {
            readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings.supergfxctl ?? {}
            readonly property var _user: root.pluginApi?.pluginSettings.supergfxctl ?? {}

            property bool patchPending: _user.patchPending ?? _manifest.patchPending ?? true
            property bool polling: _user.polling ?? _manifest.polling ?? false
            property int pollingInterval: _user.pollingInterval ?? _manifest.pollingInterval ?? 3000
        }
    }

    readonly property bool available: sgfx.available
    readonly property bool busy: setModeProc.running || refreshProc.running

    readonly property string version: sgfx.version
    readonly property int mode: sgfx.mode
    readonly property int pendingAction: sgfx.pendingAction
    readonly property bool hasPendingAction: sgfx.pendingAction !== SGFX.Action.Nothing
    readonly property int pendingMode: sgfx.pendingMode

    Component.onCompleted: {
        refresh();
    }

    function isModeSupported(mode: int): bool {
        return (sgfx.supportedModesMask & (1 << mode)) !== 0;
    }

    function getModeLabel(mode: int): string {
        switch (mode) {
        case SGFX.Mode.Integrated:
            return root.pluginApi.tr("mode.Integrated");
        case SGFX.Mode.Hybrid:
            return root.pluginApi.tr("mode.Hybrid");
        case SGFX.Mode.AsusMuxDgpu:
            return root.pluginApi.tr("mode.AsusMuxDgpu");
        case SGFX.Mode.NvidiaNoModeset:
            return root.pluginApi.tr("mode.NvidiaNoModeset");
        case SGFX.Mode.Vfio:
            return root.pluginApi.tr("mode.Vfio");
        case SGFX.Mode.AsusEgpu:
            return root.pluginApi.tr("mode.AsusEgpu");
        default:
            return root.pluginApi.tr("unknown");
        }
    }

    function getActionLabel(action: int): string {
        switch (action) {
        case SGFX.Action.Logout:
            return I18n.tr("session-menu.logout");
        case SGFX.Action.Reboot:
            return I18n.tr("session-menu.reboot");
        case SGFX.Action.SwitchToIntegrated:
            return root.pluginApi.tr("action.SwitchToIntegrated");
        case SGFX.Action.AsusEgpuDisable:
            return root.pluginApi.tr("action.AsusEgpuDisable");
        case SGFX.Action.Nothing:
        default:
            return "";
        }
    }

    function getTooltip(): string {
        const label = root.getModeLabel(root.mode);
        if (!root.hasPendingAction) {
            return label;
        }
        return `${label} | ${root.getActionLabel(root.pendingAction)}`;
    }

    function refresh(): void {
        return sgfx.refresh();
    }

    function setMode(mode: int): bool {
        return sgfx.setMode(mode);
    }

    function log(...msg): void {
        if (root.pluginSettings.debug) {
            Logger.i(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
        }
    }

    function warn(...msg): void {
        if (root.pluginSettings.debug) {
            Logger.w(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
        }
    }

    function error(...msg): void {
        if (root.pluginSettings.debug) {
            Logger.e(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
        }
    }

    readonly property Process refreshProc: Process {
        id: refreshProc
        running: false
        command: ["supergfxctl", "--version", "--get", "--supported", "--pend-action", "--pend-mode"]
        stdout: StdioCollector {
            // TODO: supergfxctl sometimes takes time to exit after printing
            // investigate or find a workaround
            onStreamFinished: sgfx.parseOutput(text.trim())
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                sgfx.available = false;
            }
        }
    }

    readonly property Timer pollingTimer: Timer {
        interval: root.pluginSettings.supergfxctl.pollingInterval
        repeat: true
        running: root.available && !root.busy && root.pluginSettings.supergfxctl.polling

        onTriggered: {
            if (root.busy) {
                root.log("poll skipped: supergfxctl is busy");
                return;
            }

            root.refresh();
        }
    }

    readonly property Connections notificationListener: Connections {
        target: NotificationServer {
            onNotification: notification => {
                root.log(notification);
            }
        }
    }

    readonly property Process setModeProc: Process {
        stderr: StdioCollector {
            onStreamFinished: {
                if (root.debug && text) {
                    root.error(text);
                }
            }
        }
        onExited: exitCode => {
            // pending mode has been set manually in sgfx.setMode
            // if process exited successfully, set pending action
            // if not, clear pending mode
            if (root.pluginSettings.supergfxctl.patchPending) {
                if (exitCode === 0) {
                    root.sgfx.pendingAction = root.sgfx.requiredAction(root.pendingMode, root.mode);
                } else {
                    root.sgfx.pendingMode = SGFX.Mode.None;
                }
            }

            // per asusctl/rog-control-center, supergfxctl output after mode switch is unreliable, and requires reboot
            // (see https://gitlab.com/asus-linux/asusctl/-/blob/main/rog-control-center/src/notify.rs?ref_type=heads#L361)
            //
            // it is unclear whether thats actually true (the unreliable part, and the reboot part), since per supergfxctl readme
            // (see https://gitlab.com/asus-linux/supergfxctl)
            // 			If rebootless switch fails: you may need the following:
            // 			sudo sed -i 's/#KillUserProcesses=no/KillUserProcesses=yes/' /etc/systemd/logind.conf
            // as well as
            // 			Switch GPU modes
            // 			Switching to/from Hybrid mode requires a logout only. (no reboot)
            // 			Switching between integrated/vfio is instant. (no logout or reboot)
            //
            // after some testing on my machine, both seem to be incorrect as to what action needs to be taken:
            // integrated <-> hybrid: reboot
            // integrated -> dgpu: just works
            // dgpu <- integrated: reboot      // !!!!
            // hybrid <-> dgpu: logout
            //
            // most of the time
            // supergfxctl --pend-mode --pend-action
            // reports absolute nonsense, saying no action is required, or no mode is pending after switch
            //
            // for now, we provide the user with 2 options:
            // guess the required action ourselves or rely on supergfxctl
            root.refresh();
        }
    }
}
