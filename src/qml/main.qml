import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0
import Components 1.0

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    title: "Listream"
    visible: true
    color: "#1e1e2e"
    flags: Qt.Window | Qt.FramelessWindowHint

    Shortcut { sequence: "Space"; onActivated: PlayerController.togglePause() }
    Shortcut { sequence: "Escape"; onActivated: PlayerController.stop() }
    Shortcut { sequence: "F"; onActivated: {
        if (root.visibility === Window.FullScreen) {
            var nr = AppBackend.getWindowRect()
            root.visibility = Window.Windowed
            if (Object.keys(nr).length > 0) {
                root.width = nr.w
                root.height = nr.h
                root.x = nr.x
                root.y = nr.y
            }
        } else {
            if (root.visibility === Window.Windowed) {
                AppBackend.saveWindowRect(root.x, root.y, root.width, root.height)
            }
            root.showFullScreen()
        }
    }}

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar { Layout.fillWidth: true }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            property bool sidebarCollapsed: false

            Rectangle {
                id: sidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: parent.sidebarCollapsed ? 0 : 300
                color: "#181825"
                clip: true

                Behavior on width {
                    NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    SearchBar { Layout.fillWidth: true }
                    ChannelList { Layout.fillWidth: true; Layout.fillHeight: true }
                }
            }

            PlayerPane {
                anchors {
                    left: sidebar.right
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
            }

            Rectangle {
                id: toggleBtn
                property bool collapsed: parent.sidebarCollapsed
                anchors {
                    left: parent.left
                    leftMargin: sidebar.width - 1
                    verticalCenter: parent.verticalCenter
                }
                width: collapsed ? 22 : 24
                height: 60
                topLeftRadius: 0; bottomLeftRadius: 0
                topRightRadius: 4; bottomRightRadius: 4
                color: toggleMouse.containsMouse ? "#45475a" : "#313244"

                MouseArea {
                    id: toggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.parent.sidebarCollapsed = !parent.parent.sidebarCollapsed
                }

                Canvas {
                    id: arrowCanvas
                    anchors.centerIn: parent
                    width: 12; height: 12
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = "#a6adc8"; ctx.lineWidth = 1.5
                        ctx.beginPath()
                        if (toggleBtn.collapsed) {
                            ctx.moveTo(6, 1); ctx.lineTo(2, 6); ctx.lineTo(6, 11)
                        } else {
                            ctx.moveTo(2, 1); ctx.lineTo(6, 6); ctx.lineTo(2, 11)
                        }
                        ctx.stroke()
                    }
                    Connections {
                        target: toggleBtn
                        function onCollapsedChanged() { arrowCanvas.requestPaint() }
                    }
                }
            }
        }

        StatusBar { Layout.fillWidth: true }
    }

    Item {
        anchors.fill: parent

        MouseArea {
            height: 4; anchors { left: parent.left; right: parent.right; top: parent.top }
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.TopEdge)
        }
        MouseArea {
            height: 4; anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            cursorShape: Qt.SizeVerCursor
            onPressed: root.startSystemResize(Qt.BottomEdge)
        }
        MouseArea {
            width: 4; anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.LeftEdge)
        }
        MouseArea {
            width: 4; anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            cursorShape: Qt.SizeHorCursor
            onPressed: root.startSystemResize(Qt.RightEdge)
        }
        // 四角 — 避开 TopBar 的鼠标区域
        MouseArea {
            width: 8; height: 8; anchors { top: parent.top; left: parent.left }
            cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.TopLeftCorner)
        }
        MouseArea {
            width: 8; height: 8; anchors { top: parent.top; right: parent.right }
            cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.TopRightCorner)
        }
        MouseArea {
            width: 8; height: 8; anchors { bottom: parent.bottom; left: parent.left }
            cursorShape: Qt.SizeBDiagCursor
            onPressed: root.startSystemResize(Qt.BottomLeftCorner)
        }
        MouseArea {
            width: 8; height: 8; anchors { bottom: parent.bottom; right: parent.right }
            cursorShape: Qt.SizeFDiagCursor
            onPressed: root.startSystemResize(Qt.BottomRightCorner)
        }
    }

    Connections {
        target: AppBackend
        function onErrorOccurred(title, message) {
            errorDialog.title = title
            errorDialog.text = message
            errorDialog.open()
        }
    }

    Dialog {
        id: errorDialog
        title: ""
        property alias text: msgText.text
        modal: true
        standardButtons: Dialog.Ok
        implicitWidth: Math.min(500, Math.max(200, msgText.implicitWidth + leftPadding + rightPadding))
        anchors.centerIn: parent

        background: Rectangle {
            color: "#1e1e2e"
            border.color: "#f38ba8"
        }

        Label {
            id: msgText
            color: "#cdd6f4"
            font.pixelSize: 13
        }
    }

}
