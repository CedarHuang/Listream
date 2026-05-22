import ctypes
import ctypes.wintypes
import os

from PySide6.QtCore import Signal, Slot, QPointF
from PySide6.QtQuick import QQuickItem
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "Listream.QmlItems"
QML_IMPORT_MAJOR_VERSION = 1

_user32 = ctypes.windll.user32

_GWL_STYLE = -16
_WS_CAPTION = 0x00C00000
_WS_SYSMENU = 0x00080000
_WS_THICKFRAME = 0x00040000
_WS_CHILD = 0x40000000
_WS_CLIPCHILDREN = 0x02000000
_WS_CLIPSIBLINGS = 0x04000000
_SWP_NOZORDER = 0x0004
_SWP_NOACTIVATE = 0x0010
_SWP_SHOWWINDOW = 0x0040
_SWP_HIDEWINDOW = 0x0080


@QmlElement
class MpvRenderer(QQuickItem):
    statusChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._mpv = None
        self._mpv_hwnd = 0
        self._parent_hwnd = 0
        self._scene_attached = False
        self._pending_url = ""

    def componentComplete(self):
        super().componentComplete()
        try:
            import mpv
        except ImportError:
            self.statusChanged.emit("error:mpv 库未安装")
            return
        try:
            self._mpv = mpv.MPV(
                vo="gpu",
                hwdec="auto-safe",
                keep_open="yes",
                osc="no",
                input_cursor="no",
                input_default_bindings="no",
                volume=80,
            )
            self._mpv.observe_property("pause", self._on_pause)
            self._mpv.observe_property("eof-reached", self._on_eof)
        except Exception as e:
            self.statusChanged.emit(f"error:{e}")

    def itemChange(self, change, value):
        if change == QQuickItem.ItemSceneChange:
            if value is not None and not self._scene_attached:
                self._on_scene_attached(value)
                self._scene_attached = True
        return super().itemChange(change, value)

    def geometryChange(self, new_geo, old_geo):
        super().geometryChange(new_geo, old_geo)
        self._sync_geometry()

    def _on_scene_attached(self, window):
        win_hwnd = int(window.winId())
        self._parent_hwnd = win_hwnd
        if self._mpv is None:
            return
        self._find_and_reparent_mpv()
        self._sync_geometry()

    def _find_and_reparent_mpv(self):
        hwnd = _find_mpv_window()
        if not hwnd:
            import time
            time.sleep(0.1)
            hwnd = _find_mpv_window()
        if not hwnd:
            self.statusChanged.emit("error:未找到 mpv 窗口")
            return
        self._mpv_hwnd = hwnd
        _user32.SetParent(hwnd, self._parent_hwnd)
        style = _user32.GetWindowLongW(hwnd, _GWL_STYLE)
        style &= ~(_WS_CAPTION | _WS_SYSMENU | _WS_THICKFRAME)
        style |= _WS_CHILD | _WS_CLIPCHILDREN | _WS_CLIPSIBLINGS
        _user32.SetWindowLongW(hwnd, _GWL_STYLE, style)
        self.statusChanged.emit("idle")

    def _sync_geometry(self):
        if not self._mpv_hwnd or not self._parent_hwnd:
            return
        p = self.mapToScene(QPointF(0, 0))
        ratio = self.window().devicePixelRatio() if self.window() else 1.0
        x = int(p.x() * ratio)
        y = int(p.y() * ratio)
        w = int(self.width() * ratio)
        h = int(self.height() * ratio)
        _user32.SetWindowPos(
            self._mpv_hwnd, 0, x, y, w, h,
            _SWP_NOZORDER | _SWP_NOACTIVATE,
        )

    def _on_pause(self, name, value):
        if value:
            self.statusChanged.emit("paused")
        else:
            self.statusChanged.emit("playing")

    def _on_eof(self, name, value):
        if value:
            self.statusChanged.emit("stopped")

    def _ensure_visible(self):
        if self._mpv_hwnd:
            _user32.SetWindowPos(
                self._mpv_hwnd, 0, 0, 0, 0, 0,
                _SWP_NOZORDER | _SWP_NOACTIVATE | _SWP_SHOWWINDOW,
            )

    def _ensure_hidden(self):
        if self._mpv_hwnd:
            _user32.SetWindowPos(
                self._mpv_hwnd, 0, 0, 0, 0, 0,
                _SWP_NOZORDER | _SWP_NOACTIVATE | _SWP_HIDEWINDOW,
            )

    @Slot(str)
    def play(self, url: str) -> None:
        if self._mpv:
            self._mpv.play(url)
            self._ensure_visible()
            self.statusChanged.emit("loading")

    @Slot()
    def stop(self) -> None:
        if self._mpv:
            self._mpv.stop()
        self._ensure_hidden()
        self.statusChanged.emit("stopped")

    @Slot()
    def togglePause(self) -> None:
        if self._mpv:
            self._mpv.pause = not self._mpv.pause

    @Slot(float)
    def setVolume(self, vol: float) -> None:
        if self._mpv:
            self._mpv.volume = int(vol * 100)


def _find_mpv_window() -> int:
    pid = os.getpid()
    result = 0
    WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.wintypes.HWND, ctypes.wintypes.LPARAM)

    def callback(hwnd, lparam):
        nonlocal result
        window_pid = ctypes.wintypes.DWORD()
        _user32.GetWindowThreadProcessId(hwnd, ctypes.byref(window_pid))
        if window_pid.value != pid:
            return True
        class_name = ctypes.create_unicode_buffer(256)
        _user32.GetClassNameW(hwnd, class_name, 256)
        if class_name.value == "mpv":
            result = hwnd
            return False
        return True

    _user32.EnumWindows(WNDENUMPROC(callback), 0)
    return result
