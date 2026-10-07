import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0
import Theme 1.0

Rectangle {
    id: bar
    height: Theme.space10
    color: Theme.bgWindow

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
    }

    MouseArea {
        anchors.fill: parent
        property point clickPos: "0,0"
        property bool _suppressDrag: false

        onPressed: (mouse) => {
            _suppressDrag = false
            clickPos = Qt.point(mouse.x, mouse.y)
        }
        onPositionChanged: (mouse) => {
            if (_suppressDrag) return
            var dx = mouse.x - clickPos.x
            var dy = mouse.y - clickPos.y
            if (Math.abs(dx) < 4 && Math.abs(dy) < 4) return
            var win = bar.Window.window

            if (!WindowState.windowed) {
                if (Math.abs(dy) < 10) return
                // 最大化/全屏 → 脱离为 Windowed（尺寸由 WindowState 按记忆几何恢复），
                // 再按光标锚点定位。全屏下拖拽同样退出全屏。
                var fracX = mouse.x / bar.width
                var pressCursor = WindowState.cursorPos()
                WindowState.beginDragMove()
                clickPos = Qt.point(fracX * win.width, mouse.y)
                win.x = pressCursor.x - clickPos.x
                win.y = pressCursor.y - clickPos.y
                return
            }

            var dragCursor = WindowState.cursorPos()
            win.x = dragCursor.x - clickPos.x
            win.y = dragCursor.y - clickPos.y
        }
        onDoubleClicked: {
            _suppressDrag = true
            WindowState.toggleMaximized()  // 全屏时由状态机自行决定退回进全屏前的模式
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.space3
        spacing: Theme.space2

        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/assets/icon.svg"
            sourceSize.width: 20
            sourceSize.height: 20
            width: 20
            height: 20
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Listream"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeLg
            font.bold: true
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1; height: 16
            color: Theme.borderLight
        }

        TextButton {
            text: "订阅管理"
            font.pixelSize: Theme.fontSizeMd
            onClicked: subDialog.open()
        }

        TextButton {
            text: "设置"
            font.pixelSize: Theme.fontSizeMd
            onClicked: settingsDialog.open()
        }

        TextButton {
            text: "关于"
            font.pixelSize: Theme.fontSizeMd
            onClicked: aboutDialog.open()
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 0
        spacing: 0

        Button {
            id: minBtn
            // 命中区占满标题栏高度：最大化后屏幕顶边即窗口顶边，
            // 鼠标甩到右上角（Fitts 定律）必须能命中，不能留顶部死区。
            width: 46; height: bar.height
            hoverEnabled: true
            flat: true
            padding: 0
            background: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    color: minBtn.hovered ? Theme.bgHover : "transparent"
                    radius: Theme.radiusSm
                }
            }
            onClicked: WindowState.minimize()
            contentItem: Item {
                Canvas {
                    anchors.centerIn: parent
                    width: 12; height: 12
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = Theme.textPrimary; ctx.lineWidth = 1.5
                        ctx.beginPath()
                        ctx.moveTo(2, 10); ctx.lineTo(10, 10)
                        ctx.stroke()
                    }
                }
            }
        }

        Button {
            id: maxBtn
            width: 46; height: bar.height
            hoverEnabled: true
            flat: true
            padding: 0
            background: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    color: maxBtn.hovered ? Theme.bgHover : "transparent"
                    radius: Theme.radiusSm
                }
            }
            onClicked: WindowState.toggleMaximized()
            contentItem: Item {
                Canvas {
                    anchors.centerIn: parent
                    width: 12; height: 12
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = Theme.textPrimary; ctx.lineWidth = 1.5
                        ctx.beginPath()
                        ctx.rect(2, 3, 8, 7)
                        ctx.stroke()
                    }
                }
            }
        }

        Button {
            id: closeBtn
            width: 46; height: bar.height
            hoverEnabled: true
            flat: true
            padding: 0
            background: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    color: closeBtn.hovered ? Theme.error : "transparent"
                    radius: Theme.radiusSm
                }
            }
            onClicked: bar.Window.window.close()
            contentItem: Item {
                Canvas {
                    anchors.centerIn: parent
                    width: 12; height: 12
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = closeBtn.hovered ? Theme.textOnAccent : Theme.textPrimary
                        ctx.lineWidth = 1.5
                        ctx.beginPath()
                        ctx.moveTo(2, 2); ctx.lineTo(10, 10)
                        ctx.moveTo(10, 2); ctx.lineTo(2, 10)
                        ctx.stroke()
                    }
                }
            }
        }
    }

    SubscriptionDialog { id: subDialog }
    SettingsDialog { id: settingsDialog }
    AboutDialog { id: aboutDialog }
}
