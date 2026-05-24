pragma Singleton
import QtQuick

QtObject {
    // ============================================================
    // Surface Elevation — warm-neutral dark grays
    // ============================================================
    readonly property color bgPlayer:    "#0a0a0a"
    readonly property color bgWindow:    "#151515"
    readonly property color bgSidebar:   "#181818"
    readonly property color bgField:     "#262626"
    readonly property color bgSurface:   "#2e2e2e"
    readonly property color bgHover:     "#363636"
    readonly property color bgOverlay:   "#1e1e1e"

    // ============================================================
    // Text Hierarchy
    // ============================================================
    readonly property color textPrimary:   "#ededed"
    readonly property color textSecondary: "#9e9e9e"
    readonly property color textMuted:     "#6a6a6a"
    readonly property color textDisabled:  "#505050"

    // ============================================================
    // Accent
    // ============================================================
    readonly property color accent:        "#3b82f6"
    readonly property color accentHover:   "#60a5fa"
    readonly property color accentMuted:   "#1a2844"

    // ============================================================
    // Semantic
    // ============================================================
    readonly property color success:       "#22c55e"
    readonly property color warning:       "#eab308"
    readonly property color error:         "#ef4444"
    readonly property color errorHover:    "#f76363"
    readonly property color currentItem:   "#3b82f6"

    // ============================================================
    // Misc
    // ============================================================
    readonly property color overlayDim:    "#60000000"
    readonly property color textOnAccent:  "#ffffff"

    // ============================================================
    // Borders & Separators
    // ============================================================
    readonly property color border:        "#383838"
    readonly property color borderLight:   "#323232"

    // ============================================================
    // Typography
    // ============================================================
    readonly property int fontSizeXs:  11
    readonly property int fontSizeSm:  12
    readonly property int fontSizeMd:  13
    readonly property int fontSizeLg:  15
    readonly property int fontSizeXl:  18
    readonly property int fontSizeXxl: 22

    // ============================================================
    // Spacing — 4px grid
    // ============================================================
    readonly property int space1:  4
    readonly property int space2:  8
    readonly property int space3:  12
    readonly property int space4:  16
    readonly property int space5:  20
    readonly property int space6:  24
    readonly property int space8:  32
    readonly property int space10: 40

    // ============================================================
    // Border Radius
    // ============================================================
    readonly property int radiusSm: 4
    readonly property int radiusMd: 8
    readonly property int radiusLg: 12

    // ============================================================
    // Animation
    // ============================================================
    readonly property int animFast:   120
    readonly property int animNormal: 180
    readonly property int animSlow:   300
}
