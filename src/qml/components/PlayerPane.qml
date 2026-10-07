import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0
import Listream.QmlItems 1.0
import Theme 1.0

Rectangle {
    color: Theme.bgPlayer

    Loader {
        id: mpvLoader
        anchors.fill: parent
        active: false
        sourceComponent: MpvRenderer {
            objectName: "mpvRenderer"
            anchors.fill: parent
            Component.onCompleted: AppBackend.setRenderer(this)
        }
    }

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: mpvLoader.active = true
    }

    Rectangle {
        anchors.fill: parent
        visible: PlayerController.status === "idle" || PlayerController.status === "stopped"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bgWindow }
            GradientStop { position: 1.0; color: Theme.bgPlayer }
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.space4

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/assets/icon.svg"
                sourceSize.width: 48
                sourceSize.height: 48
                width: 48
                height: 48
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "选择一个频道开始播放"
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeXl
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: AppBackend.lastChannelName !== ""
                text: "上次观看: " + AppBackend.lastChannelName
                color: Theme.textMuted
                font.pixelSize: Theme.fontSizeMd
            }

            TextButton {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: AppBackend.lastChannelUrl !== ""
                text: "继续播放"
                textColor: Theme.accent
                font.pixelSize: Theme.fontSizeMd
                onClicked: AppBackend.playChannel(AppBackend.lastChannelUrl, AppBackend.lastChannelName)
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 100; height: 100
        radius: Theme.radiusLg
        color: Theme.bgOverlay
        opacity: 0.92
        visible: PlayerController.status === "loading" || PlayerController.status === "buffering"

        Column {
            anchors.centerIn: parent
            spacing: Theme.space3
            BusyIndicator {
                id: spinner
                anchors.horizontalCenter: parent.horizontalCenter
                palette.dark: Theme.accent
                running: true
            }
            Text {
                text: PlayerController.status === "loading" ? "连接中..." : "缓冲中..."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeMd
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: PlayerController.status.startsWith("error")
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bgWindow }
            GradientStop { position: 1.0; color: Theme.bgPlayer }
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.space4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "播放失败"
                color: Theme.error
                font.pixelSize: Theme.fontSizeXl
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: PlayerController.title !== ""
                text: PlayerController.title
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeMd
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "该频道暂时无法播放，可能是源已离线或网络异常。"
                color: Theme.textMuted
                font.pixelSize: Theme.fontSizeSm
            }

            TextButton {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: PlayerController.currentUrl !== ""
                text: "重试"
                textColor: Theme.accent
                font.pixelSize: Theme.fontSizeMd
                onClicked: AppBackend.playChannel(PlayerController.currentUrl, PlayerController.title)
            }
        }
    }

    MetaOverlay {}

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        enabled: PlayerController.status === "playing" || PlayerController.status === "paused"
        onDoubleClicked: WindowState.toggleFullscreen()
    }
}
