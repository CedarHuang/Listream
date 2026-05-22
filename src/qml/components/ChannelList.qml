import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0

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

    highlight: Rectangle {
        color: "#45475a"
        radius: 4
    }

    highlightMoveDuration: 80

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    Keys.onReturnPressed: {
        if (currentIndex >= 0) {
            var url = ChannelFilterModel.getUrl(currentIndex)
            var name = ChannelFilterModel.getName(currentIndex)
            if (url) AppBackend.playChannel(url, name)
        }
    }
}
