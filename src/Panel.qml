/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.Noctalia

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth: 500 * Style.uiScaleRatio
    property real contentPreferredHeight: 200 * Style.uiScaleRatio

    anchors.fill: parent

    readonly property var supergfxctl: pluginApi.mainInstance

    readonly property var currentMode: supergfxctl.modeInfo(supergfxctl.mode)
    readonly property var pendingAction: supergfxctl.actionInfo(supergfxctl.pendingAction)

    component GPUButton: NButton {
        property int modeEnum: Main.Mode.None
        readonly property var info: root.supergfxctl.modeInfo(modeEnum)

        Layout.fillWidth: true
        Layout.preferredHeight: 50

        enabled: root.supergfxctl.supportedModes.includes(modeEnum)
        outlined: modeEnum !== root.supergfxctl.mode
        border.width: Style.borderM
        text: info.label
        icon: info.icon

        onClicked: root.supergfxctl.setMode(modeEnum)
    }

    component Header: NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: header.implicitHeight + Style.marginM * 2

        RowLayout {
            id: header
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NIcon {
                icon: currentMode.icon
                pointSize: Style.fontSizeXXL
                color: Color.mPrimary
            }

            NText {
                text: root.pluginApi.tr("gpu")
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
                Layout.fillWidth: true
            }

            NIconButtonHot {
                icon: root.pendingAction.icon
                baseSize: Style.baseWidgetSize * 0.8
                color: Color.mError
                hot: true
                tooltipText: root.pendingAction.label

                visible: root.supergfxctl.hasPendingAction
            }

            NIconButton {
                icon: "refresh"
                tooltipText: I18n.tr("tooltips.refresh")
                baseSize: Style.baseWidgetSize * 0.8
                enabled: root.supergfxctl.available
                onClicked: root.supergfxctl.refresh()
            }

            NIconButton {
                icon: "close"
                tooltipText: I18n.tr("tooltips.close")
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: root.pluginApi.closePanel(root.screen)
            }
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.transparent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL

            Header {}

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.marginM + 50
                spacing: Style.marginM

                GPUButton {
                    modeEnum: Main.SGFXMode.Integrated
                }
                GPUButton {
                    modeEnum: Main.SGFXMode.Hybrid
                }
                GPUButton {
                    modeEnum: Main.SGFXMode.AsusMuxDgpu
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                GPUButton {
                    modeEnum: Main.SGFXMode.AsusEgpu
                }
                GPUButton {
                    modeEnum: Main.SGFXMode.Vfio
                }
            }
        }
    }
}
