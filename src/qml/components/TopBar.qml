import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0

Rectangle {
    id: bar
    height: 40
    color: "#11111b"

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 8

        Button {
            text: "订阅管理"
            flat: true
            font.pixelSize: 13
            palette.buttonText: "#cdd6f4"
            onClicked: subDialog.open()
        }

        Button {
            text: "全部刷新"
            flat: true
            font.pixelSize: 13
            palette.buttonText: "#cdd6f4"
            onClicked: AppBackend.refreshAll()
        }
    }

    SubscriptionDialog { id: subDialog }
}
