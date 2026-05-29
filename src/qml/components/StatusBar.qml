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
        id: statusRow
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

            FloatingTip {
                text: "画质增强 " + (PlayerController.vfEnabled ? "开" : "关")
                visible: vfIconMouse.containsMouse
                container: statusRow
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
            hoverEnabled: true
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

            FloatingTip {
                target: volSlider.handle
                text: Math.round(volSlider.value)
                visible: volSlider.hovered || volSlider.pressed
                container: statusRow
            }
        }

        Item {
            id: afColumn
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            width: afIcon.width
            height: afIcon.height + 2

            Text {
                id: afIcon
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "≈"
                color: PlayerController.afEnabled ? Theme.accent : Theme.textMuted
                font.pixelSize: Theme.fontSizeXxl
            }

            Row {
                id: afDotsRow
                y: afIcon.font.pixelSize + 1
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        property int threshold: (index + 1) * 2
                        width: 2.5; height: 2.5
                        radius: 1.25
                        color: {
                            if (!PlayerController.afEnabled) return Theme.textMuted
                            return PlayerController.afMaxGain >= threshold ? Theme.accent : Theme.textMuted
                        }
                    }
                }
            }

            MouseArea {
                id: afIconMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PlayerController.cycleAfGain()
                hoverEnabled: true
            }

            FloatingTip {
                text: {
                    if (!PlayerController.afEnabled) return "响度均衡 关"
                    var g = PlayerController.afMaxGain
                    if (g === 2) return "响度均衡 低"
                    if (g === 4) return "响度均衡 中"
                    if (g === 6) return "响度均衡 高"
                    return "响度均衡"
                }
                visible: afIconMouse.containsMouse
                container: statusRow
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 14
            color: Theme.border
        }

        Text {
            id: metaIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "ⓘ"
            color: PlayerController.showMeta ? Theme.accent : Theme.textMuted
            font.pixelSize: Theme.fontSizeLg

            MouseArea {
                id: metaIconMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PlayerController.toggleMeta()
                hoverEnabled: true
            }

            FloatingTip {
                text: "视频信息 " + (PlayerController.showMeta ? "开" : "关")
                visible: metaIconMouse.containsMouse
                container: statusRow
            }
        }
    }
}
