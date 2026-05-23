import logging

from PySide6.QtCore import QObject, Signal, QTimer
from PySide6.QtNetwork import (
    QNetworkAccessManager,
    QNetworkProxy,
    QNetworkRequest,
    QNetworkReply,
)

logger = logging.getLogger(__name__)

_PROXY_TYPE_MAP = {
    "http": QNetworkProxy.ProxyType.HttpProxy,
    "socks5": QNetworkProxy.ProxyType.Socks5Proxy,
}


class Fetcher(QObject):
    fetched = Signal(str, object, str)  # subscription_id, content_or_None, error_or_empty
    _TIMEOUT_MS = 30_000

    def __init__(self, parent: QObject | None = None):
        super().__init__(parent)
        self._nam = QNetworkAccessManager(self)

    def configure_proxy(self, proxy: dict) -> None:
        """根据配置字典设置代理，enabled=False 时关闭代理。"""
        if not proxy.get("enabled"):
            self._nam.setProxy(QNetworkProxy(QNetworkProxy.ProxyType.NoProxy))
            return
        proxy_type = _PROXY_TYPE_MAP.get(proxy.get("type", "http"), QNetworkProxy.ProxyType.HttpProxy)
        host = proxy.get("host", "")
        port = proxy.get("port", 0)
        if host and port:
            self._nam.setProxy(QNetworkProxy(proxy_type, host, port))
            logger.info("代理已设置 type=%s host=%s port=%s", proxy.get("type"), host, port)
        else:
            logger.warning("代理已启用但 host/port 无效，已忽略")

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
            reply.deleteLater()
            timer.deleteLater()

        def on_timeout():
            logger.warning("抓取超时 subscription_id=%s", subscription_id)
            reply.abort()
            self.fetched.emit(subscription_id, None, "请求超时")
            reply.deleteLater()
            timer.deleteLater()

        timer.timeout.connect(on_timeout)
        reply.finished.connect(on_finished)
        timer.start(self._TIMEOUT_MS)


def _reply_error(reply: QNetworkReply) -> str:
    if reply.error() == QNetworkReply.NetworkError.NoError:
        return ""
    return reply.errorString()
