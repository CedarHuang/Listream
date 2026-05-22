import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0

Rectangle {
    height: 40
    color: "#1e1e2e"

    TextField {
        id: field
        anchors.fill: parent
        anchors.margins: 8
        placeholderText: "搜索频道..."
        placeholderTextColor: "#6c7086"
        color: "#cdd6f4"
        font.pixelSize: 13
        leftPadding: 10
        background: Rectangle {
            color: "#313244"
            radius: 6
        }
        onTextChanged: ChannelFilterModel.setFilterText(text)
    }
}
