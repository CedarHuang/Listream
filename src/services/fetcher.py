import logging

from PySide6.QtCore import QObject, Signal, QTimer
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkRequest, QNetworkReply

logger = logging.getLogger(__name__)


class Fetcher(QObject):
    fetched = Signal(str, object, str)  # subscription_id, content_or_None, error_or_empty
    _TIMEOUT_MS = 30_000

    def __init__(self, parent: QObject | None = None):
        super().__init__(parent)
        self._nam = QNetworkAccessManager(self)

    def fetch(self, subscription_id: str, url: str) -> None:
        logger.info("开始抓取 subscription_id=%s url=%s", subscription_id, url)
        reply = self._nam.get(QNetworkRequest(url))
        timer = QTimer(self)
        timer.setSingleShot(True)

        def on_finished():
            timer.stop()
            err = _reply_error(reply)
            if err:
                logger.error("抓取失败 subscription_id=%s error=%s", subscription_id, err)
                self.fetched.emit(subscription_id, None, err)
            else:
                raw = bytes(reply.readAll()).decode("utf-8", errors="replace")
                logger.info("抓取成功 subscription_id=%s size=%d", subscription_id, len(raw))
                self.fetched.emit(subscription_id, raw, "")

        def on_timeout():
            logger.warning("抓取超时 subscription_id=%s", subscription_id)
            reply.abort()
            self.fetched.emit(subscription_id, None, "请求超时")

        timer.timeout.connect(on_timeout)
        reply.finished.connect(on_finished)
        timer.start(self._TIMEOUT_MS)


def _reply_error(reply: QNetworkReply) -> str:
    if reply.error() == QNetworkReply.NetworkError.NoError:
        return ""
    return reply.errorString()
