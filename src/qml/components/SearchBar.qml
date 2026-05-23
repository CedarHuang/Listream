import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0
import Theme 1.0

Rectangle {
    height: Theme.space10
    color: Theme.bgSidebar

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.space2
        spacing: Theme.space1

        TextField {
            id: field
            Layout.fillWidth: true
            placeholderText: "搜索频道..."
            placeholderTextColor: Theme.textMuted
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeMd
            leftPadding: Theme.space3
            background: Rectangle {
                color: Theme.bgField
                radius: Theme.radiusMd
                border.width: 1
                border.color: field.activeFocus ? Theme.accent : Theme.border
            }
            onTextChanged: ChannelFilterModel.setFilterText(text)
        }

        Text {
            visible: field.text !== ""
            text: ChannelFilterModel.filteredCount + "/" + ChannelFilterModel.totalCount
            color: Theme.textMuted
            font.pixelSize: Theme.fontSizeSm
        }
    }
}
