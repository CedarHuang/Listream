import logging

from PySide6.QtCore import QObject, Signal, Slot

from ..services.subscription_manager import SubscriptionManager
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

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channel_model = ChannelListModel(self)
        self._filter_model = ChannelFilterModel(self)
        self._filter_model.setSourceModel(self._channel_model)
        self._sub_model = SubscriptionListModel(self)
        self._player = PlayerController(self)
        self._fetcher = Fetcher(self)
        self._fetcher.fetched.connect(self._on_fetched)
        self._manager = SubscriptionManager(self._fetcher)
        self._manager.set_on_channels_changed(self._on_channels_changed)
        self._last_channel = load_last_channel()

    @property
    def channelModel(self):
        return self._filter_model

    @property
    def subscriptionModel(self):
        return self._sub_model

    @property
    def player(self) -> PlayerController:
        return self._player

    @property
    def lastChannelUrl(self) -> str:
        if self._last_channel:
            return self._last_channel.get("url", "")
        return ""

    @property
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

    @Slot(str, str)
    def addSubscription(self, name: str, url: str) -> None:
        logger.info("添加订阅 name=%s url=%s", name, url)
        self._manager.add(name, url)
        self._sub_model.replace_all(self._manager.subscriptions)

    @Slot(str)
    def removeSubscription(self, sub_id: str) -> None:
        logger.info("删除订阅 subscription_id=%s", sub_id)
        self._manager.remove(sub_id)
        self._sub_model.replace_all(self._manager.subscriptions)

    @Slot(str)
    def refreshSubscription(self, sub_id: str) -> None:
        self._manager.refresh(sub_id)

    @Slot()
    def refreshAll(self) -> None:
        self._manager.refresh_all()

    @Slot(str, str)
    def playChannel(self, url: str, name: str) -> None:
        save_last_channel(url, name)
        self._player.play(url, name)

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

    def _on_fetched(self, sub_id: str, content: str | None, error: str) -> None:
        self._manager.on_fetch_completed(sub_id, content, error)
        if error:
            logger.error("获取订阅失败 subscription_id=%s error=%s", sub_id, error)
            self.errorOccurred.emit("获取失败", error)

    def _on_channels_changed(self) -> None:
        self._push_channels()
        self._sub_model.replace_all(self._manager.subscriptions)

    def _push_channels(self) -> None:
        self._channel_model.replace_all(self._manager.all_channels)
        self.channelsChanged.emit()
