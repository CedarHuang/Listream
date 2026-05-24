import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Listream.ViewModels 1.0
import Theme 1.0

Dialog {
    id: dialog
    title: ""
    modal: true
    width: 360
    topPadding: 0
    leftPadding: Theme.space6
    rightPadding: Theme.space6
    bottomPadding: Theme.space6

    parent: Overlay.overlay
    implicitHeight: header.height + topPadding + contentItem.implicitHeight + bottomPadding

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    Overlay.modal: Rectangle {
        color: Theme.overlayDim
    }

    background: Rectangle {
        color: Theme.bgOverlay
        radius: Theme.radiusLg
        border.color: Theme.border
        border.width: 1
    }

    header: Rectangle {
        height: 48
        color: "transparent"

        Label {
            anchors { left: parent.left; leftMargin: Theme.space6; verticalCenter: parent.verticalCenter }
            text: "设置"
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

    onOpened: {
        var cfg = AppBackend.getProxyConfig()
        proxySwitch.checked = cfg.enabled === true
        typeCombo.currentIndex = cfg.type === "socks5" ? 1 : 0
        hostField.text = cfg.host || ""
        portField.text = cfg.port > 0 ? cfg.port : ""
    }

    contentItem: ColumnLayout {
        spacing: Theme.space4

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "代理"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMd
                Layout.preferredWidth: 60
            }
            Switch {
                id: proxySwitch
                palette.button: Theme.bgHover
            }
            Item { Layout.fillWidth: true }
        }

        ComboBox {
            id: typeCombo
            Layout.fillWidth: true
            enabled: proxySwitch.checked
            model: ["HTTP", "SOCKS5"]
            font.pixelSize: Theme.fontSizeMd

            background: Rectangle {
                color: Theme.bgField
                radius: Theme.radiusMd
                border.width: 1
                border.color: typeCombo.activeFocus ? Theme.accent : Theme.border
            }

            contentItem: Text {
                leftPadding: Theme.space3
                rightPadding: typeCombo.indicator.width
                text: typeCombo.displayText
                color: Theme.textPrimary
                font: typeCombo.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            indicator: Rectangle {
                x: typeCombo.width - width - Theme.space2
                y: typeCombo.topPadding + (typeCombo.availableHeight - height) / 2
                width: 12; height: 12
                color: "transparent"

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = Theme.textSecondary
                        ctx.lineWidth = 1.5
                        ctx.beginPath()
                        ctx.moveTo(2, 4)
                        ctx.lineTo(6, 8)
                        ctx.lineTo(10, 4)
                        ctx.stroke()
                    }
                }
            }

            delegate: ItemDelegate {
                width: typeCombo.width
                contentItem: Text {
                    text: modelData
                    color: Theme.textPrimary
                    font: typeCombo.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: Theme.space3
                }
                background: Rectangle {
                    color: highlighted ? Theme.bgHover : Theme.bgField
                }
                highlighted: typeCombo.highlightedIndex === index
            }

            popup: Popup {
                y: typeCombo.height + Theme.space1
                width: typeCombo.width
                implicitHeight: contentItem.implicitHeight
                padding: Theme.space1

                background: Rectangle {
                    color: Theme.bgField
                    radius: Theme.radiusMd
                    border.color: Theme.border
                    border.width: 1
                }

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: typeCombo.popup.visible ? typeCombo.delegateModel : null
                    currentIndex: typeCombo.highlightedIndex
                }
            }
        }

        RowLayout {
            spacing: Theme.space3
            enabled: proxySwitch.checked

            TextField {
                id: hostField
                Layout.fillWidth: true
                placeholderText: "主机地址"
                placeholderTextColor: Theme.textMuted
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMd
                background: Rectangle {
                    color: Theme.bgField
                    radius: Theme.radiusMd
                    border.width: 1
                    border.color: hostField.activeFocus ? Theme.accent : Theme.border
                }
            }

            TextField {
                id: portField
                Layout.preferredWidth: 80
                placeholderText: "端口"
                placeholderTextColor: Theme.textMuted
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMd
                validator: IntValidator { bottom: 1; top: 65535 }
                background: Rectangle {
                    color: Theme.bgField
                    radius: Theme.radiusMd
                    border.width: 1
                    border.color: portField.activeFocus ? Theme.accent : Theme.border
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Theme.space3

            TextButton {
                text: "取消"
                textColor: Theme.textSecondary
                font.pixelSize: Theme.fontSizeMd
                onClicked: dialog.close()
            }

            Button {
                id: saveBtn
                text: "保存"
                font.pixelSize: Theme.fontSizeMd
                enabled: !proxySwitch.checked || (hostField.text !== "" && portField.text !== "")
                hoverEnabled: true
                contentItem: Text {
                    text: saveBtn.text
                    color: Theme.textOnAccent
                    font: saveBtn.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: saveBtn.enabled ? 1.0 : 0.5
                }
                background: Rectangle {
                    color: saveBtn.enabled ? (saveBtn.hovered ? Theme.accentHover : Theme.accent) : Theme.bgHover
                    radius: Theme.radiusSm
                    implicitWidth: 72
                    implicitHeight: 34
                }
                onClicked: {
                    var proxyType = typeCombo.currentIndex === 1 ? "socks5" : "http"
                    var port = parseInt(portField.text) || 0
                    AppBackend.setProxyConfig(proxySwitch.checked, proxyType, hostField.text, port)
                    dialog.close()
                }
            }
        }
    }
}
