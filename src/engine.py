import logging
import sys

from PySide6.QtCore import Qt
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
    _win.setIcon(QIcon(":/assets/icon.png"))
    # 描边颜色从 QML 根对象 _themeBorder 属性读取，Theme.border 是唯一真实源
    backend.windowState.attach(_win, QQmlProperty.read(_win, "_themeBorder"))

    # 数据加载（配置、台标目录扫描、网络栈）放在首帧呈现之后，不占首帧的关键路径。
    # frameSwapped 是「已出画」的确凿证据；SingleShotConnection 限定只执行一次。
    # 窗口始终不呈现时 init 不执行，恢复可见后首帧一到即加载。
    # 异常无法再让进程启动失败，必须显式记录并反馈到 UI。
    def _deferred_init() -> None:
        try:
            backend.init()
        except Exception as e:
            logger.exception("初始化失败")
            backend.errorOccurred.emit("初始化失败", str(e))

    _win.frameSwapped.connect(_deferred_init, Qt.SingleShotConnection)
    return engine
