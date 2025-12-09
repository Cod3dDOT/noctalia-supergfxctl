/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import QtQuick

import Quickshell

import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Services.Noctalia

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string density: Settings.data.bar.density
    readonly property bool isBarVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"

    readonly property var supergfxctl: pluginApi.mainInstance

    readonly property var currentMode: supergfxctl.modeInfo(supergfxctl.mode)

    implicitWidth: pill.width
    implicitHeight: pill.height

    BarPill {
        id: pill
        opacity: root.supergfxctl.available ? 1 : 0.5
        screen: root.screen
        density: root.density
        oppositeDirection: BarService.getPillDirection(root)
        icon: root.currentMode.icon
        autoHide: false
        forceOpen: !root.isBarVertical
        forceClose: root.isBarVertical
        onClicked: root.pluginApi.openPanel(root.screen)
        tooltipText: {
            if (!root.supergfxctl.available) {
                return "";
            }

            let tooltip = root.currentMode.label;
            if (root.supergfxctl.hasPendingAction) {
                const label = root.supergfxctl.actionInfo(root.supergfxctl.pendingAction).label;
                tooltip += " | " + label;
            }

            return tooltip;
        }

        onRightClicked: {
            var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
            if (popupMenuWindow) {
                popupMenuWindow.showContextMenu(contextMenu);
                const pos = BarService.getContextMenuPosition(pill, contextMenu.implicitWidth, contextMenu.implicitHeight);
                contextMenu.openAtItem(pill, pos.x, pos.y);
            }
        }

        Loader {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 2
            anchors.topMargin: 1
            z: 2
            active: root.supergfxctl.hasPendingAction
            sourceComponent: Rectangle {
                id: badge
                height: 8
                width: height
                radius: Style.radiusXS
                color: Color.mError
                border.color: Color.mSurface
                border.width: Style.borderS
            }
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: {
            let items = [];

            items.push({
                "label": "Current: " + root.currentMode.label,
                "action": "current",
                "icon": root.currentMode.icon,
                "enabled": false
            });

            items.push({
                "label": "Open Panel",
                "action": "open-panel",
                "icon": "external-link"
            });

            items.push({
                "label": "Refresh Status",
                "action": "refresh",
                "icon": "refresh"
            });

            items.push({
                "label": I18n.tr("context-menu.widget-settings"),
                "action": "widget-settings",
                "icon": "settings"
            });

            return items;
        }

        onTriggered: action => {
            var popupMenuWindow = PanelService.getPopupMenuWindow(root.screen);
            if (popupMenuWindow) {
                popupMenuWindow.close();
            }

            if (action === "widget-settings") {
                BarService.openWidgetSettings(root.screen, root.section, root.sectionWidgetIndex, root.widgetId);
            } else if (action === "open-panel") {
                root.pluginApi.openPanel(root.screen);
            } else if (action === "refresh") {
                root.supergfxctl.refresh();
            }
        }
    }
}
