import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0
import Components 1.0
import Theme 1.0

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    title: "Listream"
    visible: true
    color: Theme.bgWindow
    flags: Qt.Window | Qt.FramelessWindowHint
    property bool sidebarCollapsed: false
    property bool _sidebarBeforeFullscreen: false
    property bool _skipAnim: false
    property bool _wasMaximized: false
    property bool _maximizedBeforeFullscreen: false
    property int _prevVisibility: Window.Windowed
    readonly property color _themeBorder: Theme.border  // Python 侧 DWM 描边读取用

    Timer { id: animTimer; interval: 0; onTriggered: root._skipAnim = false }
    Timer {
        id: _restoreMaxTimer
        interval: 0; repeat: false
        onTriggered: root.showMaximized()
    }

    // ---- 窗口状态操作（唯一真相源） ----

    function beginDragUnmaximize() {
        root._wasMaximized = false
        AppBackend.forceClearMaxWindowStyle()
    }

    function toggleMaximized() {
        if (root.visibility === Window.Maximized) {
            root._wasMaximized = false
            AppBackend.forceClearMaxWindowStyle()
            root.visibility = Window.Windowed
            var nr = AppBackend.getWindowRect()
            if (Object.keys(nr).length > 0) {
                root.x = nr.x; root.y = nr.y
                root.width = nr.w; root.height = nr.h
            }
        } else if (root.visibility === Window.Windowed) {
            AppBackend.saveWindowRect(root.x, root.y, root.width, root.height)
            root.showMaximized()
        }
    }

    function enterFullscreen() {
        root._maximizedBeforeFullscreen = root._wasMaximized
        if (root.visibility === Window.Windowed)
            AppBackend.saveWindowRect(root.x, root.y, root.width, root.height)
        root._skipAnim = true
        root._sidebarBeforeFullscreen = root.sidebarCollapsed
        root.sidebarCollapsed = true
        root.showFullScreen()
        animTimer.start()
    }

    function exitFullscreen() {
        if (root._maximizedBeforeFullscreen) {
            root._maximizedBeforeFullscreen = false
            root.showMaximized()
        } else {
            root._wasMaximized = false
            var nr = AppBackend.getWindowRect()
            AppBackend.forceClearMaxWindowStyle()
            root.visibility = Window.Windowed
            if (Object.keys(nr).length > 0) {
                root.x = nr.x; root.y = nr.y
                root.width = nr.w; root.height = nr.h
            }
        }
    }

    onVisibilityChanged: (v) => {
        var prev = root._prevVisibility

        if (v === Window.Maximized) {
            root._wasMaximized = true
        } else if (v === Window.FullScreen) {
            root._wasMaximized = false
        } else if (v === Window.Windowed && prev === Window.Maximized) {
            root._wasMaximized = false
        } else if (v === Window.Windowed && prev === Window.Minimized && root._wasMaximized) {
            root._wasMaximized = false
            _restoreMaxTimer.start()
        }

        root._prevVisibility = v

        if (v !== Window.FullScreen && _sidebarBeforeFullscreen !== sidebarCollapsed) {
            root._skipAnim = true
            sidebarCollapsed = _sidebarBeforeFullscreen
            animTimer.start()
        }
    }

    Shortcut { sequence: "Space"; onActivated: PlayerController.togglePause() }
    Shortcut { sequence: "Escape"; onActivated: { if (root.visibility === Window.FullScreen) root.exitFullscreen() }}
    Shortcut { sequence: "Tab"; onActivated: root.sidebarCollapsed = !root.sidebarCollapsed }
    Shortcut { sequence: "F"; onActivated: {
        if (root.visibility === Window.FullScreen)
            root.exitFullscreen()
        else
            root.enterFullscreen()
    }}

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar { Layout.fillWidth: true }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: sidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: root.sidebarCollapsed ? 0 : 300
                color: Theme.bgSidebar
                clip: true

                Behavior on width {
                    enabled: !root._skipAnim
                    NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.space2
                        Layout.rightMargin: Theme.space2
                        spacing: Theme.space1

                        SearchBar { Layout.fillWidth: true }

                        RefreshButton {
                            implicitWidth: 28; implicitHeight: 28
                            enabled: !AppBackend.busy
                            running: AppBackend.refreshingAll
                            onClicked: AppBackend.refreshAll()
                        }
                    }

                    ChannelList { Layout.fillWidth: true; Layout.fillHeight: true }
                }
            }

            Rectangle {
                id: sidebarBorder
                anchors {
                    left: sidebar.right
                    top: parent.top
                    bottom: parent.bottom
                }
                width: 1
                color: Theme.border
                visible: sidebar.width > 0
            }

            PlayerPane {
                anchors {
                    left: sidebarBorder.right
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
            }

            Rectangle {
                id: toggleBtn
                property bool collapsed: root.sidebarCollapsed
                anchors {
                    left: parent.left
                    leftMargin: sidebar.width
                    verticalCenter: parent.verticalCenter
                }
                width: 20
                height: 60
                topLeftRadius: 0; bottomLeftRadius: 0
                topRightRadius: Theme.radiusMd; bottomRightRadius: Theme.radiusMd
                color: toggleMouse.containsMouse ? Theme.bgHover : Theme.bgSurface
                opacity: 0.92

                MouseArea {
                    id: toggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sidebarCollapsed = !root.sidebarCollapsed
                }

                Canvas {
                    id: arrowCanvas
                    anchors.centerIn: parent
                    width: 12; height: 12
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = Theme.textSecondary; ctx.lineWidth = 1.5
                        ctx.beginPath()
                        if (toggleBtn.collapsed) {
                            ctx.moveTo(2, 1); ctx.lineTo(6, 6); ctx.lineTo(2, 11)
                        } else {
                            ctx.moveTo(6, 1); ctx.lineTo(2, 6); ctx.lineTo(6, 11)
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
        id: resizeHandles
        anchors.fill: parent
        enabled: root.visibility === Window.Windowed

        MouseArea {
            height: 4; anchors { left: parent.left; right: parent.right; top: parent.top }
            cursorShape: resizeHandles.enabled ? Qt.SizeVerCursor : Qt.ArrowCursor
            onPressed: root.startSystemResize(Qt.TopEdge)
        }
        MouseArea {
            height: 4; anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            cursorShape: resizeHandles.enabled ? Qt.SizeVerCursor : Qt.ArrowCursor
            onPressed: root.startSystemResize(Qt.BottomEdge)
        }
        MouseArea {
            width: 4; anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            cursorShape: resizeHandles.enabled ? Qt.SizeHorCursor : Qt.ArrowCursor
            onPressed: root.startSystemResize(Qt.LeftEdge)
        }
        MouseArea {
            width: 4; anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            cursorShape: resizeHandles.enabled ? Qt.SizeHorCursor : Qt.ArrowCursor
            onPressed: root.startSystemResize(Qt.RightEdge)
        }
        // 四角
        MouseArea {
            width: 8; height: 8; anchors { top: parent.top; left: parent.left }
            cursorShape: resizeHandles.enabled ? Qt.SizeFDiagCursor : Qt.ArrowCursor
            onPressed: root.startSystemResize(Qt.TopLeftCorner)
        }
        MouseArea {
            width: 8; height: 8; anchors { top: parent.top; right: parent.right }
            cursorShape: resizeHandles.enabled ? Qt.SizeBDiagCursor : Qt.ArrowCursor
            onPressed: root.startSystemResize(Qt.TopRightCorner)
        }
        MouseArea {
            width: 8; height: 8; anchors { bottom: parent.bottom; left: parent.left }
            cursorShape: resizeHandles.enabled ? Qt.SizeBDiagCursor : Qt.ArrowCursor
            onPressed: root.startSystemResize(Qt.BottomLeftCorner)
        }
        MouseArea {
            width: 8; height: 8; anchors { bottom: parent.bottom; right: parent.right }
            cursorShape: resizeHandles.enabled ? Qt.SizeFDiagCursor : Qt.ArrowCursor
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
        parent: Overlay.overlay
        topPadding: 0
        leftPadding: Theme.space6
        rightPadding: Theme.space6
        bottomPadding: Theme.space6
        implicitWidth: Math.min(500, Math.max(280, msgText.implicitWidth + leftPadding + rightPadding))
        implicitHeight: header.height + topPadding + contentItem.implicitHeight + bottomPadding
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        Overlay.modal: Rectangle {
            color: Theme.overlayDim
        }

        background: Rectangle {
            color: Theme.bgOverlay
            border.color: Theme.error
            radius: Theme.radiusLg
            border.width: 1
        }

        header: Rectangle {
            height: 48
            color: "transparent"

            Label {
                anchors { left: parent.left; leftMargin: Theme.space6; verticalCenter: parent.verticalCenter }
                text: errorDialog.title
                color: Theme.error
                font.pixelSize: Theme.fontSizeXl
                font.bold: true
            }
        }

        contentItem: ColumnLayout {
            spacing: Theme.space4

            Label {
                id: msgText
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMd
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Button {
                Layout.alignment: Qt.AlignRight
                text: "确定"
                palette.buttonText: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMd
                background: Rectangle {
                    color: Theme.bgHover
                    radius: Theme.radiusSm
                    implicitWidth: 72
                    implicitHeight: 34
                }
                onClicked: errorDialog.close()
            }
        }
    }

}
