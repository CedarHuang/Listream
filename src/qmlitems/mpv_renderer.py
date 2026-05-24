import ctypes
import logging

from PySide6.QtCore import QTimer, Signal, Slot
from PySide6.QtGui import QOpenGLContext
from PySide6.QtQuick import QQuickFramebufferObject
from PySide6.QtQml import QmlElement

logger = logging.getLogger(__name__)

QML_IMPORT_NAME = "Listream.QmlItems"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class MpvRenderer(QQuickFramebufferObject):
    statusChanged = Signal(str)
    onFrameReady = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._mpv = None
        self._proxy = {}
        self._volume = 80
        self._mpv_ok = True
        self.onFrameReady.connect(self._do_update)

    def componentComplete(self):
        super().componentComplete()
        try:
            __import__("mpv")
        except ImportError:
            self._mpv_ok = False
            logger.error("mpv 库未安装")
            self.statusChanged.emit("error:mpv 库未安装")

    def createRenderer(self):
        self._init_mpv()
        return self._Renderer(self)

    @Slot()
    def _do_update(self):
        self.update()

    # ---- QML API (主线程 safe) ----

    @Slot(str)
    def play(self, url: str) -> None:
        if self._mpv:
            logger.info("mpv 播放 url=%s", url)
            self._mpv.play(url)
            self.statusChanged.emit("loading")
            self._wait_playing(0)

    def _wait_playing(self, attempts: int) -> None:
        if not self._mpv:
            return
        try:
            if self._mpv.playback_time is not None:
                self.statusChanged.emit("playing")
                return
        except Exception:
            pass
        if attempts < 120:
            QTimer.singleShot(100, lambda: self._wait_playing(attempts + 1))
        else:
            if not self._mpv.pause:
                self.statusChanged.emit("playing")

    @Slot()
    def stop(self) -> None:
        if self._mpv:
            logger.info("mpv 停止")
            self._mpv.stop()
        self.statusChanged.emit("stopped")

    @Slot()
    def togglePause(self) -> None:
        if self._mpv:
            self._mpv.pause = not self._mpv.pause

    @Slot(float)
    def setVolume(self, vol: float) -> None:
        self._volume = int(vol * 100)
        if self._mpv:
            self._mpv.volume = self._volume

    def configure_proxy(self, proxy: dict) -> None:
        self._proxy = proxy
        if self._mpv:
            if proxy.get("enabled") and proxy.get("type") == "http":
                url = f"http://{proxy['host']}:{proxy['port']}"
                self._mpv["http-proxy"] = url
                logger.info("mpv 代理已设置 %s", url)
            else:
                self._mpv["http-proxy"] = ""

    # ---- 内部 ----

    def _init_mpv(self):
        if self._mpv or not self._mpv_ok:
            return
        try:
            import mpv

            opts = {
                "vo": "libmpv",
                "hwdec": "auto-safe",
                "keep_open": "yes",
                "osc": "no",
                "input_cursor": "no",
                "input_default_bindings": "no",
                "volume": self._volume,
            }
            if self._proxy.get("enabled") and self._proxy.get("type") == "http":
                opts["http-proxy"] = f"http://{self._proxy['host']}:{self._proxy['port']}"

            self._mpv = mpv.MPV(**opts)
            self._mpv.observe_property("pause", self._on_pause)
            self._mpv.observe_property("eof-reached", self._on_eof)
            logger.info("mpv(libmpv) 已初始化")
            self.statusChanged.emit("idle")
        except Exception as e:
            logger.error("mpv 初始化失败: %s", e)
            self._mpv_ok = False
            self.statusChanged.emit(f"error:{e}")

    def _on_pause(self, _name, value):
        if value:
            self.statusChanged.emit("paused")
        else:
            self.statusChanged.emit("playing")

    def _on_eof(self, _name, value):
        if value:
            self.statusChanged.emit("stopped")

    # ---- Renderer ----

    class _Renderer(QQuickFramebufferObject.Renderer):
        def __init__(self, parent: "MpvRenderer"):
            super().__init__()
            self._parent = parent
            self._ctx = None

        def render(self):
            if not self._parent._mpv_ok:
                return
            mpv = self._parent._mpv
            if not mpv:
                return

            if self._ctx is None:
                self._ctx = self._create_render_context(mpv)
                if self._ctx is None:
                    return
                self.update()
                return

            fbo = self.framebufferObject()
            if fbo is None:
                return
            scale = self._parent.window().devicePixelRatio() if self._parent.window() else 1.0
            w = max(1, int(self._parent.width() * scale))
            h = max(1, int(self._parent.height() * scale))
            fbo_id = fbo.handle()
            if fbo_id == 0:
                return
            self._ctx.render(
                flip_y=False,
                opengl_fbo={"w": w, "h": h, "fbo": fbo_id},
            )

        def _create_render_context(self, mpv):
            import mpv as mpv_mod

            ProcAddr = ctypes.CFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p, ctypes.c_char_p)

            def _get_proc(_ctx, name):
                gl_ctx = QOpenGLContext.currentContext()
                if gl_ctx is None:
                    return 0
                addr = gl_ctx.getProcAddress(name)
                return int(addr) if addr else 0

            get_proc = ProcAddr(_get_proc)

            try:
                ctx = mpv_mod.MpvRenderContext(
                    mpv,
                    "opengl",
                    opengl_init_params={"get_proc_address": get_proc},
                )
                ctx.update_cb = self._parent.onFrameReady.emit
                logger.info("mpv render context 已创建")
                return ctx
            except Exception as e:
                logger.error("mpv render context 创建失败: %s", e)
                return None
