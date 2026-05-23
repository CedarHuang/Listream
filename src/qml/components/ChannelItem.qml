import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0

Rectangle {
    id: item
    height: 40
    color: itemArea.containsMouse ? "#313244" : "transparent"
    property bool isCurrent: url !== "" && url === PlayerController.currentUrl

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: AppBackend.playChannel(url, name)
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 10

        Item {
            width: 24; height: 24
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.centerIn: parent
                width: 24; height: 24
                source: logo || ""
                sourceSize.width: 24
                fillMode: Image.PreserveAspectFit
                visible: logo !== "" && status !== Image.Error
            }
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
