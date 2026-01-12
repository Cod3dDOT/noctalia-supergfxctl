/*
 * Icons helper singleton
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

pragma Singleton

import Quickshell

import QtQuick

import "../lib"

Singleton {
    function getModeIcon(mode: int): string {
        switch (mode) {
        case SGFX.Mode.Integrated:
            return "cpu";
        case SGFX.Mode.Hybrid:
            return "chart-circles";
        case SGFX.Mode.AsusMuxDgpu:
            return "gauge";
        case SGFX.Mode.NvidiaNoModeset:
            return "cpu-off";
        case SGFX.Mode.Vfio:
            return "device-desktop-up";
        case SGFX.Mode.AsusEgpu:
            return "external-link";
        default:
            return "question-mark";
        }
    }

    function getActionIcon(action: int): string {
        switch (action) {
        case SGFX.SGFXAction.Logout:
            return "logout";
        case SGFX.SGFXAction.Reboot:
            return "reload";
        case SGFX.SGFXAction.SwitchToIntegrated:
            return "cpu";
        case SGFX.SGFXAction.AsusEgpuDisable:
            return "external-link-off";
        case SGFX.SGFXAction.Nothing:
        default:
            return "check";
        }
    }
}
