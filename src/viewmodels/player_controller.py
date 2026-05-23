import logging

from PySide6.QtCore import QObject, Signal, Slot, Property

logger = logging.getLogger(__name__)


class PlayerController(QObject):
    volumeChanged = Signal()
    titleChanged = Signal()
    statusChanged = Signal(str)
    urlChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._volume = 0.8
        self._title = ""
        self._url = ""
        self._status = "idle"
        self._renderer = None
        self._proxy = {}

    def set_renderer(self, renderer) -> None:
        self._renderer = renderer
        if renderer is not None:
            renderer.statusChanged.connect(self._on_renderer_status)
            if self._proxy:
                renderer.configure_proxy(self._proxy)

    def configure_proxy(self, proxy: dict) -> None:
        self._proxy = proxy
        if self._renderer:
            self._renderer.configure_proxy(proxy)

    def _on_renderer_status(self, status: str) -> None:
        self._status = status
        if status.startswith("error:"):
            logger.error("渲染器错误: %s", status)
        self.statusChanged.emit(status)

    @Property(float, notify=volumeChanged)
    def volume(self) -> float:
        return self._volume

    @volume.setter
    def volume(self, v: float) -> None:
        if self._volume != v:
            self._volume = v
            self.volumeChanged.emit()
            if self._renderer:
                self._renderer.setVolume(v)

    @Property(str, notify=titleChanged)
    def title(self) -> str:
        return self._title

    @Property(str, notify=urlChanged)
    def currentUrl(self) -> str:
        return self._url

    @Slot(str, str)
    def play(self, url: str, title: str) -> None:
        logger.info("播放 title=%s", title)
        self._title = title
        self._url = url
        self.titleChanged.emit()
        self.urlChanged.emit()
        if self._renderer:
            self._renderer.play(url)

    @Slot()
    def stop(self) -> None:
        logger.info("停止播放")
        self._url = ""
        self.urlChanged.emit()
        if self._renderer:
            self._renderer.stop()

    @Slot()
    def togglePause(self) -> None:
        if self._renderer:
            self._renderer.togglePause()

    @Property(str, notify=statusChanged)
    def status(self) -> str:
        return self._status
