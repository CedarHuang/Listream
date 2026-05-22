import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0

Dialog {
    id: dialog
    title: "订阅管理"
    modal: true
    standardButtons: Dialog.Close
    width: 500
    height: 400

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
                width: subListView.width
                height: 36
                color: index % 2 === 0 ? "#1e1e2e" : "#181825"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4

                    Text {
                        Layout.preferredWidth: 100
                        text: subName
                        color: "#cdd6f4"
                        elide: Text.ElideRight
                        font.pixelSize: 13
                    }

                    Text {
                        Layout.fillWidth: true
                        text: subUrl
                        color: "#6c7086"
                        elide: Text.ElideMiddle
                        font.pixelSize: 12
                    }

                    Text {
                        Layout.preferredWidth: 50
                        text: channelCount + " 个"
                        color: "#a6adc8"
                        font.pixelSize: 12
                    }

                    Button {
                        text: "刷新"
                        flat: true
                        palette.buttonText: "#89b4fa"
                        font.pixelSize: 12
                        onClicked: AppBackend.refreshSubscription(subId)
                    }

                    Button {
                        text: "删除"
                        flat: true
                        palette.buttonText: "#f38ba8"
                        font.pixelSize: 12
                        onClicked: AppBackend.removeSubscription(subId)
                    }
                }
            }
        }
    }
}
