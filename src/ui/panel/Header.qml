/*
 * Panel header
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

import "../../lib"
import ".."

NBox {
    id: root

    required property string title

    property bool busy: false

    property int currentMode: SGFX.Mode.None
    property int pendingAction: SGFX.SGFXAction.Nothing
    property string pendingActionLabel: ""

    signal pendingActionClick
    signal close
    signal refresh

    Layout.fillWidth: true
    Layout.preferredHeight: headerRow.implicitHeight + Style.marginM * 2

    RowLayout {
        id: headerRow
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIcon.qml
        NIcon {
            icon: Icons.getModeIcon(root.currentMode)
            pointSize: Style.fontSizeXXL
            color: Color.mPrimary
        }

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
        NText {
            Layout.fillWidth: true
            text: root.title
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
        }

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
        NIconButton {
            icon: Icons.getActionIcon(root.pendingAction)
            tooltipText: root.pendingActionLabel
            baseSize: Style.baseWidgetSize * 0.8
            visible: root.pendingAction != null && root.pendingAction !== SGFX.SGFXAction.Nothing
            onClicked: root.pendingActionClick
        }

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
        NIconButton {
            id: refreshButton
            icon: "refresh"
            tooltipText: I18n.tr("tooltips.refresh")
            baseSize: Style.baseWidgetSize * 0.8
            enabled: !root.busy
            onClicked: root.refresh

            RotationAnimation {
                id: rotationAnimator
                target: refreshButton
                property: "rotation"
                to: 360
                duration: 2000
                loops: Animation.Infinite
                running: root.busy
            }
        }

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
        NIconButton {
            icon: "close"
            tooltipText: I18n.tr("tooltips.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: root.close
        }
    }
}
