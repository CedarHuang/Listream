import QtQuick
import Theme 1.0

Rectangle {
    id: tip
    property string text: ""
    property QtObject target: parent
    property string align: "center"
    property int gap: 2

    readonly property bool _isChild: target === parent

    x: {
        var rx = _isChild ? target.width : target.x + target.width;
        if (align === "right")
            return rx - width;
        var lx = _isChild ? 0 : target.x;
        if (align === "left")
            return lx;
        return _isChild ? (target.width - width) / 2 : target.x + (target.width - width) / 2;
    }
    y: (_isChild ? -height : target.y - height) - gap

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
