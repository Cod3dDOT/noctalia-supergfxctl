/*
 * Panel UI
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.Noctalia

import "lib"
import "ui/panel"

Item {
    id: root

    // Plugin API (injected by PluginPanelSlot)
    property QtObject pluginApi: null
    readonly property QtObject pluginCore: pluginApi?.mainInstance

    // SmartPanel properties (required for panel behavior)
    readonly property Rectangle geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    readonly property int contentPreferredWidth: 420 * Style.uiScaleRatio
    readonly property int contentPreferredHeight: 170 * Style.uiScaleRatio

    anchors.fill: parent

    component PanelGPUButton: GPUButton {
        Layout.fillWidth: true

        label: root.pluginCore?.getModeLabel(this.mode) ?? ""

        currentMode: root.pluginCore?.mode ?? SGFX.Mode.None
        pendingMode: root.pluginCore?.pendingMode ?? SGFX.Mode.None

        supported: root.pluginCore.isModeSupported(this.mode) ?? false
        enabled: root.pluginCore?.available && !root.pluginCore?.busy && this.supported

        onClick: root.pluginCore?.setMode(this.mode)
    }

    component PanelHeader: Header {
        title: root.pluginCore?.tr("gpu") ?? "GPU"

        currentMode: root.pluginCore?.mode ?? SGFX.Mode.None
        pendingAction: root.pluginCore?.pendingAction ?? SGFX.SGFXAction.Nothing
        pendingActionLabel: root.pluginCore?.getActionLabel(this.pendingAction) ?? ""

        busy: (root.pluginCore?.busy || !root.pluginCore.available) ?? false

        // TODO: why does screen simply work here?
        // shouldnt we call pluginApi.withCurrentScreen?
        onPendingActionClick: root.pluginApi?.withCurrentScreen(screen => {
            PanelService.getPanel("sessionMenuPanel", screen)?.toggle();
        })
        onClose: root.pluginApi?.withCurrentScreen(screen => {
            root.pluginApi?.closePanel(screen);
        })
        onRefresh: root.pluginCore?.refresh()
    }

    Rectangle {
        id: panelContainer
        x: Style.marginM
        y: Style.marginM
        color: "transparent"

        ColumnLayout {
            spacing: Style.marginM

            PanelHeader {}

            RowLayout {
                spacing: Style.marginM

                PanelGPUButton {
                    mode: SGFX.Mode.Integrated
                }
                PanelGPUButton {
                    mode: SGFX.Mode.Hybrid
                }
                PanelGPUButton {
                    mode: SGFX.Mode.AsusMuxDgpu
                }
            }

            RowLayout {
                spacing: Style.marginM

                PanelGPUButton {
                    mode: SGFX.Mode.AsusEgpu
                }
                PanelGPUButton {
                    mode: SGFX.Mode.Vfio
                }
            }
        }
    }
}
