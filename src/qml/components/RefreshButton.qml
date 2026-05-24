import QtQuick
import QtQuick.Controls
import Theme 1.0

Button {
    id: control
    flat: true
    hoverEnabled: true
    property bool running: false

    contentItem: Text {
        text: "↻"
        color: control.enabled
            ? (control.hovered ? Theme.accentHover : Theme.textSecondary)
            : Theme.textDisabled
        font.pixelSize: control.implicitHeight > 24 ? 18 : 15
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        RotationAnimation on rotation {
            running: control.running
            from: 0; to: 360
            duration: 800
            loops: Animation.Infinite
        }
    }

    background: Rectangle {
        color: control.hovered && control.enabled ? Theme.bgHover : "transparent"
        radius: Theme.radiusSm
    }
}
