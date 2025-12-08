/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick
import Quickshell.Io

import qs.Commons

Item {
    id: root

    property var pluginApi: null

    enum SGFXMode {
        Hybrid,
        Integrated,
        NvidiaNoModeset,
        Vfio,
        AsusEgpu,
        AsusMuxDgpu,
        None
    }

    enum SGFXPower {
        Active,
        Suspended,
        Off,
        DgpuDisabled,
        AsusMuxDiscreet,
        Unknown
    }

    enum SGFXAction {
        Nothing,
        Logout,
        Reboot,
        SwitchToIntegrated,
        AsusEgpuDisable
    }

    readonly property bool available: d.available
    readonly property string version: d.version

    readonly property int mode: d.mode
    readonly property list<int> supportedModes: d.supportedModes

    readonly property int power: d.power

    readonly property int pendingAction: d.pendingAction
    readonly property bool hasPendingAction: d.pendingAction !== Main.SGFXAction.Nothing
    readonly property int pendingMode: d.pendingMode

    function setMode(mode) {
        if (d.mode === mode)
            return;

        setModeProc.command = ["supergfxctl", "-m", d.modes[mode].key];
        setModeProc.running = true;

        // manually set pending mode
        d.pendingMode = mode;
    }

    function refresh() {
        refreshProc.command = ["supergfxctl", "-vgsSpP"];
        refreshProc.running = true;
    }

    function modeInfo(mode) {
        return d.modes[mode] ?? d.modes[Main.SGFXMode.None];
    }

    function powerInfo(power) {
        return d.powers[power] ?? d.powers[Main.SGFXPower.Unknown];
    }

    function actionInfo(action) {
        return d.actions[action] ?? d.actions[Main.SGFXAction.Nothing];
    }

    function log(...msg) {
        Logger.i(pluginApi?.pluginId, "(supergfxctl v" + d.version + "):", ...msg);
    }

    function warn(...msg) {
        Logger.w(pluginApi?.pluginId, "(supergfxctl v" + d.version + "):", ...msg);
    }

    function error(...msg) {
        Logger.e(pluginApi?.pluginId, "(supergfxctl v" + d.version + "):", ...msg);
    }

    QtObject {
        id: d

        property bool available: false
        property string version: ""
        property int mode: Main.SGFXMode.None
        property int power: Main.SGFXPower.Unknown
        property int pendingAction: Main.SGFXAction.Nothing
        property int pendingMode: Main.SGFXMode.None
        property list<int> supportedModes: []

        readonly property var modes: [
            {
                key: "Hybrid",
                label: pluginApi.tr("mode.Hybrid"),
                icon: "chart-circles",
                description: "Both GPUs active"
            },
            {
                key: "Integrated",
                label: pluginApi.tr("mode.Integrated"),
                icon: "cpu",
                description: "iGPU only"
            },
            {
                key: "NvidiaNoModeset",
                label: pluginApi.tr("mode.NvidiaNoModeset"),
                icon: "cpu-off",
                description: "Nvidia without modesetting"
            },
            {
                key: "Vfio",
                label: pluginApi.tr("mode.Vfio"),
                icon: "device-desktop-up",
                description: "GPU passthrough"
            },
            {
                key: "AsusEgpu",
                label: pluginApi.tr("mode.AsusEgpu"),
                icon: "external-link",
                description: "External GPU"
            },
            {
                key: "AsusMuxDgpu",
                label: pluginApi.tr("mode.AsusMuxDgpu"),
                icon: "gauge",
                description: "Direct dGPU via MUX"
            },
            {
                key: "None",
                label: pluginApi.tr("unknown"),
                icon: "question-mark",
                description: "Unknown mode"
            }
        ]

        readonly property var powers: [
            {
                key: "active",
                label: "Active",
                icon: "power"
            },
            {
                key: "suspended",
                label: "Suspended",
                icon: "zzz"
            },
            {
                key: "off",
                label: "Off",
                icon: "power-off"
            },
            {
                key: "dgpu_disabled",
                label: "ASUS Disabled",
                icon: "plug-off"
            },
            {
                key: "asus_mux_discreet",
                label: "ASUS MUX Discreet",
                icon: "gauge"
            },
            {
                key: "unknown",
                label: pluginApi.tr("unknown"),
                icon: "question-mark"
            }
        ]

        readonly property var actions: [
            {
                key: "No action required",
                label: "",
                icon: "circle-check"
            },
            {
                key: "Logout required to complete mode change",
                label: I18n.tr("session-menu.logout") + " " + pluginApi.tr("action.required"),
                icon: "logout"
            },
            {
                key: "Reboot required to complete mode change",
                label: I18n.tr("session-menu.reboot") + " " + pluginApi.tr("action.required"),
                icon: "rotate-clockwise"
            },
            {
                key: "You must switch to Integrated first",
                label: pluginApi.tr("action.switch"),
                icon: "cpu"
            },
            {
                key: "The mode must be switched to Integrated or Hybrid first",
                label: pluginApi.tr("action.disable_egpu"),
                icon: "external-link-off"
            }
        ]

        function findMode(key) {
            return modes.findIndex(m => m.key === key);
        }

        function findPower(key) {
            return powers.findIndex(p => p.key === key);
        }

        function findAction(key) {
            return actions.findIndex(a => a.key === key);
        }

        function isVersionGreater(a: string, b: string): bool {
            return a.localeCompare(b, undefined, {
                numeric: true
            }) === 1;
        }

        function parseOutput(text, flags) {
            const lines = text.trim().split("\n");
            let index = 0;

            function readLine() {
                if (index >= lines.length) {
                    root.warn("supergfxctl: expected more lines for parsing; got only", lines.length);
                    return "";
                }
                return lines[index++].trim();
            }

            const parsers = {
                v: {
                    parse() {
                        d.version = readLine();
                        d.available = true;
                    }
                },
                g: {
                    parse() {
                        d.mode = d.findMode(readLine());
                    }
                },
                s: {
                    parse() {
                        const raw = readLine();
                        const list = raw.replace(/[\[\]]/g, "").split(",").map(s => d.findMode(s.trim())).filter(m => m >= 0);

                        if (!d.isVersionGreater(d.version, "5.2.7") && list.length === 1 && list[0] === Main.SGFXMode.AsusMuxDgpu) {
                            root.warn("detected old supergfxctl bug: adding Integrated + Hybrid to supported modes");
                            list.push(Main.SGFXMode.Integrated, Main.SGFXMode.Hybrid);
                        }

                        d.supportedModes = list;
                    }
                },
                S: {
                    parse() {
                        d.power = d.findPower(readLine());
                    }
                },
                p: {
                    parse() {
                        // this is unreliable after mode switch per https://gitlab.com/asus-linux/asusctl/-/blob/main/rog-control-center/src/notify.rs?ref_type=heads#L361
                        const action = d.findAction(readLine());

                        // only set pending action if it wasnt set before manually
                        if (d.pendingAction === Main.SGFXAction.Nothing) {
                            d.pendingAction = action;
                        }
                    }
                },
                P: {
                    parse() {
                        // this is unreliable after mode switch per https://gitlab.com/asus-linux/asusctl/-/blob/main/rog-control-center/src/notify.rs?ref_type=heads#L361
                        const mode = d.findMode(readLine());

                        // only set pending mode if it wasnt set before manually
                        if (d.pendingMode === Main.SGFXMode.None) {
                            d.pendingMode = mode;
                        }
                    }
                }
            };

            for (const flag of flags) {
                const entry = parsers[flag];

                if (!entry) {
                    root.warn(`supergfxctl: unknown flag '${flag}' — skipping`);
                    continue;
                }

                entry.parse();
            }

            root.log("supergfxctl parsed results:", JSON.stringify({
                version: d.version,
                mode: d.mode,
                supportedModes: d.supportedModes,
                power: d.power,
                pendingAction: d.pendingAction,
                pendingMode: d.pendingMode
            }));
        }

        function determineRequiredAction(newMode: int, currentMode: int): int {
            switch (newMode) {
            case Main.SGFXMode.Hybrid:
                switch (currentMode) {
                case Main.SGFXMode.Integrated:
                case Main.SGFXMode.AsusEgpu:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                case Main.SGFXMode.Vfio:
                    return Main.SGFXAction.SwitchToIntegrated;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.Integrated:
                switch (currentMode) {
                case Main.SGFXMode.Hybrid:
                case Main.SGFXMode.AsusEgpu:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.NvidiaNoModeset:
                switch (currentMode) {
                case Main.SGFXMode.AsusEgpu:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.Vfio:
                switch (currentMode) {
                case Main.SGFXMode.AsusEgpu:
                case Main.SGFXMode.Hybrid:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.AsusEgpu:
                switch (currentMode) {
                case Main.SGFXMode.Integrated:
                case Main.SGFXMode.Hybrid:
                case Main.SGFXMode.NvidiaNoModeset:
                    return Main.SGFXAction.Logout;
                case Main.SGFXMode.Vfio:
                    return Main.SGFXAction.SwitchToIntegrated;
                case Main.SGFXMode.AsusMuxDgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            case Main.SGFXMode.AsusMuxDgpu:
                switch (currentMode) {
                case Main.SGFXMode.Hybrid:
                case Main.SGFXMode.Integrated:
                case Main.SGFXMode.NvidiaNoModeset:
                case Main.SGFXMode.Vfio:
                case Main.SGFXMode.AsusEgpu:
                    return Main.SGFXAction.Reboot;
                default:
                    return Main.SGFXAction.Nothing;
                }
            default:
                return Main.SGFXAction.Nothing;
            }
        }
    }

    Process {
        id: refreshProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const args = refreshProc.command.slice(1);

                // Turn "-vgsP" → ["v","g","s","P"]
                const flags = [].concat.apply([], args.map(a => a.startsWith("-") ? a.slice(1).split("") : []));

                d.parseOutput(text, flags);
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.error("failed to refresh status");
            }
        }
    }

    Process {
        id: setModeProc
        running: false
        onExited: exitCode => {
            // per https://gitlab.com/asus-linux/asusctl/-/blob/main/rog-control-center/src/notify.rs?ref_type=heads#L361
            // this will never provide correct pendingMode/pendingAction results until reboot
            root.refresh();

            if (exitCode !== 0) {
                root.error("failed to set mode");
                d.pendingMode = Main.SGFXMode.None;
                return;
            }

            d.pendingAction = d.determineRequiredAction(d.pendingMode, d.mode);
        }
    }

    Component.onCompleted: refresh()
}
