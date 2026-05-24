import logging

from PySide6.QtCore import Property, QObject, Signal, Slot
from PySide6.QtGui import QCursor

from ..services.subscription_manager import SubscriptionManager
from ..services.logo_cache import LogoCache
from ..services.fetcher import Fetcher
from ..services.storage import (
    load_last_channel,
    save_last_channel,
    load_proxy_config,
    save_proxy_config,
)
from .channel_list_model import ChannelListModel, ChannelFilterModel
from .subscription_list_model import SubscriptionListModel
from .player_controller import PlayerController

logger = logging.getLogger(__name__)


class AppBackend(QObject):
    channelsChanged = Signal()
    subscriptionsChanged = Signal()
    errorOccurred = Signal(str, str)
    lastChannelChanged = Signal()
    busyChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channel_model = ChannelListModel(self)
        self._filter_model = ChannelFilterModel(self)
        self._filter_model.setSourceModel(self._channel_model)
        self._sub_model = SubscriptionListModel(self)
        self._player = PlayerController(self)
        self._fetcher = Fetcher(self)
        self._fetcher.fetched.connect(self._on_fetched)
        self._logo_cache = LogoCache(self)
        self._manager = SubscriptionManager(self._fetcher, self._logo_cache)
        self._manager.set_on_channels_changed(self._on_channels_changed)
        self._last_channel = load_last_channel()
        self._busy_count = 0

    @Property(bool, notify=busyChanged)
    def busy(self) -> bool:
        return self._busy_count > 0

    def _inc_busy(self, n: int = 1) -> None:
        was = self._busy_count > 0
        self._busy_count += n
        if not was:
            self.busyChanged.emit()

    def _dec_busy(self) -> None:
        if self._busy_count > 0:
            self._busy_count -= 1
            if self._busy_count == 0:
                self.busyChanged.emit()

    @property
    def channelModel(self):
        return self._filter_model

    @property
    def subscriptionModel(self):
        return self._sub_model

    @property
    def player(self) -> PlayerController:
        return self._player

    @Property(str, constant=True)
    def version(self) -> str:
        from .. import __version__
        return __version__

    @Property(str, notify=lastChannelChanged)
    def lastChannelUrl(self) -> str:
        if self._last_channel:
            return self._last_channel.get("url", "")
        return ""

    @Property(str, notify=lastChannelChanged)
    def lastChannelName(self) -> str:
        if self._last_channel:
            return self._last_channel.get("name", "")
        return ""

    def init(self) -> None:
        self._apply_proxy()
        self._manager.load()
        self._sub_model.replace_all(self._manager.subscriptions)
        self._push_channels()
        self._manager.startup_refresh()

    def _apply_proxy(self) -> None:
        proxy = load_proxy_config()
        if proxy:
            self._fetcher.configure_proxy(proxy)
            self._player.configure_proxy(proxy)

    @Slot(str, str)
    def addSubscription(self, name: str, url: str) -> None:
        logger.info("添加订阅 name=%s url=%s", name, url)
        self._inc_busy()
        self._manager.add(name, url)
        self._sub_model.replace_all(self._manager.subscriptions)

    @Slot(str)
    def removeSubscription(self, sub_id: str) -> None:
        logger.info("删除订阅 subscription_id=%s", sub_id)
        self._manager.remove(sub_id)
        self._sub_model.replace_all(self._manager.subscriptions)

    @Slot(str, str, str)
    def updateSubscription(self, sub_id: str, name: str, url: str) -> None:
        self._manager.update(sub_id, name, url)
        self._sub_model.notify_item(sub_id)

    @Slot(str, bool)
    def setSubscriptionEnabled(self, sub_id: str, enabled: bool) -> None:
        self._manager.set_enabled(sub_id, enabled)
        self._sub_model.notify_item(sub_id)

    @Slot(str)
    def refreshSubscription(self, sub_id: str) -> None:
        self._inc_busy()
        self._manager.refresh(sub_id)

    @Slot()
    def refreshAll(self) -> None:
        n = sum(1 for s in self._manager.subscriptions if s.enabled)
        if n > 0:
            self._inc_busy(n)
        self._manager.refresh_all()

    @Slot(str, str)
    def playChannel(self, url: str, name: str) -> None:
        save_last_channel(url, name)
        self._player.play(url, name)

    @Slot(float, float, float, float)
    def saveWindowRect(self, x: float, y: float, w: float, h: float) -> None:
        self._windowRect = {"x": x, "y": y, "w": w, "h": h}

    @Slot(result="QVariantMap")
    def getCursorPos(self) -> dict:
        pos = QCursor.pos()
        return {"x": pos.x(), "y": pos.y()}

    @Slot(result="QVariantMap")
    def getWindowRect(self) -> dict:
        return self._windowRect if hasattr(self, "_windowRect") else {}

    @Slot(QObject)
    def setRenderer(self, renderer: QObject) -> None:
        self._player.set_renderer(renderer)

    @Slot(result="QVariantMap")
    def getProxyConfig(self) -> dict:
        return load_proxy_config()

    @Slot(bool, str, str, int)
    def setProxyConfig(self, enabled: bool, proxy_type: str, host: str, port: int) -> None:
        proxy = {"enabled": enabled, "type": proxy_type, "host": host, "port": port}
        save_proxy_config(proxy)
        logger.info("代理配置已保存 enabled=%s type=%s host=%s port=%s", enabled, proxy_type, host, port)
        self._fetcher.configure_proxy(proxy)
        self._player.configure_proxy(proxy)

    def _on_fetched(self, sub_id: str, content: str | None, error: str) -> None:
        self._manager.on_fetch_completed(sub_id, content, error)
        self._sub_model.notify_item(sub_id)
        self._dec_busy()
        if error:
            logger.error("获取订阅失败 subscription_id=%s error=%s", sub_id, error)
            self.errorOccurred.emit("获取失败", error)

    def _on_channels_changed(self) -> None:
        self._push_channels()

    def _push_channels(self) -> None:
        self._channel_model.replace_all(self._manager.all_channels)
        self.channelsChanged.emit()
