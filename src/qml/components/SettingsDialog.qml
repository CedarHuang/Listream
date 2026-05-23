import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0

Dialog {
    id: dialog
    title: "设置"
    modal: true
    standardButtons: Dialog.Close
    implicitWidth: 360

    background: Rectangle {
        color: "#1e1e2e"
        border.color: "#313244"
    }

    header: Label {
        text: "设置"
        color: "#cdd6f4"
        font.pixelSize: 16
        padding: 16
    }

    onOpened: {
        var cfg = AppBackend.getProxyConfig()
        proxySwitch.checked = cfg.enabled === true
        typeCombo.currentIndex = cfg.type === "socks5" ? 1 : 0
        hostField.text = cfg.host || ""
        portField.text = cfg.port > 0 ? cfg.port : ""
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Label {
                text: "代理"
                color: "#cdd6f4"
                font.pixelSize: 13
                Layout.preferredWidth: 60
            }
            Switch {
                id: proxySwitch
                palette.button: "#45475a"
            }
            Item { Layout.fillWidth: true }
        }

        ComboBox {
            id: typeCombo
            Layout.fillWidth: true
            enabled: proxySwitch.checked
            model: ["HTTP", "SOCKS5"]
            palette.base: "#313244"
            palette.text: "#cdd6f4"
            palette.button: "#45475a"
        }

        RowLayout {
            spacing: 8
            enabled: proxySwitch.checked

            TextField {
                id: hostField
                Layout.fillWidth: true
                placeholderText: "主机地址"
                placeholderTextColor: "#6c7086"
                color: "#cdd6f4"
                background: Rectangle { color: "#313244"; radius: 4 }
            }

            TextField {
                id: portField
                Layout.preferredWidth: 80
                placeholderText: "端口"
                placeholderTextColor: "#6c7086"
                color: "#cdd6f4"
                validator: IntValidator { bottom: 1; top: 65535 }
                background: Rectangle { color: "#313244"; radius: 4 }
            }
        }

        Button {
            text: "保存"
            palette.buttonText: "#cdd6f4"
            background: Rectangle { color: "#45475a"; radius: 4; implicitWidth: 60; implicitHeight: 34 }
            enabled: !proxySwitch.checked || (hostField.text !== "" && portField.text !== "")
            onClicked: {
                var proxyType = typeCombo.currentIndex === 1 ? "socks5" : "http"
                var port = parseInt(portField.text) || 0
                AppBackend.setProxyConfig(proxySwitch.checked, proxyType, hostField.text, port)
                dialog.close()
            }
        }
    }
}
