import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0

Rectangle {
    height: 40
    color: "#1e1e2e"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        TextField {
            id: field
            Layout.fillWidth: true
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

        Text {
            visible: field.text !== ""
            text: ChannelFilterModel.filteredCount + "/" + ChannelFilterModel.totalCount
            color: "#6c7086"
            font.pixelSize: 12
        }
    }
}
