import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0

Dialog {
    id: dialog
    title: "订阅管理"
    modal: true
    standardButtons: Dialog.Close
    width: 600
    height: 450

    background: Rectangle {
        color: "#1e1e2e"
        border.color: "#313244"
    }

    header: Label {
        text: "订阅管理"
        color: "#cdd6f4"
        font.pixelSize: 16
        padding: 16
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: nameField
                Layout.preferredWidth: 120
                placeholderText: "名称"
                placeholderTextColor: "#6c7086"
                color: "#cdd6f4"
                background: Rectangle { color: "#313244"; radius: 4 }
            }

            TextField {
                id: urlField
                Layout.fillWidth: true
                placeholderText: "M3U 地址"
                placeholderTextColor: "#6c7086"
                color: "#cdd6f4"
                background: Rectangle { color: "#313244"; radius: 4 }
            }

            Button {
                text: "添加"
                palette.buttonText: "#cdd6f4"
                background: Rectangle { color: "#45475a"; radius: 4; implicitWidth: 60; implicitHeight: 34 }
                enabled: nameField.text !== "" && urlField.text !== ""
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

            delegate: Rectangle {
                id: row
                width: subListView.width
                height: 36
                color: index % 2 === 0 ? "#1e1e2e" : "#181825"
                property bool editing: false

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Switch {
                        id: enabledSwitch
                        checked: model.enabled !== undefined ? model.enabled : true
                        palette.button: "#45475a"
                        Layout.preferredWidth: 40
                        onToggled: AppBackend.setSubscriptionEnabled(model.subId, checked)
                    }

                    // 显示模式
                    Text {
                        visible: !row.editing
                        Layout.preferredWidth: 90
                        text: model.subName
                        color: enabledSwitch.checked ? "#cdd6f4" : "#6c7086"
                        elide: Text.ElideRight
                        font.pixelSize: 13
                    }

                    Text {
                        visible: !row.editing
                        Layout.fillWidth: true
                        text: model.subUrl
                        color: enabledSwitch.checked ? "#6c7086" : "#45475a"
                        elide: Text.ElideMiddle
                        font.pixelSize: 12
                    }

                    // 编辑模式
                    TextField {
                        id: editName
                        visible: row.editing
                        Layout.preferredWidth: 90
                        text: model.subName
                        color: "#cdd6f4"
                        font.pixelSize: 12
                        background: Rectangle { color: "#313244"; radius: 4 }
                    }

                    TextField {
                        id: editUrl
                        visible: row.editing
                        Layout.fillWidth: true
                        text: model.subUrl
                        color: "#cdd6f4"
                        font.pixelSize: 12
                        background: Rectangle { color: "#313244"; radius: 4 }
                    }

                    Text {
                        Layout.preferredWidth: 45
                        text: model.channelCount + " 个"
                        color: "#a6adc8"
                        font.pixelSize: 12
                    }

                    Button {
                        visible: !row.editing
                        text: "编辑"
                        flat: true
                        palette.buttonText: "#89b4fa"
                        font.pixelSize: 12
                        onClicked: {
                            row.editing = true
                            editName.text = model.subName
                            editUrl.text = model.subUrl
                        }
                    }

                    Button {
                        visible: row.editing
                        text: "保存"
                        flat: true
                        palette.buttonText: "#a6e3a1"
                        font.pixelSize: 12
                        enabled: editName.text !== "" && editUrl.text !== ""
                        onClicked: {
                            AppBackend.updateSubscription(model.subId, editName.text, editUrl.text)
                            row.editing = false
                        }
                    }

                    Button {
                        visible: row.editing
                        text: "取消"
                        flat: true
                        palette.buttonText: "#6c7086"
                        font.pixelSize: 12
                        onClicked: row.editing = false
                    }

                    Button {
                        visible: !row.editing
                        text: "刷新"
                        flat: true
                        palette.buttonText: "#89b4fa"
                        font.pixelSize: 12
                        onClicked: AppBackend.refreshSubscription(model.subId)
                    }

                    Button {
                        text: "删除"
                        flat: true
                        palette.buttonText: "#f38ba8"
                        font.pixelSize: 12
                        onClicked: AppBackend.removeSubscription(model.subId)
                    }
                }
            }
        }
    }
}
