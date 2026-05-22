import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0

Rectangle {
    height: 28
    color: "#11111b"

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 16

        Text {
            text: PlayerController.title ? "▶ " + PlayerController.title : "未播放"
            color: PlayerController.title ? "#a6e3a1" : "#6c7086"
            font.pixelSize: 12
        }

        Text {
            text: {
                switch (PlayerController.status) {
                    case "loading": return "缓冲中..."
                    case "playing": return "播放中"
                    case "paused": return "已暂停"
                    case "error": return "播放错误"
                    default: return ""
                }
            }
            color: "#a6adc8"
            font.pixelSize: 12
            visible: PlayerController.status !== "idle"
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 12
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "音量"
            color: "#6c7086"
            font.pixelSize: 12
        }

        Slider {
            id: volSlider
            width: 100
            from: 0; to: 100
            value: PlayerController.volume * 100
            onValueChanged: PlayerController.volume = value / 100
        }
    }
}
