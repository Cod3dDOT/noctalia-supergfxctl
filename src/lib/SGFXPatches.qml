/*
 * supergfxctl helper for patching
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

import QtQuick

import "SemVer.js"

QtObject {
    // patched up version of pending actions for mode switch
    // TODO: this WILL differ depending on hardware (maybe fw versions?)
    // NOTE: supergfxctl has an option to force reboot to deal with finicky hw
    readonly property var _pendingActionMatrix: ({
            [SGFX.Mode.Hybrid]: ({
                    [SGFX.Mode.Integrated]: SGFX.Action.Logout,
                    [SGFX.Mode.AsusEgpu]: SGFX.Action.Logout,
                    [SGFX.Mode.AsusMuxDgpu]: SGFX.Action.Logout,
                    [SGFX.Mode.Vfio]: SGFX.Action.SwitchToIntegrated
                }),
            [SGFX.Mode.Integrated]: ({
                    [SGFX.Mode.Hybrid]: SGFX.Action.Logout,
                    [SGFX.Mode.AsusEgpu]: SGFX.Action.Logout,
                    [SGFX.Mode.AsusMuxDgpu]: SGFX.Action.Reboot
                }),
            [SGFX.Mode.NvidiaNoModeset]: ({
                    [SGFX.Mode.AsusEgpu]: SGFX.Action.Logout,
                    [SGFX.Mode.AsusMuxDgpu]: SGFX.Action.Reboot
                }),
            [SGFX.Mode.Vfio]: ({
                    [SGFX.Mode.AsusEgpu]: SGFX.Action.Logout,
                    [SGFX.Mode.Hybrid]: SGFX.Action.Logout,
                    [SGFX.Mode.AsusMuxDgpu]: SGFX.Action.Reboot
                }),
            [SGFX.Mode.AsusEgpu]: ({
                    [SGFX.Mode.Integrated]: SGFX.Action.Logout,
                    [SGFX.Mode.Hybrid]: SGFX.Action.Logout,
                    [SGFX.Mode.NvidiaNoModeset]: SGFX.Action.Logout,
                    [SGFX.Mode.Vfio]: SGFX.Action.SwitchToIntegrated,
                    [SGFX.Mode.AsusMuxDgpu]: SGFX.Action.Reboot
                }),
            [SGFX.Mode.AsusMuxDgpu]: ({
                    [SGFX.Mode.Integrated]: SGFX.Action.Reboot,
                    [SGFX.Mode.Hybrid]: SGFX.Action.Reboot,
                    [SGFX.Mode.NvidiaNoModeset]: SGFX.Action.Reboot,
                    [SGFX.Mode.Vfio]: SGFX.Action.SwitchToIntegrated,
                    [SGFX.Mode.AsusMuxDgpu]: SGFX.Action.Reboot
                })
        })

    function guessPendingAction(currentMode: int, pendingMode: int): int {
        const row = _pendingActionMatrix[pendingMode];
        return row?.[currentMode] ?? SGFX.Action.Nothing;
    }

    readonly property var _patches: [
        {
            name: "Supergfxctl Mux Bug (MR #44)",
            condition: version => !SemVer.isVersionGreater(version, "5.2.7"),
            apply: () => {
                console.warn("Applying patch: Adding missing Integrated and Hybrid modes");
                if (!modeEnums.includes(SGFX.Mode.Integrated))
                    modeEnums.push(SGFX.Mode.Integrated);
                if (!modeEnums.includes(SGFX.Mode.Hybrid))
                    modeEnums.push(SGFX.Mode.Hybrid);
            }
        }
    ]

    /**
     * Executes all applicable patches based on the current environment.
     * @param {string} sgfxVersion - supergfxctl version.
     */
    function applyPatches(options) {
        _patches.forEach(patch => {
            if (patch.condition(sgfxVersion)) {
                patch.apply();
            }
        });
    }
}
