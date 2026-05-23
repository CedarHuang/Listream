import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0
import Theme 1.0

Dialog {
    id: dialog
    title: ""
    modal: true
    width: 340
    topPadding: 0
    leftPadding: Theme.space6
    rightPadding: Theme.space6
    bottomPadding: Theme.space6

    implicitHeight: header.height + topPadding + contentItem.implicitHeight + bottomPadding

    Overlay.modal: Rectangle {
        color: Theme.overlayDim
    }

    background: Rectangle {
        color: Theme.bgOverlay
        radius: Theme.radiusLg
    }

    header: Rectangle {
        height: 48
        color: "transparent"

        Label {
            anchors { left: parent.left; leftMargin: Theme.space6; verticalCenter: parent.verticalCenter }
            text: "关于 Listream"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeXl
            font.bold: true
        }

        Button {
            id: closeX
            anchors { right: parent.right; rightMargin: Theme.space3; verticalCenter: parent.verticalCenter }
            width: 28; height: 28
            flat: true
            hoverEnabled: true
            contentItem: Text {
                text: "×"
                color: closeX.hovered ? Theme.textPrimary : Theme.textSecondary
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: closeX.hovered ? Theme.bgHover : "transparent"
                radius: Theme.radiusSm
            }
            onClicked: dialog.close()
        }
    }

    contentItem: ColumnLayout {
        spacing: Theme.space4

        Image {
            source: "qrc:/assets/icon.svg"
            sourceSize.width: 64
            sourceSize.height: 64
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Listream"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeXxl
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "v" + AppBackend.version
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeMd
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "IPTV 直播流播放器"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeMd
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: '<a href="https://github.com/CedarHuang/Listream">GitHub</a>'
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeMd
            textFormat: Text.StyledText
            linkColor: Theme.accent
            onLinkActivated: link => Qt.openUrlExternally(link)
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
        }

        Label {
            text: "Apache License 2.0"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSizeSm
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Copyright © 2026 CedarHuang"
            color: Theme.textMuted
            font.pixelSize: Theme.fontSizeSm
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
