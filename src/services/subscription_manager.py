import logging
from datetime import datetime, timedelta, timezone

logger = logging.getLogger(__name__)

from .storage import (
    ensure_dirs,
    load_config,
    save_config,
    load_channel_cache,
    save_channel_cache,
    delete_channel_cache,
)
from .m3u_parser import parse_m3u
from .fetcher import Fetcher
from .logo_cache import LogoCache
from ..models.subscription import Subscription
from ..models.channel import Channel


class SubscriptionManager:
    def __init__(self, fetcher: Fetcher | None = None, logo_cache: LogoCache | None = None):
        ensure_dirs()
        self._fetcher = fetcher
        self._logo_cache = logo_cache
        self._subscriptions: list[Subscription] = []
        self._all_channels: list[Channel] = []
        self._on_channels_changed = None

    @property
    def subscriptions(self) -> list[Subscription]:
        return list(self._subscriptions)

    @property
    def all_channels(self) -> list[Channel]:
        return list(self._all_channels)

    def set_on_channels_changed(self, callback) -> None:
        self._on_channels_changed = callback

    def load(self) -> None:
        data = load_config()
        sub_dicts = data.get("subscriptions", [])
        self._subscriptions = [Subscription.from_dict(d) for d in sub_dicts]
        self._rebuild_channels()

    def add(self, name: str, url: str) -> Subscription:
        sub = Subscription(name=name, url=url)
        self._subscriptions.append(sub)
        logger.info("添加订阅 name=%s url=%s", name, url)
        self._persist()
        self._schedule_fetch(sub)
        return sub

    def remove(self, subscription_id: str) -> None:
        self._subscriptions = [
            s for s in self._subscriptions if s.id != subscription_id
        ]
        logger.info("删除订阅 subscription_id=%s", subscription_id)
        delete_channel_cache(subscription_id)
        self._persist()
        self._rebuild_channels()

    def update(self, subscription_id: str, name: str, url: str) -> None:
        for s in self._subscriptions:
            if s.id == subscription_id:
                s.name = name
                s.url = url
                logger.info("更新订阅 subscription_id=%s name=%s url=%s", subscription_id, name, url)
                self._persist()
                self._schedule_fetch(s)
                return

    def set_enabled(self, subscription_id: str, enabled: bool) -> None:
        for s in self._subscriptions:
            if s.id == subscription_id:
                s.enabled = enabled
                logger.info("切换订阅 subscription_id=%s enabled=%s", subscription_id, enabled)
                self._persist()
                self._rebuild_channels()
                return

    def refresh(self, subscription_id: str) -> None:
        for s in self._subscriptions:
            if s.id == subscription_id:
                self._schedule_fetch(s)
                return

    def refresh_all(self) -> None:
        for s in self._subscriptions:
            if s.enabled:
                self._schedule_fetch(s)

    def startup_refresh(self) -> None:
        threshold = datetime.now(timezone.utc) - timedelta(hours=12)
        for s in self._subscriptions:
            if not s.enabled:
                continue
            if s.last_updated:
                try:
                    last = datetime.fromisoformat(s.last_updated)
                    if last > threshold:
                        continue
                except ValueError:
                    pass
            self._schedule_fetch(s)

    def _schedule_fetch(self, sub: Subscription) -> None:
        if self._fetcher is None:
            return
        self._fetcher.fetch(sub.id, sub.url)

    def on_fetch_completed(
        self, subscription_id: str, content: str | None, error: str
    ) -> None:
        for s in self._subscriptions:
            if s.id == subscription_id:
                if error:
                    s.error_message = error
                    self._persist()
                    return
                if content is not None:
                    channels = parse_m3u(content, subscription_id)
                    s.channel_count = len(channels)
                    s.last_updated = datetime.now(timezone.utc).isoformat()
                    s.error_message = ""
                    logger.info("解析完成 subscription_id=%s channel_count=%d", subscription_id, len(channels))
                    save_channel_cache(
                        subscription_id,
                        [ch.to_dict() for ch in channels],
                    )
                    self._persist()
                    self._rebuild_channels()
                return

    def _rebuild_channels(self) -> None:
        all_ch: list[Channel] = []
        logo_urls: list[str] = []
        for s in self._subscriptions:
            if not s.enabled:
                continue
            cached = load_channel_cache(s.id)
            if cached:
                for d in cached:
                    url = d.get("logo", "")
                    if url and self._logo_cache:
                        resolved = self._logo_cache.resolve(url)
                        d["logo"] = resolved
                        if url == resolved:
                            logo_urls.append(url)
                all_ch.extend(Channel.from_dict(d) for d in cached)
        self._all_channels = all_ch
        if self._on_channels_changed:
            self._on_channels_changed()
        if self._logo_cache and logo_urls:
            self._logo_cache.prefetch(logo_urls)

    def _persist(self) -> None:
        data = load_config()
        data["subscriptions"] = [s.to_dict() for s in self._subscriptions]
        save_config(data)
