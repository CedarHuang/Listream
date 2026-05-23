import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0

Dialog {
    id: dialog
    title: "关于"
    modal: true
    standardButtons: Dialog.Close
    implicitWidth: 340

    background: Rectangle {
        color: "#1e1e2e"
        border.color: "#313244"
    }

    header: Label {
        text: "关于 Listream"
        color: "#cdd6f4"
        font.pixelSize: 16
        padding: 16
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Image {
            source: "qrc:/assets/icon.svg"
            sourceSize.width: 64
            sourceSize.height: 64
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Listream"
            color: "#cdd6f4"
            font.pixelSize: 18
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "v" + AppBackend.version
            color: "#a6adc8"
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "IPTV 直播流播放器"
            color: "#a6adc8"
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: '<a href="https://github.com/CedarHuang/Listream">GitHub</a>'
            color: "#cdd6f4"
            font.pixelSize: 13
            textFormat: Text.StyledText
            linkColor: "#89b4fa"
            onLinkActivated: link => Qt.openUrlExternally(link)
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#313244"
        }

        Label {
            text: "Apache License 2.0"
            color: "#6c7086"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Copyright © 2026 CedarHuang"
            color: "#6c7086"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
