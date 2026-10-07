import logging
import sys

from PySide6.QtGui import QIcon
from PySide6.QtQuick import QQuickWindow, QSGRendererInterface
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQml import QQmlApplicationEngine, QQmlProperty, qmlRegisterSingletonType

from . import resources_rc  # noqa: F401 注册 .qrc 编译的资源

logger = logging.getLogger(__name__)


def create_engine() -> QQmlApplicationEngine:
    from .qmlitems import mpv_renderer  # noqa: F401 触发 @QmlElement 注册
    from .viewmodels.app_backend import AppBackend
    from .viewmodels.player_controller import PlayerController
    from .viewmodels.window_state import WindowState

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
        WindowState, "Listream.ViewModels", 1, 0, "WindowState",
        lambda _eng: backend.windowState,
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
        sys.exit(-1)

    # 窗口原生呈现（DWM 描边 / 圆角 / setMask 兜底）全部交给 WindowState 接管。
    _win = engine.rootObjects()[0]
    _win.setIcon(QIcon(":/assets/icon.svg"))
    # 描边颜色从 QML 根对象 _themeBorder 属性读取，Theme.border 是唯一真实源
    backend.windowState.attach(_win, QQmlProperty.read(_win, "_themeBorder"))
    return engine
