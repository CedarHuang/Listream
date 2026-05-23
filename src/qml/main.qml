import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0
import Components 1.0

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    title: "Listream"
    visible: true
    color: "#1e1e2e"

    Shortcut { sequence: "Space"; onActivated: PlayerController.togglePause() }
    Shortcut { sequence: "Escape"; onActivated: PlayerController.stop() }
    Shortcut { sequence: "F"; onActivated: {
        if (root.visibility === Window.FullScreen) root.showNormal()
        else root.showFullScreen()
    }}

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar { Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1

            Rectangle {
                Layout.preferredWidth: 300
                Layout.fillHeight: true
                color: "#181825"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    SearchBar { Layout.fillWidth: true }
                    ChannelList { Layout.fillWidth: true; Layout.fillHeight: true }
                }
            }

            PlayerPane { Layout.fillWidth: true; Layout.fillHeight: true }
        }

        StatusBar { Layout.fillWidth: true }
    }

    Connections {
        target: AppBackend
        function onErrorOccurred(title, message) {
            errorDialog.title = title
            errorDialog.text = message
            errorDialog.open()
        }
    }

    Dialog {
        id: errorDialog
        title: ""
        property alias text: msgText.text
        modal: true
        standardButtons: Dialog.Ok
        implicitWidth: Math.min(500, Math.max(200, msgText.implicitWidth + leftPadding + rightPadding))
        anchors.centerIn: parent

        background: Rectangle {
            color: "#1e1e2e"
            border.color: "#f38ba8"
        }

        Label {
            id: msgText
            color: "#cdd6f4"
            font.pixelSize: 13
        }
    }

}
