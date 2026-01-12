/*
 * supergfxctl helper singleton
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

pragma Singleton

import QtQuick

import Quickshell

Singleton {
    enum Mode {
        Integrated,
        Hybrid,
        AsusMuxDgpu,
        NvidiaNoModeset,
        Vfio,
        AsusEgpu,
        None
    }

    enum Action {
        Logout,
        Reboot,
        SwitchToIntegrated,
        AsusEgpuDisable,
        Nothing
    }

    property bool available: false
    property string version: "???"
    property int mode: SGFX.Mode.None
    property int pendingAction: SGFX.Action.Nothing
    property int pendingMode: SGFX.Mode.None
    property int supportedModesMask: 0

    readonly property var _modeStringValues: ({
            "Integrated": SGFX.Mode.Integrated,
            "Hybrid": SGFX.Mode.Hybrid,
            "AsusMuxDgpu": SGFX.Mode.AsusMuxDgpu,
            "NvidiaNoModeset": SGFX.Mode.NvidiaNoModeset,
            "Vfio": SGFX.Mode.Vfio,
            "AsusEgpu": SGFX.Mode.AsusEgpu,
            "None": SGFX.Mode.None
        })

    readonly property var _modeStringValuesReversed: Object.entries(_modeStringValues).reduce((obj, item) => (obj[item[1]] = item[0]) && obj, {})

    function isValidMode(v: int): bool {
        return _modeStringValuesReversed.hasOwnProperty(v);
    }

    function modeFromString(message: string): int {
        return _modeStringValues[message];
    }

    function modeToString(v: int): string {
        return _modeStringValuesReversed[v];
    }

    function actionFromString(message: string): int {
        switch (message) {
        case "Logout required to complete mode change":
            return SGFX.Action.Logout;
        case "Reboot required to complete mode change":
            return SGFX.Action.Reboot;
        case "You must switch to Integrated first":
            return SGFX.Action.SwitchToIntegrated;
        case "The mode must be switched to Integrated or Hybrid first":
            return SGFX.Action.AsusEgpuDisable;
        case "No action required":
            return SGFX.Action.Nothing;
        default:
            return SGFX.Action.Nothing;
        }
    }

    function parseOutput(text: string): bool {
        root.log("[parseOutput] start");

        if (text == "") {
            available = false;
            return available;
        }

        const lines = text.split("\n");

        if (lines.length != 5) {
            available = false;
            return available;
        }

        const lineVersion = lines[0] || "???";
        const lineMode = lines[1] || "None";
        const lineSupported = lines[2] || "[]";
        const linePendAction = lines[3] || "No action required";
        let linePendMode = lines[4] || "";

        // set version as soon as possible
        // mainly so that .log functions print correct version
        version = lineVersion;

        root.log(`[parseOutput] version=${lineVersion}, mode=${lineMode}, pendingMode=${linePendMode}, pendingAction=${linePendAction}`);

        if (linePendMode === "Unknown") {
            linePendMode = "None";
        }

        const newMode = modeEnum[lineMode] ?? SGFX.Mode.None;
        const newPendingMode = modeEnum[linePendMode] ?? SGFX.Mode.None;
        const newPendingAction = actionFromString(linePendAction);

        let newSupportedMask = 0;
        if (lineSupported.length > 2) {
            const trimmed = lineSupported.substring(1, lineSupported.length - 1);
            const modeNames = trimmed.split(",");
            const modeEnums = modeNames.map(name => modeEnum[name.trim()] ?? SGFX.Mode.None).filter(m => m >= 0);

            // for versions < 5.2.7, add Integrated and Hybrid if current mode is AsusMuxDgpu
            // https://gitlab.com/asus-linux/supergfxctl/-/merge_requests/44
            if (!SemVer.isVersionGreater(lineVersion, "5.2.7") && newMode === SGFX.Mode.AsusMuxDgpu) {
                root.warn("fixing supergfxctl bug [merge request #44]: adding missing Integrated and Hybrid modes");

                if (!modeEnums.includes(SGFX.Mode.Integrated))
                    modeEnums.push(SGFX.Mode.Integrated);
                if (!modeEnums.includes(SGFX.Mode.Hybrid))
                    modeEnums.push(SGFX.Mode.Hybrid);
            }

            for (let i = 0; i < modeEnums.length; i++) {
                newSupportedMask |= 1 << modeEnums[i];
            }
        } else {
            root.warn("[parseOutput] no supported modes reported");
        }

        supportedModesMask = newSupportedMask;

        if (!root.pluginSettings.supergfxctl.patchPending) {
            mode = newMode;
            pendingMode = newPendingMode;
            pendingAction = newPendingAction;
        } else {
            // only set if pending mode has not been set manually
            // generally, this is the case when launch supergfxctl for the first time
            // and there is a pending mode
            if (pendingMode === SGFX.Mode.None) {
                mode = newMode;
                pendingMode = newPendingMode;
                pendingAction = SGFXPatches.guessPendingAction(mode, newPendingMode);
                root.log("[parseOutput] state updated:", `mode=${mode}, pendingMode=${pendingMode}, pendingAction=${pendingAction}`);
            } else {
                root.log("[parseOutput] pending mode already set manually, skipping mode update");
            }
        }

        available = true;

        root.log(`[parseOutput] completed successfully (available=${available}, supportedMask=0x${newSupportedMask.toString(16)})`);

        return available;
    }

    function setMode(modeEnum: int): bool {
        if (!isValidMode(modeEnum)) {
            root.error("tried setting mode to invalid int", modeEnum);
            return false;
        }

        // manually set pending mode
        // pending action will be set on process exit if it was successfull
        if (root.pluginSettings.supergfxctl.patchPending) {
            pendingMode = modeEnum;
        }
        root.setModeProc.command = ["supergfxctl", "--mode", modeEnumReversed[modeEnum]];
        root.setModeProc.running = true;

        if (root.pluginSettings.debug) {
            root.log(`Setting mode ${modeEnum}`);
        }

        return true;
    }

    function refresh(): void {
        if (root.pluginSettings.debug) {
            root.log("refreshing...");
        }
        refreshProc.running = true;
    }
}
