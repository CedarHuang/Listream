from PySide6.QtCore import QObject, Signal, Slot, Property


class PlayerController(QObject):
    volumeChanged = Signal()
    titleChanged = Signal()
    statusChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._volume = 0.8
        self._title = ""
        self._status = "idle"
        self._renderer = None

    def set_renderer(self, renderer) -> None:
        self._renderer = renderer
        if renderer is not None:
            renderer.statusChanged.connect(self._on_renderer_status)

    def _on_renderer_status(self, status: str) -> None:
        self._status = status
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

    @Slot(str, str)
    def play(self, url: str, title: str) -> None:
        self._title = title
        self.titleChanged.emit()
        if self._renderer:
            self._renderer.play(url)

    @Slot()
    def stop(self) -> None:
        if self._renderer:
            self._renderer.stop()

    @Slot()
    def togglePause(self) -> None:
        if self._renderer:
            self._renderer.togglePause()

    @Property(str, notify=statusChanged)
    def status(self) -> str:
        return self._status
