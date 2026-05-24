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
        self._cached: set[str] = set()

    def warm(self) -> None:
        try:
            self._cached = {f.name for f in self._dir.iterdir() if f.is_file()}
        except FileNotFoundError:
            self._cached = set()

    def resolve(self, url: str) -> str:
        if not url:
            return ""
        path = self._path_for(url)
        if path.name in self._cached:
            return path.as_uri()
        if path.exists():
            self._cached.add(path.name)
            return path.as_uri()
        return url

    def prefetch(self, urls: list[str]) -> None:
        for url in urls:
            if not url or url in self._active or self._path_for(url).name in self._cached:
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
            self._cached.add(path.name)
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
