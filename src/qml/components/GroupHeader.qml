import QtQuick
import Theme 1.0

Rectangle {
    width: ListView.view.width
    height: Theme.space8
    color: Theme.bgSidebar

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        height: 1
        color: Theme.border
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.space3
        width: 4; height: 4
        radius: 2
        color: Theme.textMuted
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.space3 + 10
        text: section
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSizeSm
        font.bold: true
    }
}
