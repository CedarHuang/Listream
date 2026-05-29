import QtQuick
import Listream.ViewModels 1.0
import Theme 1.0

Rectangle {
    id: root
    anchors {
        right: parent.right
        bottom: parent.bottom
        rightMargin: Theme.space3
        bottomMargin: Theme.space3
    }
    width: 230
    height: metaColumn.implicitHeight + Theme.space3 * 2
    color: Theme.bgOverlay
    opacity: 0.88
    radius: Theme.radiusMd

    visible: {
        if (!PlayerController.showMeta) return false
        var s = PlayerController.status
        return s === "playing" || s === "paused" || s === "buffering"
    }
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

    property var _meta: {
        try { return JSON.parse(PlayerController.videoMeta) }
        catch (e) { return {} }
    }

    function _has(key) {
        var v = root._meta[key]
        return v !== undefined && v !== null && v !== "" && v !== "no"
    }

    function _fmtText(key, fmt) {
        if (fmt === "_dsize")
            return root.parent.width + "×" + root.parent.height
        if (fmt === "_bitrate")
            return (PlayerController.cacheSpeed * 8 / 1000).toFixed(0) + " kbps"
        var v = root._meta[key]
        if (v === undefined || v === null) return "—"
        if (fmt === "vwh")
            return (root._meta["video-params/w"] || "?") + "×" + (root._meta["video-params/h"] || "?")
        if (fmt === "fps") return Number(v).toFixed(1) + " fps"
        if (fmt === "br") return (v / 1000).toFixed(0) + " kbps"
        if (fmt === "ch") return v + " ch"
        if (fmt === "hz") return (v / 1000).toFixed(1) + " kHz"
        return String(v)
    }

    Component {
        id: metaDelegate
        Row {
            width: metaColumn.width
            spacing: Theme.space2
            visible: {
                if (fmt === "_dsize") return root.parent.width > 0 && root.parent.height > 0
                if (fmt === "_bitrate") return PlayerController.cacheSpeed > 0
                return root._has(key)
            }
            Text {
                text: label
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeSm
                width: 48
            }
            Text {
                id: valText
                width: metaColumn.width - 48 - Theme.space2
                elide: Text.ElideRight
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeSm
                text: _fmtText(key, fmt)

                Text {
                    id: _measure
                    visible: false
                    text: valText.text
                    font: valText.font
                }

                MouseArea {
                    id: valMA
                    anchors.fill: parent
                    hoverEnabled: true
                }

                // FloatingTip 必须放在 Text 内而非 Row 内——
                // 作为 Row 直接子元素时 visibility 切换会触发布局重算导致抽搐
                FloatingTip {
                    text: _fmtText(key, fmt)
                    visible: _measure.contentWidth > valText.width && valMA.containsMouse
                }
            }
        }
    }

    Column {
        id: metaColumn
        anchors {
            left: parent.left; right: parent.right; top: parent.top
            leftMargin: Theme.space3; rightMargin: Theme.space3
            topMargin: Theme.space3
        }
        spacing: Theme.space1

        Repeater {
            model: ListModel {
                ListElement { key: "video-codec"; label: "视频编码"; fmt: "" }
                ListElement { key: "file-format"; label: "容器格式"; fmt: "" }
                ListElement { key: "video-params/w"; label: "原始尺寸"; fmt: "vwh" }
                ListElement { key: "_dsize"; label: "显示尺寸"; fmt: "_dsize" }
                ListElement { key: "estimated-vf-fps"; label: "帧率"; fmt: "fps" }
                ListElement { key: "_bitrate"; label: "码率"; fmt: "_bitrate" }
                ListElement { key: "hwdec-current"; label: "解码器"; fmt: "" }
                ListElement { key: "video-params/pixelformat"; label: "像素格式"; fmt: "" }
                ListElement { key: "colorspace"; label: "色彩空间"; fmt: "" }
            }
            delegate: metaDelegate
        }

        Item {
            width: metaColumn.width
            height: 1 + Theme.space1 * 2
            visible: root._has("audio-codec")

            Rectangle {
                width: parent.width
                height: 1
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.border
            }
        }

        Repeater {
            model: ListModel {
                ListElement { key: "audio-codec"; label: "音频编码"; fmt: "" }
                ListElement { key: "audio-params/channel-count"; label: "声道"; fmt: "ch" }
                ListElement { key: "audio-params/samplerate"; label: "采样率"; fmt: "hz" }
                ListElement { key: "audio-bitrate"; label: "音频码率"; fmt: "br" }
            }
            delegate: metaDelegate
        }
    }
}
