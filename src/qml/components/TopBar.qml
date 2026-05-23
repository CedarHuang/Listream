import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0
import Theme 1.0

Rectangle {
    id: bar
    height: Theme.space10
    color: Theme.bgWindow

    MouseArea {
        anchors.fill: parent
        property point clickPos: "0,0"

        onPressed: (mouse) => {
            clickPos = Qt.point(mouse.x, mouse.y)
        }
        onPositionChanged: (mouse) => {
            var dx = mouse.x - clickPos.x
            var dy = mouse.y - clickPos.y
            if (Math.abs(dx) < 4 && Math.abs(dy) < 4) return
            var win = bar.Window.window
            if (win.visibility === Window.Maximized || win.visibility === Window.FullScreen) {
                var nr = AppBackend.getWindowRect()
                if (Object.keys(nr).length === 0) return
                if (Math.abs(dy) < 10) return
                var fracX = mouse.x / bar.width
                var c = AppBackend.getCursorPos()
                win.visibility = Window.Windowed
                win.width = nr.w
                win.height = nr.h
                win.x = c.x - fracX * nr.w
                win.y = c.y - mouse.y
                clickPos = Qt.point(fracX * nr.w, mouse.y)
                return
            }
            var c = AppBackend.getCursorPos()
            win.x = c.x - clickPos.x
            win.y = c.y - clickPos.y
        }
        onDoubleClicked: {
            var win = bar.Window.window
            if (win.visibility === Window.FullScreen) {
                win.exitFullscreen()
            } else if (win.visibility === Window.Maximized) {
                win.visibility = Window.Windowed
            } else {
                AppBackend.saveWindowRect(win.x, win.y, win.width, win.height)
                win.visibility = Window.Maximized
            }
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
            text: AppBackend.busy ? "刷新中..." : "全部刷新"
            font.pixelSize: Theme.fontSizeMd
            enabled: !AppBackend.busy
            onClicked: AppBackend.refreshAll()
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
            width: 46; height: 32
            hoverEnabled: true
            flat: true
            padding: 0
            background: Rectangle {
                color: minBtn.hovered ? Theme.bgHover : "transparent"
                radius: Theme.radiusSm
            }
            onClicked: bar.Window.window.showMinimized()
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
            width: 46; height: 32
            hoverEnabled: true
            flat: true
            padding: 0
            background: Rectangle {
                color: maxBtn.hovered ? Theme.bgHover : "transparent"
                radius: Theme.radiusSm
            }
            onClicked: {
                var win = bar.Window.window
                if (win.visibility === Window.Maximized) win.showNormal()
                else {
                    AppBackend.saveWindowRect(win.x, win.y, win.width, win.height)
                    win.showMaximized()
                }
            }
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
            width: 46; height: 32
            hoverEnabled: true
            flat: true
            padding: 0
            background: Rectangle {
                color: closeBtn.hovered ? Theme.error : "transparent"
                radius: Theme.radiusSm
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
