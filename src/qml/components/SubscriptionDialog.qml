import QtQuick
import QtQuick.Controls
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
                    color: Theme.bgField
                    radius: Theme.radiusMd
                    border.width: 1
                    border.color: nameField.activeFocus ? Theme.accent : Theme.border
                }
            }

            TextField {
                id: urlField
                Layout.fillWidth: true
                placeholderText: "M3U 地址"
                placeholderTextColor: Theme.textMuted
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMd
                background: Rectangle {
                    color: Theme.bgField
                    radius: Theme.radiusMd
                    border.width: 1
                    border.color: urlField.activeFocus ? Theme.accent : Theme.border
                }
            }

            Button {
                id: addBtn
                text: AppBackend.busy ? "添加中..." : "添加"
                font.pixelSize: Theme.fontSizeMd
                enabled: !AppBackend.busy && nameField.text !== "" && urlField.text !== ""
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
                    implicitHeight: 34
                }
                onClicked: {
                    AppBackend.addSubscription(nameField.text, urlField.text)
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

            delegate: Rectangle {
                id: row
                width: subListView.width
                height: 53
                color: row.editing ? Theme.bgField : (itemHover.hovered ? Theme.bgHover : "transparent")
                property bool editing: false

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                MouseArea {
                    id: itemHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
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
                    spacing: Theme.space3

                    Switch {
                        id: enabledSwitch
                        checked: model.enabled !== undefined ? model.enabled : true
                        palette.button: Theme.bgHover
                        Layout.preferredWidth: 40
                        onToggled: AppBackend.setSubscriptionEnabled(model.subId, checked)
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

                    Text {
                        text: model.channelCount + " 个"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSm
                        Layout.preferredWidth: 40
                    }

                    TextButton {
                        visible: !row.editing
                        text: "编辑"
                        textColor: Theme.accent
                        font.pixelSize: Theme.fontSizeSm
                        onClicked: {
                            row.editing = true
                            editName.text = model.subName
                            editUrl.text = model.subUrl
                        }
                    }

                    TextButton {
                        visible: !row.editing
                        text: "刷新"
                        textColor: Theme.accent
                        font.pixelSize: Theme.fontSizeSm
                        enabled: !AppBackend.busy
                        onClicked: AppBackend.refreshSubscription(model.subId)
                    }

                    TextButton {
                        visible: !row.editing
                        text: "删除"
                        textColor: Theme.error
                        font.pixelSize: Theme.fontSizeSm
                        onClicked: confirmDelete.open()
                    }

                    TextButton {
                        visible: row.editing
                        text: "保存"
                        textColor: Theme.success
                        font.pixelSize: Theme.fontSizeSm
                        enabled: editName.text !== "" && editUrl.text !== ""
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
}
