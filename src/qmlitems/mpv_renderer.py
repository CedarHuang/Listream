import ctypes
import json
import logging

from PySide6.QtCore import Signal, Slot, Property
from PySide6.QtGui import QOpenGLContext
from PySide6.QtQuick import QQuickFramebufferObject
from PySide6.QtQml import QmlElement

logger = logging.getLogger(__name__)
_mpv_logger = logging.getLogger("mpv")

QML_IMPORT_NAME = "Listream.QmlItems"
QML_IMPORT_MAJOR_VERSION = 1

def _build_af(max_gain: int, target_rms: float) -> str:
    return f"lavfi=[dynaudnorm=f=500:g=7:m={max_gain}:r={target_rms}:o=0.72]"
_VF_FILTER = "lavfi=[cas=strength=0.6]"


@QmlElement
class MpvRenderer(QQuickFramebufferObject):
    statusChanged = Signal(str)
    cacheProgressChanged = Signal(float, float)
    onFrameReady = Signal()
    afEnabledChanged = Signal()
    afMaxGainChanged = Signal()
    afTargetRmsChanged = Signal()
    vfEnabledChanged = Signal()
    videoMetaChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._mpv = None
        self._proxy = {}
        self._volume = 80
        self._af_enabled = True
        self._af_max_gain = 2
        self._af_target_rms = 0.2
        self._vf_enabled = True
        self._mpv_ok = True
        self._play_count = 0
        self._loading = False
        self._loading_sn = 0
        self._playback_started = False
        self._video_meta = {}

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
            self._play_count += 1
            self._loading = True
            self._loading_sn = self._play_count
            self._playback_started = False
            self.statusChanged.emit("loading")
            self._mpv.play(url)

    def _clear_meta(self) -> None:
        self._video_meta = {}
        self.videoMetaChanged.emit()

    @Slot()
    def stop(self) -> None:
        if self._mpv:
            logger.info("mpv 停止")
            self._mpv.stop()
        self._loading = False
        self._playback_started = False
        self._clear_meta()
        self._emit_status("stopped")

    @Slot()
    def togglePause(self) -> None:
        if self._mpv:
            self._mpv.pause = not self._mpv.pause

    @Slot(int)
    def setVolume(self, vol: int) -> None:
        self._volume = vol
        if self._mpv:
            # mpv 内置三次方: gain=(mpv_vol/100)³
            # 叠加 0.5 次方后: gain=(slider/100)^1.5 → Stevens 定律感知线性最优
            self._mpv.volume = int((vol / 100.0) ** 0.5 * 100)

    @Property(bool, notify=afEnabledChanged)
    def afEnabled(self) -> bool:
        return self._af_enabled

    @afEnabled.setter
    def afEnabled(self, v: bool) -> None:
        if self._af_enabled != v:
            self._af_enabled = v
            self.afEnabledChanged.emit()
            self._apply_af()

    @Property(int, notify=afMaxGainChanged)
    def afMaxGain(self) -> int:
        return self._af_max_gain

    @afMaxGain.setter
    def afMaxGain(self, v: int) -> None:
        v = max(2, min(100, v))
        if self._af_max_gain != v:
            self._af_max_gain = v
            self.afMaxGainChanged.emit()
            self._apply_af()

    @Property(float, notify=afTargetRmsChanged)
    def afTargetRms(self) -> float:
        return self._af_target_rms

    @afTargetRms.setter
    def afTargetRms(self, v: float) -> None:
        v = round(max(0.0, min(1.0, v)), 1)
        if self._af_target_rms != v:
            self._af_target_rms = v
            self.afTargetRmsChanged.emit()
            self._apply_af()

    @Property(bool, notify=vfEnabledChanged)
    def vfEnabled(self) -> bool:
        return self._vf_enabled

    @vfEnabled.setter
    def vfEnabled(self, v: bool) -> None:
        if self._vf_enabled != v:
            self._vf_enabled = v
            self.vfEnabledChanged.emit()
            if self._mpv:
                self._mpv["deband"] = v
                self._mpv["scale"] = "ewa_lanczossharp" if v else "lanczos"
                self._mpv["vf"] = _VF_FILTER if v else ""

    @Property(str, notify=videoMetaChanged)
    def videoMeta(self) -> str:
        return json.dumps(self._video_meta, ensure_ascii=False)

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

    _META_PROPS = [
        "video-codec", "video-params/w", "video-params/h",
        "video-params/pixelformat", "hwdec-current", "estimated-vf-fps",
        "audio-codec", "audio-bitrate",
        "audio-params/samplerate", "audio-params/channel-count",
        "file-format",
    ]

    _COLOR_PROPS = ["video-params/primaries", "video-params/gamma"]

    def _collect_meta(self) -> None:
        if not self._mpv:
            return
        meta = {}
        for prop in self._META_PROPS:
            try:
                val = getattr(self._mpv, prop.replace("-", "_"))
                if val is not None:
                    meta[prop] = val
            except Exception:
                pass
        parts = []
        for prop in self._COLOR_PROPS:
            try:
                val = getattr(self._mpv, prop.replace("-", "_"))
                if val:
                    parts.append(str(val))
            except Exception:
                pass
        if parts:
            meta["colorspace"] = " / ".join(parts)
        if meta != self._video_meta:
            self._video_meta = meta
            self.videoMetaChanged.emit()

    def _af_filter(self) -> str:
        return _build_af(self._af_max_gain, self._af_target_rms) if self._af_enabled else ""

    def _apply_af(self) -> None:
        if self._mpv:
            self._mpv["af"] = self._af_filter()

    def _init_mpv(self):
        if self._mpv or not self._mpv_ok:
            return
        try:
            import mpv

            mpv_log_level = self._PY_TO_MPV.get(
                logging.getLogger().getEffectiveLevel(), "info"
            )
            opts = {
                "vo": "libmpv",
                "hwdec": "auto-safe",
                "keep_open": "yes",
                "osc": "no",
                "input_cursor": "no",
                "input_default_bindings": "no",
                "af": self._af_filter(),
                "vf": _VF_FILTER if self._vf_enabled else "",
                "deband": self._vf_enabled,
                "deband-iterations": 2,
                "deband-threshold": 40,
                "deband-grain": 6,
                "scale": "ewa_lanczossharp" if self._vf_enabled else "lanczos",
                "cscale": "spline36",
                "dscale": "mitchell",
                "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                "msg-level": f"all={mpv_log_level}",
            }
            if self._proxy.get("enabled") and self._proxy.get("type") == "http":
                opts["http-proxy"] = f"http://{self._proxy['host']}:{self._proxy['port']}"

            self._mpv = mpv.MPV(log_handler=self._on_mpv_log, loglevel=mpv_log_level, **opts)
            self._mpv.observe_property("pause", self._on_pause)
            self._mpv.observe_property("eof-reached", self._on_eof)
            self._mpv.observe_property("demuxer-cache-state", self._on_cache_state)
            self._mpv.observe_property("paused-for-cache", self._on_paused_for_cache)
            self._register_mpv_events()
            self.setVolume(self._volume)
            logger.info("mpv(libmpv) 已初始化")
            self.statusChanged.emit("idle")
        except Exception as e:
            logger.error("mpv 初始化失败: %s", e)
            self._mpv_ok = False
            self.statusChanged.emit(f"error:{e}")

    def _on_pause(self, _name, value):
        if self._loading or self._play_count == 0:
            return
        if value:
            logger.info("mpv 已暂停")
            self._emit_status("paused")
        else:
            logger.info("mpv 已恢复播放")
            self._emit_status("playing")

    def _on_eof(self, _name, value):
        if value and self._play_count > 0:
            if self._loading:
                return
            logger.info("mpv 播放结束 (EOF)")
            self._loading = False
            self._playback_started = False
            self._emit_status("stopped")

    def _on_cache_state(self, _name, value):
        if not value:
            return
        duration = value.get("cache-duration", 0) or 0
        speed = value.get("raw-input-rate", 0) or 0
        try:
            self.cacheProgressChanged.emit(float(duration), float(speed))
        except RuntimeError:
            pass

    def _on_paused_for_cache(self, _name, value):
        if value:
            if self._play_count == 0:
                return
            if not self._playback_started and not self._loading:
                return
            if self._loading:
                if self._loading_sn != self._play_count:
                    return
            logger.info("mpv 缓冲不足，暂停等待")
            self._emit_status("buffering")
        elif self._playback_started and self._play_count > 0:
            logger.info("mpv 缓冲完成，恢复播放")
            if self._mpv and self._mpv.pause:
                self._emit_status("paused")
            else:
                self._emit_status("playing")

    def _emit_status(self, status: str) -> None:
        try:
            self.statusChanged.emit(status)
        except RuntimeError:
            pass

    def _register_mpv_events(self):
        try:
            self._mpv.register_event_callback(self._on_mpv_event)
        except AttributeError:
            self._mpv.event_callback("end-file")(self._on_end_file_event)
            self._mpv.event_callback("playback-restart")(self._on_playback_restart)

    _PY_TO_MPV = {
        logging.FATAL: "fatal",
        logging.ERROR: "error",
        logging.WARN : "warn",
        logging.INFO : "info",
        logging.DEBUG: "v",
    }

    _MPV_LOG_MAP = {
        "fatal": logging.FATAL,
        "error": logging.ERROR,
        "warn" : logging.WARN,
        "info" : logging.INFO,
        "v"    : logging.DEBUG,
        "debug": logging.DEBUG,
        "trace": logging.DEBUG,
    }

    def _on_mpv_log(self, level: str, _prefix: str, text: str) -> None:
        text = text.strip()
        if not text:
            return
        py_level = self._MPV_LOG_MAP.get(level)
        if py_level is not None:
            _mpv_logger.log(py_level, "%s", text)

    @staticmethod
    def _err_text(code: int) -> str:
        try:
            import mpv
            return mpv.ErrorCode.human_readable(code)
        except Exception:
            return f"错误码 {code}"

    def _report_error(self, err_code: int) -> None:
        logger.warning("mpv 流错误: %s (code=%d)", self._err_text(err_code), err_code)

    def _handle_end_file(self, data) -> None:
        if data is None:
            return
        if data.reason == 4:  # ERROR
            self._report_error(data.error)
            self._emit_status("error:stream")
        elif data.reason == 0:  # EOF
            logger.info("mpv 流正常结束 (EOF)")
            self._clear_meta()
            if self._loading:
                self._loading = False
                self._emit_status("stopped")
        elif data.reason == 2:  # ABORTED
            logger.info("mpv 流被中断 (ABORTED)")

    def _handle_playback_restart(self) -> None:
        if self._loading and self._loading_sn == self._play_count:
            logger.info("mpv 播放已开始 (PLAYBACK_RESTART)")
            self._loading = False
            self._playback_started = True
            self._collect_meta()
            self._emit_status("playing")

    def _on_mpv_event(self, event):
        eid = event.event_id.value
        if eid == 7:  # END_FILE
            self._handle_end_file(event.data)
        elif eid == 21:  # PLAYBACK_RESTART
            self._handle_playback_restart()

    def _on_end_file_event(self, event):
        self._handle_end_file(event.data)

    def _on_playback_restart(self, event):
        self._handle_playback_restart()

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
