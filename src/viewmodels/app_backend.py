import logging
from collections import Counter

from PySide6.QtCore import Property, QObject, QTimer, Signal, Slot

from ..services.subscription_manager import SubscriptionManager
from ..services.logo_cache import LogoCache
from ..services.fetcher import Fetcher, REASON_BACKGROUND, REASON_REFRESH_ALL
from ..services.storage import (
    load_last_channel,
    save_last_channel,
    load_proxy_config,
    save_proxy_config,
)
from .channel_list_model import ChannelListModel, ChannelFilterModel
from .subscription_list_model import SubscriptionListModel
from .player_controller import PlayerController
from .window_state import WindowState

logger = logging.getLogger(__name__)


class AppBackend(QObject):
    channelsChanged = Signal()
    subscriptionsChanged = Signal()
    errorOccurred = Signal(str, str)
    lastChannelChanged = Signal()
    busyChanged = Signal()
    refreshingAllChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channel_model = ChannelListModel(self)
        self._filter_model = ChannelFilterModel(self)
        self._filter_model.setSourceModel(self._channel_model)
        self._sub_model = SubscriptionListModel(self)
        self._player = PlayerController(self)
        self._window_state = WindowState(self)
        self._fetcher = Fetcher(self)
        self._fetcher.fetchStarted.connect(self._on_fetch_started)
        self._fetcher.fetched.connect(self._on_fetched)
        self._logo_cache = LogoCache(self)
        self._manager = SubscriptionManager(self._fetcher, self._logo_cache)
        self._manager.set_on_channels_changed(self._on_channels_changed)
        self._last_channel = load_last_channel()
        # 未完成的抓取账本：reason -> 在飞请求数。每一笔都在 fetchStarted 里记下、
        # 在 fetched 里凭同一个 reason 消掉，所以既不会漏消（UI 永久卡住），
        # 也不会被别的来源的完成信号误消（提前熄灭）。
        self._pending: Counter[str] = Counter()

    @Property(bool, notify=busyChanged)
    def busy(self) -> bool:
        """有由 UI 发起、会阻塞全局操作的抓取在进行（添加订阅 / 全部刷新）。

        单条订阅的刷新、编辑后重抓、启动刷新都走 REASON_BACKGROUND，只反映在
        订阅列表的 refreshing 角色上，不占用全局 busy。
        """
        return any(n for reason, n in self._pending.items() if reason != REASON_BACKGROUND)

    @Property(bool, notify=refreshingAllChanged)
    def refreshingAll(self) -> bool:
        """全部刷新批次自身是否还有在飞请求。

        与 busy 解耦：刷新期间添加订阅，批次跑完转圈就停，而按钮仍因 busy 保持禁用。
        这里由账本推导而非锁存，本地文件与远程混排时也不会留下「已归零」的假状态。
        """
        return self._pending[REASON_REFRESH_ALL] > 0

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
    def windowState(self) -> WindowState:
        return self._window_state

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
        self._logo_cache.warm()
        self._manager.load()
        self._sub_model.replace_all(self._manager.subscriptions)
        QTimer.singleShot(0, self._load_channels_deferred)
        self._manager.startup_refresh()

    def _load_channels_deferred(self) -> None:
        self._manager.rebuild_channels()
        self._push_channels()

    def _apply_proxy(self) -> None:
        proxy = load_proxy_config()
        if proxy:
            self._fetcher.configure_proxy(proxy)
            self._player.configure_proxy(proxy)

    @Slot(str, str)
    def addSubscription(self, name: str, url: str) -> None:
        logger.info("添加订阅 name=%s url=%s", name, url)
        # 记账发生在 fetchStarted（见 _acquire），这里不必提前记账：本地文件订阅会在
        # add 内同步抓完，提前计数就得额外配对；add 中途抛异常也不会再留下未消的账。
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
        self._manager.refresh(sub_id)

    @Slot()
    def refreshAll(self) -> None:
        # 没有启用的订阅就没有任何抓取：此时进 loading 态就再也没人来关掉它。
        if not any(s.enabled for s in self._manager.subscriptions):
            return
        self._manager.refresh_all()

    @Slot(int, int)
    def moveSubscription(self, from_index: int, to_index: int) -> None:
        # 先更新模型发出动画信号，再更新管理器持久化
        if not self._sub_model.move_item(from_index, to_index):
            return
        self._manager.move_subscription(from_index, to_index)

    @Slot(str, str)
    def playChannel(self, url: str, name: str) -> None:
        save_last_channel(url, name)
        # 同步会话内的 lastChannel* 属性，否则封面「上次观看 / 继续播放」会停留在启动时的值
        self._last_channel = {"url": url, "name": name}
        self.lastChannelChanged.emit()
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
        self._player.configure_proxy(proxy)

    def _acquire(self, reason: str) -> None:
        """记一笔账，只有 busy / refreshingAll 这两个派生值真的翻转时才发通知。"""
        was = (self.busy, self.refreshingAll)
        self._pending[reason] += 1
        self._notify_if_flipped(was)

    def _release(self, reason: str) -> None:
        """消一笔账；未入账的来源（或余额已空）直接忽略，绝不误扣别人的账。"""
        if self._pending[reason] <= 0:
            return
        was = (self.busy, self.refreshingAll)
        self._pending[reason] -= 1
        if self._pending[reason] == 0:
            del self._pending[reason]
        self._notify_if_flipped(was)

    def _notify_if_flipped(self, was: tuple[bool, bool]) -> None:
        if self.busy != was[0]:
            self.busyChanged.emit()
        if self.refreshingAll != was[1]:
            self.refreshingAllChanged.emit()

    def _on_fetch_started(self, sub_id: str, reason: str) -> None:
        self._acquire(reason)
        self._sub_model.set_refreshing(sub_id, True)

    def _on_fetched(self, sub_id: str, content: str | None, error: str, reason: str) -> None:
        # 先消账再处理结果：后面的解析/落盘要是抛异常，也不能让这笔账永远挂着。
        self._release(reason)
        self._manager.on_fetch_completed(sub_id, content, error)
        self._sub_model.set_refreshing(sub_id, False)
        if error:
            logger.error("获取订阅失败 subscription_id=%s error=%s", sub_id, error)
            self.errorOccurred.emit("获取失败", error)

    def _on_channels_changed(self) -> None:
        self._push_channels()

    def _push_channels(self) -> None:
        self._channel_model.replace_all(self._manager.all_channels)
        self.channelsChanged.emit()
