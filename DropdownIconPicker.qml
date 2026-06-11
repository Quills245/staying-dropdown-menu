import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property string currentIcon: ""
    property bool allowEmpty: false

    signal iconSelected(string iconName)

    width: 240
    height: 32
    radius: Theme.cornerRadius
    color: Theme.surfaceContainer
    border.color: iconPopup.visible ? Theme.primary : Theme.outline
    border.width: 1

    // ── Load the full icon list from DMS's own codepoints file ─────────────

    property var allIcons: []

    FileView {
        path: "/usr/share/quickshell/dms/assets/fonts/material-design-icons/variablefont/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].codepoints"
        blockLoading: true
        onLoaded: {
            const lines = text().split('\n')
            const names = []
            for (let i = 0; i < lines.length; i++) {
                const name = lines[i].trim().split(' ')[0]
                if (name) names.push(name)
            }
            root.allIcons = names
        }
    }

    // ── Curated categories for browsing ────────────────────────────────────

    readonly property var iconCategories: [
        { name: "Common", icons: [
            "expand_circle_down","menu","close","search","settings","home","apps","dashboard",
            "widgets","extension","grid_view","tune","filter_list","sort","view_list","more_vert",
            "more_horiz","drag_handle","open_in_new","launch","link","refresh","sync","swap_vert",
            "add","remove","edit","delete","save","download","upload","share","content_copy",
            "content_paste","undo","redo","send","archive","bookmark","flag","push_pin"
        ]},
        { name: "System & Dev", icons: [
            "terminal","code","bug_report","build","engineering","memory","storage","computer",
            "desktop_windows","laptop","monitor","keyboard","mouse","print","power","power_settings_new",
            "restart_alt","developer_mode","data_object","api","webhook","schema","usb","devices",
            "smart_screen","device_hub","scanner","cast","cast_connected","developer_board",
            "integration_instructions","functions","calculate","science","deployed_code","package_2"
        ]},
        { name: "Security & People", icons: [
            "lock","lock_open","security","shield","vpn_key","key","password","fingerprint",
            "verified_user","admin_panel_settings","person","group","groups","manage_accounts",
            "account_circle","badge","contacts","face","supervisor_account","how_to_reg",
            "gpp_good","policy","https","enhanced_encryption","private_connectivity"
        ]},
        { name: "Files & Network", icons: [
            "folder","folder_open","folder_special","create_new_folder","description","article",
            "note","insert_drive_file","draft","file_copy","picture_as_pdf","image","photo",
            "video_file","audio_file","topic","text_snippet","wifi","wifi_off","router","lan",
            "cloud","cloud_upload","cloud_download","cloud_sync","public","language","dns",
            "rss_feed","cell_tower","signal_wifi_4_bar","network_wifi"
        ]},
        { name: "Media", icons: [
            "play_arrow","pause","stop","skip_next","skip_previous","replay","shuffle","repeat",
            "volume_up","volume_down","volume_off","music_note","library_music","album",
            "queue_music","playlist_play","radio","podcasts","mic","mic_off","headphones",
            "speaker","equalizer","movie","videocam","video_library","live_tv","tv",
            "photo_camera","subtitles","hd","screen_share","graphic_eq","surround_sound"
        ]},
        { name: "Communication", icons: [
            "mail","mail_outline","inbox","send","reply","reply_all","chat","message","sms",
            "forum","comment","feedback","contact_mail","call","call_end","video_call",
            "notifications","notifications_active","notifications_off","campaign","announcement",
            "mark_email_read","chat_bubble","voicemail","contacts","drafts"
        ]},
        { name: "Status & Time", icons: [
            "check","check_circle","cancel","error","warning","info","help","done","done_all",
            "pending","schedule","update","history","access_time","timer","alarm","event",
            "today","calendar_today","calendar_month","date_range","hourglass_empty",
            "offline_bolt","visibility","visibility_off","circle","toggle_on","toggle_off",
            "timelapse","watch_later","event_available","alarm_on"
        ]},
        { name: "Appearance & Tools", icons: [
            "palette","color_lens","brush","format_paint","gradient","blur_on","style","draw",
            "edit_note","font_download","text_format","format_size","dark_mode","light_mode",
            "brightness_high","brightness_low","contrast","invert_colors","colorize","wb_sunny",
            "nights_stay","auto_awesome","design_services","build","construction","handyman",
            "settings_applications","tune","manage_search","auto_fix_high","home_repair_service"
        ]},
        { name: "Navigation & Maps", icons: [
            "map","location_on","my_location","directions","navigation","near_me","explore",
            "place","room","pin_drop","flag","tour","hiking","route","fmd_good","share_location",
            "arrow_forward","arrow_back","arrow_upward","arrow_downward","expand_more",
            "expand_less","chevron_right","chevron_left","first_page","last_page","north","south"
        ]},
        { name: "Fun & Misc", icons: [
            "star","star_outline","favorite","favorite_border","thumb_up","thumb_down",
            "emoji_emotions","celebration","cake","local_fire_department","bolt","water","air",
            "eco","pets","park","spa","fitness_center","sports_esports","videogame_asset",
            "auto_awesome","diamond","rocket_launch","nightlife","music_note","sports_soccer",
            "sentiment_very_satisfied","sentiment_satisfied","sentiment_dissatisfied",
            "wb_twilight","toys","casino","piano","light_mode","dark_mode"
        ]}
    ]

    // ── Trigger button ─────────────────────────────────────────────────────

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (iconPopup.visible) { iconPopup.close(); return }
            searchField.text = ""
            const pos = root.mapToItem(Overlay.overlay, 0, 0)
            iconPopup.x = pos.x
            const popupH = 480
            const overlayH = Overlay.overlay?.height ?? 800
            iconPopup.y = (pos.y + root.height + popupH + 4 > overlayH)
                ? pos.y - popupH - 4
                : pos.y + root.height + 4
            iconPopup.open()
            Qt.callLater(() => searchField.forceActiveFocus())
        }
    }

    DankIcon {
        id: leadingIcon
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        name: root.currentIcon || "add"
        size: 16
        color: root.currentIcon ? Theme.surfaceText : Theme.outline
    }

    StyledText {
        anchors.left: leadingIcon.right
        anchors.leftMargin: Theme.spacingS
        anchors.right: trailingControls.left
        anchors.rightMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentIcon || "Choose icon"
        font.pixelSize: Theme.fontSizeSmall
        color: root.currentIcon ? Theme.surfaceText : Theme.outline
        elide: Text.ElideRight
    }

    Row {
        id: trailingControls
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Rectangle {
            width: 18; height: 18; radius: 9
            color: clearIconArea.containsMouse ? Theme.errorHover : "transparent"
            visible: root.currentIcon !== ""
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.centerIn: parent
                name: "close"
                size: 12
                color: clearIconArea.containsMouse ? Theme.error : Theme.outline
            }

            MouseArea {
                id: clearIconArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    mouse.accepted = true
                    root.currentIcon = ""
                    root.iconSelected("")
                }
            }
        }

        DankIcon {
            name: iconPopup.visible ? "expand_less" : "expand_more"
            size: 16
            color: Theme.outline
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Popup ──────────────────────────────────────────────────────────────

    Popup {
        id: iconPopup

        parent: Overlay.overlay
        width: 360
        height: 480
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle { color: "transparent" }

        contentItem: Rectangle {
            color: Theme.surface
            radius: Theme.cornerRadius

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadowStrong
                shadowBlur: 0.8
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 4
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: Theme.spacingS

                // Search row
                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankTextField {
                        id: searchField
                        width: parent.width - (clearSearchBtn.visible ? clearSearchBtn.width + Theme.spacingS : 0)
                        placeholderText: "Search " + root.allIcons.length + " icons…"
                    }

                    Rectangle {
                        id: clearSearchBtn
                        width: 32; height: 32; radius: Theme.cornerRadius
                        color: clearSearchArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                        visible: searchField.text !== ""
                        anchors.verticalCenter: parent.verticalCenter

                        DankIcon { anchors.centerIn: parent; name: "close"; size: 16; color: Theme.surfaceText }

                        MouseArea {
                            id: clearSearchArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchField.text = ""
                        }
                    }
                }

                // Results count hint while searching
                StyledText {
                    visible: searchField.text !== ""
                    text: {
                        const q = searchField.text.toLowerCase()
                        const n = root.allIcons.filter(i => i.includes(q)).length
                        return n + " result" + (n !== 1 ? "s" : "")
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                // Icon grid
                DankFlickable {
                    id: gridScroll
                    width: parent.width
                    height: parent.height - searchField.height
                            - (searchField.text !== "" ? resultCount.height + Theme.spacingS : 0)
                            - manualRow.height - Theme.spacingS * 4
                    contentHeight: gridContent.implicitHeight
                    clip: true

                    // Reset scroll when query changes
                    onContentHeightChanged: contentY = 0

                    Column {
                        id: gridContent
                        width: parent.width
                        spacing: Theme.spacingM

                        // ── Search results (all 4102 icons, filtered) ──────────

                        Flow {
                            width: parent.width
                            spacing: 4
                            visible: searchField.text !== ""

                            Repeater {
                                model: {
                                    const q = searchField.text.toLowerCase()
                                    return q ? root.allIcons.filter(n => n.includes(q)) : []
                                }

                                delegate: IconCell {
                                    required property string modelData
                                    iconName: modelData
                                    selected: root.currentIcon === modelData
                                    onChosen: (n) => { root.currentIcon = n; root.iconSelected(n); iconPopup.close() }
                                }
                            }

                            StyledText {
                                visible: {
                                    const q = searchField.text.toLowerCase()
                                    return q !== "" && root.allIcons.filter(n => n.includes(q)).length === 0
                                }
                                text: "No matches — use the field below to enter any icon name"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: gridContent.width
                                topPadding: Theme.spacingM
                            }
                        }

                        // ── Curated categories (shown when not searching) ──────

                        Repeater {
                            model: root.iconCategories
                            visible: searchField.text === ""

                            Column {
                                required property var modelData
                                width: gridContent.width
                                spacing: Theme.spacingXS
                                visible: searchField.text === ""

                                StyledText {
                                    text: modelData.name
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                Flow {
                                    width: parent.width
                                    spacing: 4

                                    Repeater {
                                        model: modelData.icons

                                        delegate: IconCell {
                                            required property string modelData
                                            iconName: modelData
                                            selected: root.currentIcon === modelData
                                            onChosen: (n) => { root.currentIcon = n; root.iconSelected(n); iconPopup.close() }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Manual name input
                Row {
                    id: manualRow
                    width: parent.width
                    spacing: Theme.spacingS

                    DankTextField {
                        id: manualField
                        width: parent.width - applyBtn.width - Theme.spacingS
                        placeholderText: "Enter any icon name directly…"
                        Keys.onReturnPressed: applyBtn.apply()
                        Keys.onEnterPressed: applyBtn.apply()
                    }

                    Rectangle {
                        id: applyBtn
                        width: 32; height: 32; radius: Theme.cornerRadius
                        color: applyArea.containsMouse ? Theme.primaryHover : Theme.primary
                        anchors.verticalCenter: parent.verticalCenter

                        DankIcon { anchors.centerIn: parent; name: "check"; size: 16; color: Theme.onPrimary }

                        function apply() {
                            const name = manualField.text.trim()
                            if (!name) return
                            root.currentIcon = name
                            root.iconSelected(name)
                            manualField.text = ""
                            iconPopup.close()
                        }

                        MouseArea {
                            id: applyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: applyBtn.apply()
                        }
                    }
                }
            }

            // Invisible item to satisfy the height reference
            Item {
                id: resultCount
                height: Theme.fontSizeSmall + Theme.spacingXS
                visible: false
            }
        }
    }

    // ── Reusable icon cell ─────────────────────────────────────────────────

    component IconCell: Rectangle {
        property string iconName: ""
        property bool selected: false
        signal chosen(string name)

        width: 36; height: 36
        radius: Theme.cornerRadius
        color: cellArea.containsMouse ? Theme.primaryHover : "transparent"
        border.color: selected ? Theme.primary : "transparent"
        border.width: 2

        DankIcon {
            name: parent.iconName
            size: 20
            color: parent.selected ? Theme.primary : Theme.surfaceText
            anchors.centerIn: parent
        }

        DankTooltip {
            visible: cellArea.containsMouse
            text: parent.iconName
        }

        MouseArea {
            id: cellArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.chosen(parent.iconName)
        }

        Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
    }
}
