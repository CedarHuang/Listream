import QtQuick
import Theme 1.0

Rectangle {
    id: tip
    property string text: ""
    property QtObject target: parent
    property int gap: 2
    property QtObject container: null

    readonly property bool _isChild: target === parent
    readonly property QtObject _root: {
        var w = tip.parent
        while (w && w.parent) w = w.parent
        return (w && w.width > 0) ? w : null
    }

    x: {
        var cx = _isChild ? (target.width - width) / 2
                          : target.x + (target.width - width) / 2
        if (_root) {
            var pt = tip.parent.mapToItem(_root, cx, 0)
            if (pt.x + width > _root.width)
                return tip.parent.mapFromItem(_root, _root.width - 4, 0).x - width
            if (pt.x < 0)
                return tip.parent.mapFromItem(_root, 4, 0).x
        }
        return cx
    }

    y: {
        var cy
        if (container) {
            cy = tip.parent.mapFromItem(container, 0, -height - gap).y
        } else {
            cy = (_isChild ? -height : target.y - height) - gap
        }
        if (_root) {
            var pt = tip.parent.mapToItem(_root, 0, cy)
            if (pt.y < 0) {
                if (container)
                    return tip.parent.mapFromItem(container, 0, container.height + gap).y
                return _isChild ? target.height + gap : target.y + target.height + gap
            }
        }
        return cy
    }

    width: tipText.implicitWidth + 10
    height: tipText.implicitHeight + 6
    radius: 4
    color: Theme.bgSurface
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Text {
        id: tipText
        anchors.centerIn: parent
        text: tip.text
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSizeSm
    }
}
