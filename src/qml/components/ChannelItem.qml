import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0
import Theme 1.0

Rectangle {
    id: item
    height: Theme.space10
    color: itemArea.containsMouse ? Theme.bgHover : "transparent"
    property bool isCurrent: url !== "" && url === PlayerController.currentUrl

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    Rectangle {
        id: activeIndicator
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 3
        color: Theme.currentItem
        visible: isCurrent
    }

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: AppBackend.playChannel(url, name)
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.space3
        spacing: Theme.space2

        Rectangle {
            width: 24; height: 24
            anchors.verticalCenter: parent.verticalCenter
            color: logo !== "" ? "transparent" : Theme.bgField
            radius: Theme.radiusSm

            Image {
                anchors.centerIn: parent
                width: 20; height: 20
                source: logo || ""
                sourceSize.width: 20
                fillMode: Image.PreserveAspectFit
                visible: logo !== "" && status !== Image.Error
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: name
            color: isCurrent ? Theme.currentItem : Theme.textPrimary
            font.pixelSize: Theme.fontSizeMd
            elide: Text.ElideRight
        }
    }
}
