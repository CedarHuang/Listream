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
            id: vfIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "◎"
            color: PlayerController.vfEnabled ? Theme.accent : Theme.textMuted
            font.pixelSize: Theme.fontSizeXxl

            MouseArea {
                id: vfIconMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PlayerController.vfEnabled = !PlayerController.vfEnabled
                hoverEnabled: true
            }

            ToolTip {
                parent: vfIcon
                visible: vfIconMouse.containsMouse
                text: "画质增强 " + (PlayerController.vfEnabled ? "开" : "关")
                delay: 200
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 14
            color: Theme.border
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: PlayerController.muted ? "🔇" : "🔊"
            color: PlayerController.muted ? Theme.error : Theme.textMuted
            font.pixelSize: Theme.fontSizeLg

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PlayerController.muted = !PlayerController.muted
            }
        }

        Slider {
            id: volSlider
            anchors.verticalCenter: parent.verticalCenter
            width: 100
            from: 0; to: 100
            value: PlayerController.volume
            onMoved: PlayerController.volume = Math.round(value)
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
                visible: volSlider.hovered || volSlider.pressed
                text: Math.round(volSlider.value)
                delay: 200
            }
        }

        Text {
            id: afIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "≈"
            color: PlayerController.afEnabled ? Theme.accent : Theme.textMuted
            font.pixelSize: Theme.fontSizeXxl

            MouseArea {
                id: afIconMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PlayerController.afEnabled = !PlayerController.afEnabled
                hoverEnabled: true
            }

            ToolTip {
                parent: afIcon
                visible: afIconMouse.containsMouse
                text: "响度均衡 " + (PlayerController.afEnabled ? "开" : "关")
                delay: 200
            }
        }
    }
}
