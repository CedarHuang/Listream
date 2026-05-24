import QtQuick
import QtQuick.Controls
import Listream.ViewModels 1.0
import Theme 1.0

ListView {
    id: listView
    clip: true
    focus: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 3000
    maximumFlickVelocity: 1500
    reuseItems: true
    keyNavigationWraps: false

    model: ChannelFilterModel
    section.property: "group"
    section.criteria: ViewSection.FullString
    section.delegate: GroupHeader {}

    delegate: ChannelItem {
        width: listView.width
    }

    ScrollBar.vertical: ScrollBar {
        id: vbar
        policy: ScrollBar.AsNeeded
        visible: size < 1.0
        padding: 0
        hoverEnabled: true
        contentItem: Rectangle {
            implicitWidth: 6
            topLeftRadius: Theme.radiusSm; bottomLeftRadius: Theme.radiusSm
            topRightRadius: 0; bottomRightRadius: 0
            color: vbar.hovered ? Theme.bgHover : Theme.bgSurface
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }
        }
        background: Rectangle {
            implicitWidth: 6
            color: "transparent"
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        property int speed: 5
        onWheel: (event) => {
            let targetVel = event.angleDelta.y * speed
            if (listView.verticalOvershoot !== 0.0 ||
                (targetVel > 0 && listView.verticalVelocity <= 0) ||
                (targetVel < 0 && listView.verticalVelocity >= 0)) {
                listView.flick(0, targetVel - listView.verticalVelocity)
            } else {
                listView.cancelFlick()
            }
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
