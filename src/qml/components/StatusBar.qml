import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0
import Theme 1.0

Rectangle {
    height: 28
    color: Theme.bgWindow

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: Theme.border
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.space3
        spacing: Theme.space2

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8; height: 8
            radius: Theme.radiusSm
            color: {
                switch (PlayerController.status) {
                    case "playing": return Theme.success
                    case "loading": return Theme.warning
                    case "error": return Theme.error
                    default: return Theme.textMuted
                }
            }
            visible: PlayerController.status !== "idle" && PlayerController.status !== "stopped"
        }

        Text {
            text: PlayerController.title ? "▶ " + PlayerController.title : "未播放"
            color: PlayerController.title ? Theme.success : Theme.textMuted
            font.pixelSize: Theme.fontSizeSm
        }

        Text {
            text: {
                var st = PlayerController.status
                if (st === "loading") return "连接中..."
                if (st === "buffering") return "缓冲中..."
                if (st === "playing") return "播放中"
                if (st === "paused") return "已暂停"
                if (st.startsWith("error")) return "播放错误"
                return ""
            }
            color: {
                if (PlayerController.status.startsWith("error")) return Theme.error
                return Theme.textSecondary
            }
            font.pixelSize: Theme.fontSizeSm
            visible: PlayerController.status !== "idle" && PlayerController.status !== "stopped"
        }

        Text {
            text: {
                var parts = []
                if (PlayerController.cacheDuration > 0)
                    parts.push("缓存 " + PlayerController.cacheDuration.toFixed(1) + "s")
                if (PlayerController.cacheSpeed > 0)
                    parts.push("↓ " + (PlayerController.cacheSpeed / 1024).toFixed(0) + " KB/s")
                return parts.join(" · ")
            }
            color: Theme.textMuted
            font.pixelSize: Theme.fontSizeSm
            visible: text !== "" && PlayerController.status !== "idle" && PlayerController.status !== "stopped"
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.space3
        spacing: Theme.space2

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "音量"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSizeSm
        }

        Slider {
            id: volSlider
            width: 100
            from: 0; to: 100
            value: PlayerController.volume * 100
            onValueChanged: PlayerController.volume = value / 100
            onPressedChanged: if (!pressed) PlayerController.save_volume()

            background: Rectangle {
                x: volSlider.leftPadding
                y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                implicitWidth: 100; implicitHeight: 4
                width: volSlider.availableWidth; height: implicitHeight
                radius: 2
                color: Theme.bgField

                Rectangle {
                    width: volSlider.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                }
            }

            handle: Rectangle {
                x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                implicitWidth: 12; implicitHeight: 12
                radius: 6
                color: volSlider.pressed ? Theme.accentHover : Theme.accent
            }

            ToolTip {
                parent: volSlider.handle
                visible: volSlider.pressed
                text: Math.round(volSlider.value)
            }
        }
    }
}
