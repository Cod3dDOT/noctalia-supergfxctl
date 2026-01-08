/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick

import Quickshell

import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.Noctalia

/**
	Controll center showing the current GPU mode, with an optional badge when a pending
	action is available.

	Left click to open the plugin panel
 */
// https://github.com/noctalia-dev/noctalia-shell/blob/main/Modules/Bar/Extras/BarPill.qml
NIconButton {
    id: root

    property ShellScreen screen

    // Plugin API (injected by PluginPanelSlot)
    property QtObject pluginApi: null
    readonly property QtObject pluginCore: pluginApi?.mainInstance

    readonly property string currentIcon: pluginCore?.getModeIcon(pluginCore.mode) ?? ""
    readonly property string currentLabel: pluginCore?.getModeLabel(pluginCore.mode) ?? ""

    opacity: root.pluginCore?.available ? 1.0 : 0.5
    icon: root.currentIcon
    tooltipText: {
        if (!root.pluginCore?.hasPendingAction) {
            return root.currentLabel;
        }
        const pendingActionLabel = root.pluginCore?.hasPendingAction ? root.pluginCore?.getActionLabel(root.pluginCore.pendingAction) : "";
        return root.currentLabel + " | " + pendingActionLabel;
    }

    onClicked: root.pluginApi?.openPanel(root.screen)

    Rectangle {
        id: badge
        visible: root.pluginCore?.hasPendingAction
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 2
        anchors.topMargin: 1
        z: 2
        height: 8
        width: 8
        radius: Style.radiusXS
        color: Color.mTertiary
        border.color: Color.mSurface
        border.width: Style.borderS
    }
}
