import QtQuick
import QtQuick.Controls
import Theme 1.0

Item {
    id: root
    implicitWidth: 36
    implicitHeight: 20

    property bool checked: false
    property bool enabled: true

    signal toggled()

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: !root.enabled ? Theme.bgSurface
             : root.checked ? Theme.accent : Theme.bgSurface
        border.width: root.checked && root.enabled ? 0 : 1
        border.color: Theme.border

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Rectangle {
        id: thumb
        width: 16; height: 16
        radius: 8
        y: 2
        color: root.enabled ? Theme.textOnAccent : Theme.textDisabled

        x: root.checked ? root.width - width - 2 : 2
        Behavior on x {
            NumberAnimation { duration: Theme.animFast; easing.type: Easing.InOutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled
        onClicked: {
            root.checked = !root.checked
            root.toggled()
        }
    }
}
