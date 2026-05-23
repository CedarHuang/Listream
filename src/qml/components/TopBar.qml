import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0

Rectangle {
    id: bar
    height: 40
    color: "#11111b"

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
            if (win.visibility === Window.Maximized || win.visibility === Window.FullScreen) {
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
        anchors.leftMargin: 12
        spacing: 8

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
            color: "#cdd6f4"
            font.pixelSize: 14
            font.bold: true
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1; height: 16
            color: "#45475a"
        }

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

        Button {
            text: "设置"
            flat: true
            font.pixelSize: 13
            palette.buttonText: "#cdd6f4"
            onClicked: settingsDialog.open()
        }

        Button {
            text: "关于"
            flat: true
            font.pixelSize: 13
            palette.buttonText: "#cdd6f4"
            onClicked: aboutDialog.open()
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 4
        spacing: 0

        Button {
            text: "—"
            flat: true
            font.pixelSize: 13
            palette.buttonText: "#cdd6f4"
            onClicked: bar.Window.window.showMinimized()
        }
        Button {
            text: "□"
            flat: true
            font.pixelSize: 13
            palette.buttonText: "#cdd6f4"
            onClicked: {
                var win = bar.Window.window
                if (win.visibility === Window.Maximized) win.showNormal()
                else {
                    AppBackend.saveWindowRect(win.x, win.y, win.width, win.height)
                    win.showMaximized()
                }
            }
        }
        Button {
            text: "✕"
            flat: true
            font.pixelSize: 13
            palette.buttonText: "#cdd6f4"
            onClicked: bar.Window.window.close()
        }
    }

    SubscriptionDialog { id: subDialog }
    SettingsDialog { id: settingsDialog }
    AboutDialog { id: aboutDialog }
}
