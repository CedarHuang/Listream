import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0
import Theme 1.0

ListView {
    id: listView
    clip: true
    focus: true
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationWraps: false

    model: ChannelFilterModel
    section.property: "group"
    section.criteria: ViewSection.FullString
    section.delegate: GroupHeader {}

    delegate: ChannelItem {
        width: listView.width
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle {
            implicitWidth: 6
            implicitHeight: 100
            radius: 3
            color: Theme.bgHover
        }
        background: Rectangle {
            implicitWidth: 6
            color: "transparent"
        }
    }

    Keys.onReturnPressed: {
        if (currentIndex >= 0) {
            var url = ChannelFilterModel.getUrl(currentIndex)
            var name = ChannelFilterModel.getName(currentIndex)
            if (url) AppBackend.playChannel(url, name)
        }
    }
}
