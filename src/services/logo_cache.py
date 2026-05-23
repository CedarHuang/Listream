import hashlib
import logging
from pathlib import Path

from PySide6.QtCore import QObject, QUrl, Signal
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkReply, QNetworkRequest

from .storage import logo_cache_dir

logger = logging.getLogger(__name__)


class LogoCache(QObject):
    allDone = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._dir = logo_cache_dir()
        self._nam = QNetworkAccessManager(self)
        self._pending = 0
        self._active: set[str] = set()

    def resolve(self, url: str) -> str:
        """已有缓存返回 file:// 路径，否则返回原始 URL。"""
        if not url:
            return ""
        path = self._path_for(url)
        return path.as_uri() if path.exists() else url

    def prefetch(self, urls: list[str]) -> None:
        """后台下载未缓存的 logo，跳过已在下载的 URL。"""
        for url in urls:
            if not url or url in self._active or self._path_for(url).exists():
                continue
            self._active.add(url)
            self._pending += 1
            reply = self._nam.get(QNetworkRequest(QUrl(url)))
            reply.finished.connect(lambda r=reply, u=url: self._on_done(r, u))

    def _on_done(self, reply: QNetworkReply, url: str) -> None:
        self._active.discard(url)
        path = self._path_for(url)
        if reply.error() == QNetworkReply.NetworkError.NoError:
            path.write_bytes(bytes(reply.readAll()))
        else:
            logger.debug("logo 下载失败 url=%s error=%s", url, reply.errorString())
        reply.deleteLater()
        self._pending -= 1
        if self._pending <= 0:
            self._pending = 0
            self.allDone.emit()

    def _path_for(self, url: str) -> Path:
        h = hashlib.sha256(url.encode()).hexdigest()[:16]
        ext = Path(url.partition("?")[0]).suffix or ".png"
        return self._dir / f"{h}{ext}"
