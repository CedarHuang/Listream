import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0
import Listream.QmlItems 1.0

Rectangle {
    id: pane
    color: "#000000"

    MpvRenderer {
        id: mpvRenderer
        objectName: "mpvRenderer"
        anchors.fill: parent
        Component.onCompleted: AppBackend.setRenderer(mpvRenderer)
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        visible: PlayerController.status === "idle" || PlayerController.status === "stopped"

        Column {
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "选择一个频道开始播放"
                color: "#6c7086"
                font.pixelSize: 16
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: AppBackend.lastChannelName !== ""
                text: "上次观看: " + AppBackend.lastChannelName
                color: "#a6adc8"
                font.pixelSize: 13
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: AppBackend.lastChannelUrl !== ""
                text: "继续播放"
                flat: true
                palette.buttonText: "#89b4fa"
                onClicked: AppBackend.playChannel(AppBackend.lastChannelUrl, AppBackend.lastChannelName)
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 200; height: 60
        radius: 8
        color: "#313244"
        visible: PlayerController.status === "loading"

        Row {
            anchors.centerIn: parent
            spacing: 10
            Text { text: "加载中..."; color: "#cdd6f4"; font.pixelSize: 14 }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        enabled: PlayerController.status === "playing" || PlayerController.status === "paused"
        onClicked: PlayerController.togglePause()
    }
}
