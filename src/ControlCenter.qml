/*
 * Control center shortcut showing the current GPU mode.
 * Shows a badge when a pending action is available.
 *
 * Left click to open the plugin panel.
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

import QtQuick

import Quickshell

import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.Noctalia

import "ui"

// https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
NIconButton {
    id: root

    property ShellScreen screen

    // Plugin API (injected by PluginPanelSlot)
    property QtObject pluginApi: null
    readonly property QtObject pluginCore: pluginApi?.mainInstance

    readonly property string currentIcon: Icons.getModeIcon(pluginCore?.mode)

    opacity: root.pluginCore?.available ? 1.0 : 0.5
    icon: root.currentIcon
    tooltipText: root.pluginCore?.getTooltip() ?? ""

    onClicked: root.pluginApi?.openPanel(root.screen, undefined)

    IconBadge {
        visible: root.pluginCore?.hasPendingAction ?? false
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 2
        anchors.topMargin: 1
    }
}
