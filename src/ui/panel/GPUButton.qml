/*
 * GPU button for the panel
 *
 * SPDX-FileCopyrightText: 2025-2026 cod3ddot@proton.me
 * SPDX-License-Identifier: MIT
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

import ".."

Rectangle {
    id: root

    required property string label
    required property int mode
    required property int currentMode
    required property int pendingMode

    property bool enabled: true
    property bool supported: true
    readonly property bool hovered: mouse.hovered

    signal click

    readonly property bool _interactive: {
        // make sure that we can only switch back to current mode
        // this is useful because it allows us to "cancel"
        // the switch
        // TODO: investigate how supergfxctl behaves after switching back and
        // forth without performing necessary steps (pending action) to apply the mode switch
        const current = currentMode === mode;
        const pending = pendingMode === mode;

        return enabled && !pending && !current;
    }

    readonly property color textColor: {
        if (!enabled) {
            return Color.mOutline;
        }

        if (hovered) {
            return Color.mTertiary;
        }

        if (pendingMode === mode) {
            return Color.mOnTertiary;
        }

        if (currentMode === mode) {
            return Color.mOnPrimary;
        }

        return Color.mPrimary;
    }

    readonly property color backgroundColor: {
        if (!enabled) {
            return Qt.lighter(Color.mSurfaceVariant, 1.2);
        }

        if (hovered) {
            return "transparent";
        }

        if (pendingMode === mode) {
            return Color.mTertiary;
        }

        if (currentMode === mode) {
            return Color.mPrimary;
        }

        // non-current default
        return "transparent";
    }

    readonly property color borderColor: {
        if (!enabled) {
            return Color.mOutline;
        }

        if (pendingMode === mode || hovered) {
            return Color.mTertiary;
        }

        return Color.mPrimary;
    }

    readonly property ColorAnimation animationBehaviour: ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCubic
    }

    implicitWidth: contentRow.implicitWidth + (Style.marginL * 2)
    implicitHeight: contentRow.implicitHeight + (Style.marginL * 2)

    radius: Style.iRadiusS
    color: backgroundColor
    border.width: Style.borderM
    border.color: borderColor

    opacity: enabled ? 1.0 : 0.6

    Behavior on color {
        animation: root.animationBehaviour
    }

    Behavior on border.color {
        animation: root.animationBehaviour
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Style.marginXS

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIcon.qml
        NIcon {
            icon: Icons.getModeIcon(root.mode)
            pointSize: Style.fontSizeL
            color: root.textColor

            Behavior on color {
                animation: root.animationBehaviour
            }
        }

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
        NText {
            text: root.label
            pointSize: Style.fontSizeM
            font.weight: Style.fontWeightBold
            color: root.textColor

            Behavior on color {
                animation: root.animationBehaviour
            }
        }
    }

    TapHandler {
        enabled: root._interactive
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.click
    }

    HoverHandler {
        id: mouse
        enabled: root._interactive
        cursorShape: Qt.PointingHandCursor
    }
}
