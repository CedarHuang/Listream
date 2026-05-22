import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0

Rectangle {
    id: item
    height: 40
    color: itemArea.containsMouse ? "#313244" : "transparent"
    property bool isCurrent: ListView.view.currentIndex === index

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            ListView.view.currentIndex = index
            AppBackend.playChannel(url, name)
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 28
        spacing: 10

        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: 24; height: 24
            source: logo || ""
            sourceSize.width: 24
            fillMode: Image.PreserveAspectFit
            onStatusChanged: {
                if (status === Image.Error) visible = false
            }
            visible: logo !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: name
            color: isCurrent ? "#f5c2e7" : "#cdd6f4"
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }
}
