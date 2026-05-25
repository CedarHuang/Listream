import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Listream.ViewModels 1.0
import Theme 1.0

Dialog {
    id: dialog
    title: ""
    modal: true
    width: 620
    height: 460
    topPadding: 0
    leftPadding: Theme.space6
    rightPadding: Theme.space6
    bottomPadding: Theme.space6

    parent: Overlay.overlay
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    Overlay.modal: Rectangle {
        color: Theme.overlayDim
    }

    background: Rectangle {
        color: Theme.bgOverlay
        radius: Theme.radiusLg
        border.color: Theme.border
        border.width: 1
    }

    function formatUpdateTime(isoStr) {
        if (!isoStr) return "从未更新"
        let now = new Date()
        let then = new Date(isoStr)
        let diffMin = Math.floor((now - then) / 60000)
        if (diffMin < 1) return "刚刚更新"
        if (diffMin < 60) return diffMin + "分钟前更新"
        if (diffMin < 1440) return Math.floor(diffMin / 60) + "小时前更新"
        if (diffMin < 43200) return Math.floor(diffMin / 1440) + "天前更新"
        return Qt.formatDate(then, "yyyy-MM-dd") + " 更新"
    }

    header: Rectangle {
        height: 48
        color: "transparent"

        Label {
            anchors { left: parent.left; leftMargin: Theme.space6; verticalCenter: parent.verticalCenter }
            text: "订阅管理"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeXl
            font.bold: true
        }

        Button {
            id: closeX
            anchors { right: parent.right; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            width: 28; height: 28
            flat: true
            hoverEnabled: true
            contentItem: Text {
                text: "×"
                color: closeX.hovered ? Theme.textPrimary : Theme.textSecondary
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: closeX.hovered ? Theme.bgHover : "transparent"
                radius: Theme.radiusSm
            }
            onClicked: dialog.close()
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.space3

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space3

            TextField {
                id: nameField
                Layout.preferredWidth: 120
                placeholderText: "名称"
                placeholderTextColor: Theme.textMuted
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMd
                background: Rectangle {
                    implicitHeight: 30
                    color: Theme.bgField
                    radius: Theme.radiusMd
                    border.width: 1
                    border.color: nameField.activeFocus ? Theme.accent : Theme.border
                }
            }

            Item {
                id: capsule
                Layout.fillWidth: true
                implicitHeight: 30
                property int protoIndex: 0
                readonly property var protoLabels: ["https://", "http://", "file:///"]

                Rectangle {
                    anchors.fill: parent
                    color: Theme.bgField
                    radius: Theme.radiusMd
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        id: protoBtn
                        Layout.fillHeight: true
                        implicitWidth: protoText.implicitWidth + Theme.space3 * 2
                        color: protoHover.containsMouse ? Theme.bgHover : "transparent"
                        radius: Theme.radiusMd
                        topRightRadius: 0
                        bottomRightRadius: 0

                        Behavior on color {
                            ColorAnimation { duration: Theme.animFast }
                        }

                        Text {
                            id: protoText
                            anchors.centerIn: parent
                            text: capsule.protoLabels[capsule.protoIndex]
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeSm
                        }

                        MouseArea {
                            id: protoHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var pt = protoBtn.mapToItem(dialog.contentItem, 0, protoBtn.height + 4)
                                protoMenu.x = pt.x
                                protoMenu.y = pt.y
                                protoMenu.open()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.topMargin: 7
                        Layout.bottomMargin: 7
                        implicitWidth: 1
                        color: Theme.border
                    }

                    TextField {
                        id: urlField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: capsule.protoIndex === 2 ? "本地文件路径" : "远端订阅地址"
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeMd
                        background: Rectangle {
                            color: "transparent"
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: Theme.radiusMd
                    border.width: 1
                    border.color: urlField.activeFocus ? Theme.accent : Theme.border
                }
            }

            Popup {
                id: protoMenu
                padding: 2
                background: Rectangle {
                    color: Theme.bgSurface
                    radius: Theme.radiusMd
                    border.color: Theme.border
                    border.width: 1
                }
                contentItem: ListView {
                    id: protoList
                    implicitWidth: 80
                    implicitHeight: contentItem.childrenRect.height
                    spacing: 1
                    model: capsule.protoLabels
                    delegate: ItemDelegate {
                        id: protoDelegate
                        width: protoList.width
                        height: 26
                        hoverEnabled: true
                        contentItem: Text {
                            text: modelData
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeSm
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: Theme.space3
                        }
                        background: Rectangle {
                            color: protoDelegate.hovered ? Theme.bgHover : "transparent"
                            radius: Theme.radiusSm
                        }
                        onClicked: {
                            capsule.protoIndex = index
                            protoMenu.close()
                        }
                    }
                }
            }

            Button {
                id: browseBtn
                visible: capsule.protoIndex === 2
                text: "浏览"
                font.pixelSize: Theme.fontSizeMd
                hoverEnabled: true
                contentItem: Text {
                    text: browseBtn.text
                    color: browseBtn.hovered ? Theme.textPrimary : Theme.textSecondary
                    font: browseBtn.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: browseBtn.hovered ? Theme.bgHover : "transparent"
                    radius: Theme.radiusSm
                    border.width: 1
                    border.color: Theme.border
                    implicitWidth: 56
                    implicitHeight: 30
                }
                onClicked: fileDialog.open()
            }

            Button {
                id: addBtn
                text: AppBackend.busy ? "添加中..." : "添加"
                font.pixelSize: Theme.fontSizeMd
                enabled: !AppBackend.busy && urlField.text !== ""
                hoverEnabled: true
                contentItem: Text {
                    text: addBtn.text
                    color: Theme.textOnAccent
                    font: addBtn.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: addBtn.enabled ? 1.0 : 0.5
                }
                background: Rectangle {
                    color: addBtn.enabled ? (addBtn.hovered ? Theme.accentHover : Theme.accent) : Theme.bgHover
                    radius: Theme.radiusSm
                    implicitWidth: 72
                    implicitHeight: 30
                }
                onClicked: {
                    let url = urlField.text.trim()
                    if (!/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(url)) {
                        url = capsule.protoLabels[capsule.protoIndex] + url
                    }
                    AppBackend.addSubscription(nameField.text, url)
                    nameField.text = ""
                    urlField.text = ""
                }
            }
        }

        ListView {
            id: subListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: SubscriptionListModel
            spacing: 0
            reuseItems: true

            move: Transition {
                SmoothedAnimation { property: "y"; duration: 250; easing.type: Easing.OutCubic }
            }
            displaced: Transition {
                SmoothedAnimation { property: "y"; duration: 250; easing.type: Easing.OutCubic }
            }

            delegate: Rectangle {
                id: row
                width: subListView.width
                height: 53
                color: row.editing ? Theme.bgField : "transparent"
                property bool editing: false

                HoverHandler {
                    id: hoverHandler
                }

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space2
                    anchors.rightMargin: Theme.space2
                    spacing: Theme.space2

                    ToggleSwitch {
                        id: enabledSwitch
                        checked: model.enabled !== undefined ? model.enabled : true
                        enabled: !model.refreshing
                        Layout.preferredWidth: 40
                        onToggled: AppBackend.setSubscriptionEnabled(model.subId, enabledSwitch.checked)
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Column {
                            width: parent.width
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                visible: !row.editing
                                text: model.subName
                                color: enabledSwitch.checked ? Theme.textPrimary : Theme.textDisabled
                                font.pixelSize: Theme.fontSizeMd
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: !row.editing
                                text: model.subUrl
                                color: enabledSwitch.checked ? Theme.textSecondary : Theme.textDisabled
                                font.pixelSize: Theme.fontSizeXs
                                elide: Text.ElideMiddle
                            }

                            Text {
                                visible: !row.editing
                                text: model.channelCount + " 个 · " + formatUpdateTime(model.lastUpdated)
                                color: Theme.textMuted
                                font.pixelSize: Theme.fontSizeXxs
                            }

                            TextField {
                                id: editName
                                visible: row.editing
                                text: model.subName
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeMd
                                font.bold: true
                                background: Rectangle { color: Theme.bgSurface; radius: Theme.radiusMd }
                            }

                            TextField {
                                id: editUrl
                                visible: row.editing
                                text: model.subUrl
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeXs
                                background: Rectangle { color: Theme.bgSurface; radius: Theme.radiusMd }
                            }
                        }
                    }

                    Item {
                        visible: !row.editing && hoverHandler.hovered
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 30
                        Layout.alignment: Qt.AlignVCenter

                        Item {
                            id: upArrow
                            visible: index > 0
                            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                            width: 18; height: 14
                            opacity: model.refreshing ? 0.35 : 1.0
                            property color arrowColor: upHover.containsMouse ? Theme.accent : Theme.textSecondary

                            Rectangle {
                                width: 6; height: 1.5
                                color: upArrow.arrowColor
                                antialiasing: true
                                rotation: -35
                                anchors { right: parent.horizontalCenter; rightMargin: -1; verticalCenter: parent.verticalCenter; verticalCenterOffset: 1 }
                            }
                            Rectangle {
                                width: 6; height: 1.5
                                color: upArrow.arrowColor
                                antialiasing: true
                                rotation: 35
                                anchors { left: parent.horizontalCenter; leftMargin: -1; verticalCenter: parent.verticalCenter; verticalCenterOffset: 1 }
                            }

                            MouseArea {
                                id: upHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !model.refreshing
                                onClicked: AppBackend.moveSubscription(index, index - 1)
                            }
                        }

                        Item {
                            id: downArrow
                            visible: index < subListView.count - 1
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: 18; height: 14
                            opacity: model.refreshing ? 0.35 : 1.0
                            property color arrowColor: downHover.containsMouse ? Theme.accent : Theme.textSecondary

                            Rectangle {
                                width: 6; height: 1.5
                                color: downArrow.arrowColor
                                antialiasing: true
                                rotation: 35
                                anchors { right: parent.horizontalCenter; rightMargin: -1; verticalCenter: parent.verticalCenter; verticalCenterOffset: -1 }
                            }
                            Rectangle {
                                width: 6; height: 1.5
                                color: downArrow.arrowColor
                                antialiasing: true
                                rotation: -35
                                anchors { left: parent.horizontalCenter; leftMargin: -1; verticalCenter: parent.verticalCenter; verticalCenterOffset: -1 }
                            }

                            MouseArea {
                                id: downHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !model.refreshing
                                onClicked: AppBackend.moveSubscription(index, index + 1)
                            }
                        }
                    }

                    RefreshButton {
                        visible: !row.editing
                        implicitWidth: 24; implicitHeight: 24
                        enabled: !model.refreshing
                        running: model.refreshing
                        onClicked: AppBackend.refreshSubscription(model.subId)
                    }

                    TextButton {
                        visible: !row.editing
                        text: "编辑"
                        textColor: Theme.accent
                        font.pixelSize: Theme.fontSizeSm
                        enabled: !model.refreshing
                        leftPadding: Theme.space2; rightPadding: Theme.space2
                        onClicked: {
                            row.editing = true
                            editName.text = model.subName
                            editUrl.text = model.subUrl
                        }
                    }

                    TextButton {
                        visible: !row.editing
                        text: "删除"
                        textColor: Theme.error
                        font.pixelSize: Theme.fontSizeSm
                        enabled: !model.refreshing
                        leftPadding: Theme.space2; rightPadding: Theme.space2
                        onClicked: confirmDelete.open()
                    }

                    TextButton {
                        visible: row.editing
                        text: "保存"
                        textColor: Theme.success
                        font.pixelSize: Theme.fontSizeSm
                        enabled: editUrl.text !== ""
                        leftPadding: Theme.space2; rightPadding: Theme.space2
                        onClicked: {
                            AppBackend.updateSubscription(model.subId, editName.text, editUrl.text)
                            row.editing = false
                        }
                    }

                    TextButton {
                        visible: row.editing
                        text: "取消"
                        textColor: Theme.textMuted
                        font.pixelSize: Theme.fontSizeSm
                        leftPadding: Theme.space2; rightPadding: Theme.space2
                        onClicked: {
                            editName.text = model.subName
                            editUrl.text = model.subUrl
                            row.editing = false
                        }
                    }

                    Dialog {
                        id: confirmDelete
                        title: ""
                        modal: true
                        width: 360
                        topPadding: Theme.space6
                        leftPadding: Theme.space6
                        rightPadding: Theme.space6
                        bottomPadding: Theme.space6

                        parent: Overlay.overlay
                        implicitHeight: topPadding + contentItem.implicitHeight + bottomPadding

                        x: parent ? (parent.width - width) / 2 : 0
                        y: parent ? (parent.height - height) / 2 : 0

                        Overlay.modal: Rectangle {
                            color: Theme.overlayDim
                        }

                        background: Rectangle {
                            color: Theme.bgOverlay
                            radius: Theme.radiusLg
                            border.color: Theme.border
                            border.width: 1
                        }

                        contentItem: ColumnLayout {
                            spacing: Theme.space4

                            Label {
                                text: "确认删除"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeXl
                                font.bold: true
                            }

                            Label {
                                text: "删除订阅 \"" + model.subName + "\" 及其所有频道？\n此操作不可撤销。"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeMd
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                Layout.topMargin: Theme.space2
                                spacing: Theme.space3

                                TextButton {
                                    text: "取消"
                                    textColor: Theme.textSecondary
                                    font.pixelSize: Theme.fontSizeMd
                                    onClicked: confirmDelete.close()
                                }

                                Button {
                                    id: delBtn
                                    text: "删除"
                                    font.pixelSize: Theme.fontSizeMd
                                    hoverEnabled: true
                                    contentItem: Text {
                                        text: delBtn.text
                                        color: Theme.textOnAccent
                                        font: delBtn.font
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: delBtn.hovered ? Theme.errorHover : Theme.error
                                        radius: Theme.radiusSm
                                        implicitWidth: 72
                                        implicitHeight: 34
                                    }
                                    onClicked: {
                                        AppBackend.removeSubscription(model.subId)
                                        confirmDelete.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "选择 M3U 文件"
        fileMode: FileDialog.OpenFile
        nameFilters: ["M3U 播放列表 (*.m3u *.m3u8)", "所有文件 (*)"]
        onAccepted: {
            var raw = selectedFile.toString()
            urlField.text = raw.startsWith("file:///") ? raw.substring(8) : raw
        }
    }
}
