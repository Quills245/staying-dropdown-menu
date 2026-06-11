import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string variantId: ""
    property var variantData: null
    property var popoutService: null

    // Re-read variantData directly when plugin data changes
    Connections {
        target: pluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== root.pluginId || root.variantId === "") return
            const fresh = pluginService.getPluginVariantData(root.pluginId, root.variantId)
            if (fresh) root.variantData = fresh
        }
    }

    readonly property string pillIcon:    variantData?.icon        || "expand_circle_down"
    readonly property string pillText:    variantData?.text        || ""
    readonly property string pillDisplay: variantData?.pillDisplay || "both"
    readonly property var    menuItems:   variantData?.items       ?? []

    readonly property bool pillShowIcon:  pillDisplay !== "text"
    readonly property bool pillShowLabel: pillDisplay !== "icon" && pillText !== ""

    popoutWidth: 280
    popoutHeight: Math.max(64, menuItems.length * 48 + 16)

    // ── Horizontal bar pill ──────────────────────────────────────────────────

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.pillIcon
                size: root.iconSize
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                visible: root.pillShowIcon
            }

            StyledText {
                text: root.pillText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                visible: root.pillShowLabel
            }

            DankIcon {
                name: "expand_more"
                size: root.iconSize - 8
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ── Vertical bar pill ────────────────────────────────────────────────────

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.pillIcon
                size: root.iconSize
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.pillShowIcon
            }

            StyledText {
                text: root.pillText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                visible: root.pillShowLabel
            }

            DankIcon {
                name: "expand_more"
                size: root.iconSize - 8
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // ── Popout (dropdown) content ────────────────────────────────────────────

    popoutContent: Component {
        PopoutComponent {
            showCloseButton: false

            Process {
                id: actionProcess
                running: false
            }

            Column {
                width: parent.width
                spacing: 2
                topPadding: Theme.spacingS
                bottomPadding: Theme.spacingS

                Repeater {
                    model: root.menuItems

                    delegate: DropdownItem {
                        required property var modelData
                        required property int index

                        width: parent.width
                        item: modelData
                        display: modelData.display || "both"
                        pluginService: root.pluginService
                        popoutService: root.popoutService

                        onExecuteAction: (command) => {
                            actionProcess.command = ["sh", "-c", command]
                            actionProcess.running = true
                            root.closePopout()
                        }

                        onExecutePlugin: (pluginId) => {
                            root._triggerPlugin(pluginId)
                            root.closePopout()
                        }

                        onExecutePopout: (widgetId) => {
                            root.closePopout()
                            const ok = BarWidgetService.triggerWidgetPopout(widgetId)
                            if (!ok)
                                ToastService.showWarning(widgetId + " isn't on the bar — add it to a bar to open its popout")
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    text: "No items configured"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Theme.spacingM
                    bottomPadding: Theme.spacingM
                    visible: root.menuItems.length === 0
                }
            }
        }
    }

    // ── Plugin trigger dispatch ──────────────────────────────────────────────

    readonly property var _builtinPlugins: ({
        "controlCenter":       () => popoutService?.toggleControlCenter(),
        "notificationCenter":  () => popoutService?.toggleNotificationCenter(),
        "appDrawer":           () => popoutService?.toggleAppDrawer(),
        "processList":         () => popoutService?.toggleProcessList(),
        "battery":             () => popoutService?.toggleBattery(),
        "vpn":                 () => popoutService?.toggleVpn(),
        "systemUpdate":        () => popoutService?.toggleSystemUpdate(),
        "settings":            () => popoutService?.openSettings(),
        "clipboardHistory":    () => popoutService?.openClipboardHistory(),
        "spotlight":           () => popoutService?.toggleDankLauncherV2(),
        "powerMenu":           () => popoutService?.togglePowerMenu(),
        "colorPicker":         () => popoutService?.showColorPicker(),
        "notepad":             () => popoutService?.toggleNotepad()
    })

    function _triggerPlugin(pluginId) {
        const builtin = _builtinPlugins[pluginId]
        if (builtin) builtin()
        else if (pluginService) pluginService.togglePlugin(pluginId)
    }
}
