import ctypes
import logging
import platform
from ctypes import wintypes

from PySide6.QtGui import QRegion, QPainterPath, QIcon
from PySide6.QtCore import QRectF
from PySide6.QtQuick import QQuickWindow, QSGRendererInterface
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQml import QQmlApplicationEngine, QQmlProperty, qmlRegisterSingletonType

from . import resources_rc  # noqa: F401 注册 .qrc 编译的资源

logger = logging.getLogger(__name__)


def create_engine() -> QQmlApplicationEngine:
    from .qmlitems import mpv_renderer  # noqa: F401 触发 @QmlElement 注册
    from .viewmodels.app_backend import AppBackend
    from .viewmodels.player_controller import PlayerController

    backend = AppBackend()
    backend.init()

    # 强制 OpenGL 后端 — mpv libmpv VO 需要 OpenGL 互操作
    QQuickWindow.setGraphicsApi(QSGRendererInterface.GraphicsApi.OpenGL)

    # ⚠️ 以下 import 和注册必须在 QQmlApplicationEngine 创建之前执行，
    # 否则 PySide6 shiboken 层的 QML 类型注册会损坏 QtQuick.Controls 内部类型系统。
    qmlRegisterSingletonType(
        AppBackend, "Listream.ViewModels", 1, 0, "AppBackend", lambda _eng: backend,
    )
    qmlRegisterSingletonType(
        PlayerController, "Listream.ViewModels", 1, 0, "PlayerController",
        lambda _eng: backend.player,
    )
    qmlRegisterSingletonType(
        type(backend.channelModel), "Listream.ViewModels", 1, 0, "ChannelFilterModel",
        lambda _eng: backend.channelModel,
    )
    qmlRegisterSingletonType(
        type(backend.subscriptionModel), "Listream.ViewModels", 1, 0, "SubscriptionListModel",
        lambda _eng: backend.subscriptionModel,
    )

    engine = QQmlApplicationEngine()
    engine.addImportPath("qrc:/qml")
    QQuickStyle.setStyle("Fusion")
    engine.load("qrc:/qml/main.qml")
    if not engine.rootObjects():
        logger.error("QML 加载失败，无法创建窗口")
        import sys
        sys.exit(-1)

    # ------- 无边框窗口圆角：DWM 原生（Win11）优先，setMask 兜底 -------
    _win = engine.rootObjects()[0]
    _win.setIcon(QIcon(":/assets/icon.svg"))
    _R = 8  # 对齐 Theme.radiusMd

    # --- DWM 路径 ---
    backend._hwnd = int(_win.winId()) if platform.system() == "Windows" else 0
    _dwm_hwnd: int | None = backend._hwnd if backend._hwnd else None

    DWMWA_CORNER = 33     # DWMWA_WINDOW_CORNER_PREFERENCE
    DWMWCP_ROUND = 2
    DWMWCP_DONOTROUND = 1

    def _set_dwm_corner(rounded: bool) -> None:
        if _dwm_hwnd is None:
            return
        pref = ctypes.c_int(DWMWCP_ROUND if rounded else DWMWCP_DONOTROUND)
        ctypes.windll.dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(_dwm_hwnd), DWMWA_CORNER,
            ctypes.byref(pref), ctypes.sizeof(pref),
        )

    if _dwm_hwnd is not None:
        # DWM 描边颜色 — 从 QML 根对象 _themeBorder 属性读取，Theme.border 是唯一真实源
        _border_qcolor = QQmlProperty.read(_win, "_themeBorder")
        _colorref = (_border_qcolor.blue() << 16) | (_border_qcolor.green() << 8) | _border_qcolor.red()
        _border_color = ctypes.c_int(_colorref)
        ctypes.windll.dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(_dwm_hwnd), 34,  # DWMWA_BORDER_COLOR
            ctypes.byref(_border_color), ctypes.sizeof(_border_color),
        )

        def _on_dwm_visibility(v: QQuickWindow.Visibility) -> None:
            _set_dwm_corner(v == QQuickWindow.Windowed)

        _on_dwm_visibility(_win.visibility())
        _win.visibilityChanged.connect(_on_dwm_visibility)
        logger.info("DWM 圆角: 已启用")
    else:
        logger.info("DWM 圆角: 不可用，回退 setMask")

    # --- setMask 兜底 ---
    if _dwm_hwnd is None:
        def _update_mask() -> None:
            if _win.visibility() != QQuickWindow.Windowed:
                _win.setMask(QRegion())
            else:
                p = QPainterPath()
                p.addRoundedRect(QRectF(0, 0, _win.width(), _win.height()), _R, _R)
                _win.setMask(QRegion(p.toFillPolygon().toPolygon()))

        _update_mask()
        _win.widthChanged.connect(_update_mask)
        _win.heightChanged.connect(_update_mask)
        _win.visibilityChanged.connect(_update_mask)
    # ----------------------------------------------------------------
    return engine
