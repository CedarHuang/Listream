import QtQuick
import QtQuick.Controls
import Theme 1.0

Button {
    id: control
    flat: true
    hoverEnabled: true
    leftPadding: Theme.space3
    rightPadding: Theme.space3

    property color textColor: Theme.textPrimary

    contentItem: Text {
        text: control.text
        color: control.enabled ? control.textColor : Theme.textDisabled
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: control.hovered ? Theme.bgHover : "transparent"
        radius: Theme.radiusSm
    }
}
