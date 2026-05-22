from pathlib import Path

from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonType

QML_DIR = Path(__file__).resolve().parent / "qml"


def create_engine() -> QQmlApplicationEngine:
    from .qmlitems import mpv_renderer  # noqa: F401 触发 @QmlElement 注册
    from .viewmodels.app_backend import AppBackend
    from .viewmodels.player_controller import PlayerController

    backend = AppBackend()
    backend.init()

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
    engine.addImportPath(str(QML_DIR))
    QQuickStyle.setStyle("Fusion")
    engine.load(str(QML_DIR / "main.qml"))
    if not engine.rootObjects():
        import sys
        sys.exit(-1)
    return engine
