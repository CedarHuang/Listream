import logging

from PySide6.QtCore import QObject, QUrl, Signal, QTimer
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

# 抓取来源标签。同一个订阅可能同时有多个请求在飞（例如「添加订阅」与「全部刷新」
# 撞在一起），完成信号只带 subscription_id 无法分辨是哪一笔，所以把来源挂在请求上、
# 随开始与完成两道信号一起回来，由监听方按同一标签记账与消账。
REASON_ADD = "add"                  # 添加订阅
REASON_REFRESH_ALL = "refresh_all"  # 全部刷新
REASON_BACKGROUND = "background"    # 单条刷新 / 编辑后重抓 / 启动刷新


class Fetcher(QObject):
    fetchStarted = Signal(str, str)  # subscription_id, reason
    fetched = Signal(str, object, str, str)  # subscription_id, content_or_None, error_or_empty, reason
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

    def fetch(self, subscription_id: str, url: str, reason: str = REASON_BACKGROUND) -> None:
        # 先广播开始，再抓取：本地文件是同步读取的，监听方必须在收到完成信号
        # 之前就进入「刷新中」，否则刷新按钮会永远停在加载态。
        self.fetchStarted.emit(subscription_id, reason)
        if url.startswith("file://"):
            self._fetch_local(subscription_id, url, reason)
        else:
            self._fetch_remote(subscription_id, url, reason)

    def _fetch_local(self, subscription_id: str, url: str, reason: str) -> None:
        path = QUrl(url).toLocalFile()
        logger.info("读取本地文件 subscription_id=%s path=%s", subscription_id, path)
        content, error = _read_local_file(path)
        if error:
            logger.error("读取本地文件失败 subscription_id=%s path=%s error=%s", subscription_id, path, error)
            self.fetched.emit(subscription_id, None, error, reason)
            return
        logger.info("本地文件读取成功 subscription_id=%s size=%d", subscription_id, len(content))
        self.fetched.emit(subscription_id, content, "", reason)

    def _fetch_remote(self, subscription_id: str, url: str, reason: str) -> None:
        logger.info("开始抓取 subscription_id=%s url=%s", subscription_id, url)
        reply = self._nam.get(QNetworkRequest(url))
        timer = QTimer(self)
        timer.setSingleShot(True)
        timed_out = False
        finished_emitted = False

        def on_finished():
            # 唯一收口点：正常结束、失败、abort 都汇到这里，保证一次 fetch 只发一次 fetched。
            # 重复完成会让监听方多消一次账，busy / refreshingAll 提前熄灭。
            nonlocal finished_emitted
            if finished_emitted:
                return
            finished_emitted = True
            timer.stop()
            err = "请求超时" if timed_out else _reply_error(reply)
            if err:
                logger.error("抓取失败 subscription_id=%s error=%s", subscription_id, err)
                self.fetched.emit(subscription_id, None, err, reason)
            else:
                raw = bytes(reply.readAll()).decode("utf-8", errors="replace")
                logger.info("抓取成功 subscription_id=%s size=%d", subscription_id, len(raw))
                self.fetched.emit(subscription_id, raw, "", reason)
            reply.deleteLater()
            timer.deleteLater()

        def on_timeout():
            nonlocal timed_out
            timed_out = True
            logger.warning("抓取超时 subscription_id=%s", subscription_id)
            reply.abort()  # 触发 finished，由收口点统一通知
            if not finished_emitted:
                # abort 未同步触发 finished 时的兜底；重复调用由 finished_emitted 挡住
                on_finished()

        timer.timeout.connect(on_timeout)
        reply.finished.connect(on_finished)
        timer.start(self._TIMEOUT_MS)


def _read_local_file(path: str) -> tuple[str | None, str]:
    """读取本地 M3U 文本，返回 (内容, 错误信息)，成功时错误信息为空。

    任何失败都必须转成错误信息返回、不得抛出：调用方在发出 fetchStarted 之后，
    依赖「开始—完成」必定配对来记账，一旦这里抛异常，这笔账就永远消不掉，
    该订阅会一直停在刷新态。因此这里连非 OSError 的异常（例如路径含 NUL 时
    open() 抛的 ValueError）也一并兜住。
    """
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read(), ""
    except FileNotFoundError:
        return None, "文件不存在"
    except PermissionError:
        return None, "文件无读取权限"
    except Exception as e:
        return None, str(e)


def _reply_error(reply: QNetworkReply) -> str:
    if reply.error() == QNetworkReply.NetworkError.NoError:
        return ""
    return reply.errorString()
