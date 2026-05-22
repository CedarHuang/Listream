from pathlib import Path
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonInstance

QML_DIR = Path(__file__).resolve().parent / "qml"


def create_engine() -> QQmlApplicationEngine:
    engine = QQmlApplicationEngine()
    engine.addImportPath(str(QML_DIR))

    from .qmlitems import mpv_renderer  # noqa: F401 触发 @QmlElement 注册
    from .viewmodels.app_backend import AppBackend
    from .viewmodels.player_controller import PlayerController

    backend = AppBackend()
    qmlRegisterSingletonInstance(
        AppBackend, "Listream.ViewModels", 1, 0, "AppBackend", backend
    )
    qmlRegisterSingletonInstance(
        PlayerController, "Listream.ViewModels", 1, 0, "PlayerController", backend.player
    )
    qmlRegisterSingletonInstance(
        type(backend.channelModel),
        "Listream.ViewModels",
        1,
        0,
        "ChannelFilterModel",
        backend.channelModel,
    )
    qmlRegisterSingletonInstance(
        type(backend.subscriptionModel),
        "Listream.ViewModels",
        1,
        0,
        "SubscriptionListModel",
        backend.subscriptionModel,
    )

    backend.init()
    engine.load(str(QML_DIR / "main.qml"))
    if not engine.rootObjects():
        import sys
        sys.exit(-1)
    return engine
