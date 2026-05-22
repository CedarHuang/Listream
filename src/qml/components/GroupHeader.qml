import QtQuick

Rectangle {
    width: ListView.view.width
    height: 30
    color: "#181825"

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        text: section
        color: "#a6adc8"
        font.pixelSize: 12
        font.bold: true
    }
}
