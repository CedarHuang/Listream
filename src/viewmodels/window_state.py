"""窗口状态管理 —— 最大化 / 最小化 / 全屏 的唯一真相源。

Windows 上没有独立的「全屏样式位」：全屏只是「覆盖整个显示器、无边界的窗口」，
而最大化由原生样式位 WS_MAXIMIZE 表达。QWindow.visibility() 是这套原生状态的
**有损投影**（把「全屏」「最大化」两个互斥值、「最小化」这个叠加态混在同一个四值
枚举里），Qt 的 normalGeometry() 则是恢复几何的派生缓存。

更关键的是：对无边框窗口，Qt 的 QWindow 状态设置器本身是有损的 ——
QWindow.showMinimized() 会先把窗口从全屏降级回 Windowed 再最小化，
于是「最小化 → 恢复」之后窗口既丢失了最大化也丢失了全屏（实测）。
而原生的 ShowWindow(SW_MINIMIZE) / SW_RESTORE 由操作系统维护完整状态：
最大化最小化再恢复仍是最大化，全屏最小化再恢复仍是全屏，且只有一次干净的状态跳变。

旧实现把记忆建在 Qt 的有损投影之上，于是不得不引入
_wasMaximized / _maximizedBeforeFullscreen / _prevVisibility 三个互相重叠的影子变量
去猜，这正是复杂度与 bug 的来源。

本模块因此确立两条规则：

1. **最大化与最小化走原生调用**（ShowWindow），操作系统负责保状态、保恢复几何；
   全屏没有原生等价物，仍由 Qt 负责。
2. **Qt 的可见性事件只用于对账**（reconcile）模型，绝不反向改写记忆，
   记忆只由本模块的命令写入。

模型：

    mode      ∈ {WINDOWED, MAXIMIZED, FULLSCREEN}   呈现模式，三者互斥
    minimized ∈ {True, False}                        叠加态：挂起 mode，而非清零
    _windowed_geometry                               回到 WINDOWED 时使用的几何
    _mode_before_fullscreen                          退出全屏时回到哪个模式

「最小化」不是一种 mode，而是让当前 mode 挂起；因为原生调用会完整保留状态，
恢复后 Qt 直接报回原来的模式，不需要任何影子变量。
"""

from __future__ import annotations

import ctypes
import logging
import sys
from ctypes import wintypes
from enum import IntEnum

from PySide6.QtCore import Property, QObject, QPointF, QRect, QRectF, Signal, Slot
from PySide6.QtGui import QColor, QCursor, QPainterPath, QRegion, QWindow

logger = logging.getLogger(__name__)

# Win32 常量
_SW_MAXIMIZE = 3
_SW_MINIMIZE = 6
_SW_RESTORE = 9
_GWL_STYLE = -16
_WS_MAXIMIZE = 0x01000000

# DWM 常量
_DWMWA_WINDOW_CORNER_PREFERENCE = 33
_DWMWA_BORDER_COLOR = 34
_DWMWCP_DONOTROUND = 1
_DWMWCP_ROUND = 2

_CORNER_RADIUS = 8  # 对齐 Theme.radiusMd


class _Mode(IntEnum):
    WINDOWED = 0
    MAXIMIZED = 1
    FULLSCREEN = 2


class WindowState(QObject):
    """窗口呈现状态的唯一拥有者。QML 只绑定只读属性、只调用意图方法。"""

    windowedChanged = Signal()
    maximizedChanged = Signal()
    fullscreenChanged = Signal()
    minimizedChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._window: QWindow | None = None
        self._hwnd = 0
        self._mode = _Mode.WINDOWED
        self._minimized_fallback = False  # 仅非 Windows 使用：没有 IsIconic 可查
        self._minimized_reported = False  # 已对外发出的 minimized 值，用于决定是否发信号
        self._windowed_geometry = QRect()
        self._mode_before_fullscreen = _Mode.WINDOWED

    # ------------------------------------------------------------------ QML 只读视图

    @Property(bool, notify=windowedChanged)
    def windowed(self) -> bool:
        return self._mode == _Mode.WINDOWED

    @Property(bool, notify=maximizedChanged)
    def maximized(self) -> bool:
        return self._mode == _Mode.MAXIMIZED

    @Property(bool, notify=fullscreenChanged)
    def fullscreen(self) -> bool:
        return self._mode == _Mode.FULLSCREEN

    @Property(bool, notify=minimizedChanged)
    def minimized(self) -> bool:
        """是否最小化 —— 始终即时向原生查询，不缓存。

        Qt 的可见性载荷会滞后、补发、乱序（实测最小化/恢复过程中会出现
        「原生仍 iconized 而载荷已报 Windowed」以及反过来的情况），把它缓存成
        一个字段就会像旧的影子变量一样长期失配。IsIconic 才是真相。
        """
        if self._hwnd:
            return self._is_iconic()
        return self._minimized_fallback

    @Slot(result="QPointF")
    def cursorPos(self) -> QPointF:
        return QCursor.pos()

    # ------------------------------------------------------------------ 接管窗口

    def attach(self, window: QWindow, border_color: QColor | None = None) -> None:
        """接管窗口的原生呈现状态。必须在窗口对象创建之后调用一次。

        要求窗口此时处于 Windowed：最大化/全屏状态下的「窗口化矩形」没有任何可靠
        来源（Qt 的 normalGeometry 会被 FullScreen 往返污染，Win32 的
        GetWindowPlacement.rcNormalPosition 对 Qt 自模拟的最大化同样会被写成工作区
        矩形，两者都实测过）。因此这里只记下可信时的几何，而不是猜一个。
        """
        self._window = window
        self._hwnd = int(window.winId()) if sys.platform == "win32" else 0
        if self._hwnd and border_color is not None:
            self._set_dwm_border_color(border_color)
        window.visibilityChanged.connect(self._sync_from_native)
        for signal in (window.xChanged, window.yChanged, window.widthChanged, window.heightChanged):
            signal.connect(self._on_geometry_changed)
        self._sync_from_native(window.visibility())
        self._capture_geometry_for_restore()
        self._refresh_native_chrome()
        logger.info("窗口状态: 已接管 hwnd=%s mode=%s", self._hwnd or "n/a", self._mode.name)

    # ------------------------------------------------------------------ 命令（唯一写入者）

    @Slot()
    def toggleMaximized(self) -> None:
        """最大化按钮 / 标题栏双击。全屏时先退出全屏，回到进全屏前的模式。"""
        if self._mode == _Mode.FULLSCREEN:
            self.exitFullscreen()
        elif self._mode == _Mode.MAXIMIZED:
            self.restore()
        else:
            self.maximize()

    @Slot()
    def maximize(self) -> None:
        if self._window is None or self._mode != _Mode.WINDOWED:
            return
        self._capture_geometry_for_restore()
        self._set_mode(_Mode.MAXIMIZED)
        self._show_maximized()

    @Slot()
    def restore(self) -> None:
        """回到 Windowed（取消最大化）。"""
        if self._window is None or self._mode == _Mode.WINDOWED:
            return
        rect = self._target_windowed_geometry()
        self._set_mode(_Mode.WINDOWED)
        self._apply_windowed(rect)

    @Slot()
    def toggleFullscreen(self) -> None:
        if self._mode == _Mode.FULLSCREEN:
            self.exitFullscreen()
        else:
            self.enterFullscreen()

    @Slot()
    def enterFullscreen(self) -> None:
        if self._window is None or self._mode == _Mode.FULLSCREEN:
            return
        self._mode_before_fullscreen = self._mode
        if self._mode == _Mode.WINDOWED:
            self._capture_geometry_for_restore()
        self._set_mode(_Mode.FULLSCREEN)
        self._window.showFullScreen()

    @Slot()
    def exitFullscreen(self) -> None:
        if self._window is None or self._mode != _Mode.FULLSCREEN:
            return
        self._leave_fullscreen(self._mode_before_fullscreen)

    @Slot()
    def minimize(self) -> None:
        """最小化。

        必须走原生调用：QWindow.showMinimized() 会先把无边框窗口从全屏降级回
        Windowed 再最小化，导致恢复后既丢失最大化也丢失全屏。原生 SW_MINIMIZE
        由操作系统完整保留状态，恢复时 Qt 直接报回原模式，mode 无需任何特殊处理。
        """
        win = self._window
        if win is None:
            return
        if self._hwnd:
            self._show_native(_SW_MINIMIZE)
        else:
            self._minimized_fallback = True
            win.showMinimized()
        self._sync_minimized()  # 原生状态已落地，立即对外同步，不等可见性事件

    @Slot()
    def beginDragMove(self) -> None:
        """标题栏拖拽起点：脱离最大化/全屏并按记忆几何恢复为 Windowed。

        位移计算留在 QML（那是指针语义，不是窗口状态）；这里只保证拖拽开始时
        窗口确实处于 Windowed 且尺寸正确。
        """
        if self._window is None or self._mode == _Mode.WINDOWED:
            return
        rect = self._target_windowed_geometry()
        self._set_mode(_Mode.WINDOWED)
        self._apply_windowed(rect)

    def _leave_fullscreen(self, target: _Mode) -> None:
        win = self._window
        if win is None:
            return
        if target == _Mode.MAXIMIZED:
            # 必须直接走原生 SW_MAXIMIZE：Qt 的 showMaximized()/setWindowState() 在全屏下
            # 会先产生一次 Windowed 再进 Maximized（屏幕上可见地闪一下）。
            self._set_mode(_Mode.MAXIMIZED)
            self._show_maximized()
            return
        rect = self._target_windowed_geometry()
        self._set_mode(_Mode.WINDOWED)
        self._apply_windowed(rect)

    def _show_maximized(self) -> None:
        if self._window is None:
            return
        if self._hwnd:
            self._show_native(_SW_MAXIMIZE)
        else:
            self._window.showMaximized()

    def _apply_windowed(self, rect: QRect) -> None:
        win = self._window
        if win is None:
            return
        # 必须先清掉 WS_MAXIMIZE：否则随后的 setGeometry 会被系统吸附回最大化。
        self._exit_native_maximize()
        win.showNormal()
        win.setGeometry(rect)

    # ------------------------------------------------------------------ 对账（只读原生，不改记忆）

    def _sync_from_native(self, visibility: QWindow.Visibility) -> None:
        """把模型对齐到窗口的原生可见性。外部变化与启动初始化共用此入口。"""
        if visibility in (QWindow.Hidden, QWindow.AutomaticVisibility):
            return
        self._sync_minimized()
        if visibility == QWindow.Minimized:
            return  # mode 挂起，不清零

        if visibility == QWindow.FullScreen:
            self._set_mode(_Mode.FULLSCREEN)
        elif visibility == QWindow.Maximized:
            self._set_mode(_Mode.MAXIMIZED)
        else:
            self._set_mode(_Mode.WINDOWED)

    def _set_mode(self, mode: _Mode) -> None:
        previous = self._mode
        if mode == previous:
            return
        self._mode = mode
        # 只发出真正发生变化的信号 —— 否则 QML 里绑定 fullscreen 的副作用会被误触发。
        if previous == _Mode.WINDOWED or mode == _Mode.WINDOWED:
            self.windowedChanged.emit()
        if previous == _Mode.MAXIMIZED or mode == _Mode.MAXIMIZED:
            self.maximizedChanged.emit()
        if previous == _Mode.FULLSCREEN or mode == _Mode.FULLSCREEN:
            self.fullscreenChanged.emit()
        self._refresh_native_chrome()

    def _sync_minimized(self) -> None:
        """值本身是即时查询的，这里只负责在它变化时发出信号。"""
        value = self.minimized
        if value != self._minimized_reported:
            self._minimized_reported = value
            self.minimizedChanged.emit()

    # ------------------------------------------------------------------ 几何记忆

    def _on_geometry_changed(self) -> None:
        if not self._hwnd:
            self._update_mask()
        self._remember_windowed_geometry()

    def _remember_windowed_geometry(self) -> None:
        """信号驱动：仅在窗口确实静止于 windowed 状态时更新恢复几何。

        几何信号会在命令调用栈内**同步**派发（实测 showNormal()/setGeometry() 都会
        当场触发），所以退出全屏的瞬间这里可能读到尚未纠正的 normalGeometry
        （Qt 在 Maximized↔FullScreen 往返后会把它弄成全屏矩形）。

        不需要额外的过渡期闸门：_apply_windowed 总是以 setGeometry(rect) 收尾，
        而它与那次「抢跑」的写入处在同一个调用栈、面对完全相同的闸门条件，
        因此紧接着必然还会发生一次把值纠正回来的写入 —— 终值不受影响
        （已用变异测试 + 800 步随机命令 + 定向构造污染路径三种方式验证：
        去掉任何过渡闸门，终值都不变）。

        真正必须核对的是**原生状态**：最大化过程中 Qt 会先报 Windowed，此时若只信
        可见性，恢复几何就会被正在最大化的矩形覆盖（这一点由变异测试证明——
        去掉 IsZoomed 闸门会产生 8 条断言失败）。
        """
        win = self._window
        if win is None or self._mode != _Mode.WINDOWED or self.minimized:
            return
        if win.visibility() != QWindow.Windowed or self._is_zoomed() or self._is_iconic():
            return
        self._store_windowed_geometry(win)

    def _capture_geometry_for_restore(self) -> None:
        """命令驱动：离开 Windowed 之前显式取一次几何。

        不依赖信号时序，因此命令的正确性不受事件排队顺序影响；但仍要核对原生
        状态 —— attach() 时窗口可能已经处于最大化/全屏，此时工作区矩形绝不是
        可用的窗口化矩形（Qt 的 normalGeometry 与 Win32 的 rcNormalPosition
        在无边框窗口上都会被污染，实测无法作为来源）。
        """
        win = self._window
        if win is None:
            return
        if win.visibility() != QWindow.Windowed or self._is_zoomed() or self._is_iconic():
            return
        self._store_windowed_geometry(win)

    def _store_windowed_geometry(self, win: QWindow) -> None:
        rect = QRect(win.x(), win.y(), win.width(), win.height())
        if rect.isValid() and rect.width() > 0 and rect.height() > 0:
            self._windowed_geometry = rect

    def _target_windowed_geometry(self) -> QRect:
        if self._windowed_geometry.isValid() and self._windowed_geometry.width() > 0:
            return QRect(self._windowed_geometry)
        # 兜底：attach() 时会捕获一次初始几何，正常情况下不会走到这里。
        return QRect(0, 0, 1280, 720)

    # ------------------------------------------------------------------ 原生集成

    def _show_native(self, command: int) -> None:
        ctypes.windll.user32.ShowWindow(wintypes.HWND(self._hwnd), command)

    def _exit_native_maximize(self) -> None:
        """清除原生 WS_MAXIMIZE 样式位。

        无边框窗口经 Maximized↔FullScreen 往返后，Qt 的 windowState 可能已回到
        WindowNoState，但 OS 样式位仍带 WS_MAXIMIZE；此时任何 setGeometry 都会被
        系统吸附回最大化。必须先让窗口退出最大化并落回样式位，几何才生效。
        """
        if not self._hwnd:
            return
        user32 = ctypes.windll.user32
        hwnd = wintypes.HWND(self._hwnd)
        if user32.IsZoomed(hwnd):
            user32.ShowWindow(hwnd, _SW_RESTORE)
        style = user32.GetWindowLongW(hwnd, _GWL_STYLE)
        if style & _WS_MAXIMIZE:
            user32.SetWindowLongW(hwnd, _GWL_STYLE, style & ~_WS_MAXIMIZE)

    def _is_zoomed(self) -> bool:
        return bool(self._hwnd) and bool(ctypes.windll.user32.IsZoomed(wintypes.HWND(self._hwnd)))

    def _is_iconic(self) -> bool:
        return bool(self._hwnd) and bool(ctypes.windll.user32.IsIconic(wintypes.HWND(self._hwnd)))

    def _refresh_native_chrome(self) -> None:
        """圆角只属于 Windowed 呈现。有窗口句柄时走 DWM 原生圆角，
        否则（非 Windows）回退 setMask。"""
        if not self._hwnd:
            self._update_mask()
            return
        preference = _DWMWCP_ROUND if self._mode == _Mode.WINDOWED else _DWMWCP_DONOTROUND
        value = ctypes.c_int(preference)
        ctypes.windll.dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(self._hwnd), _DWMWA_WINDOW_CORNER_PREFERENCE,
            ctypes.byref(value), ctypes.sizeof(value),
        )

    def _update_mask(self) -> None:
        win = self._window
        if win is None:
            return
        if self._mode != _Mode.WINDOWED:
            win.setMask(QRegion())
            return
        path = QPainterPath()
        path.addRoundedRect(
            QRectF(0, 0, win.width(), win.height()), _CORNER_RADIUS, _CORNER_RADIUS,
        )
        win.setMask(QRegion(path.toFillPolygon().toPolygon()))

    def _set_dwm_border_color(self, color: QColor) -> None:
        colorref = (color.blue() << 16) | (color.green() << 8) | color.red()
        value = ctypes.c_int(colorref)
        ctypes.windll.dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(self._hwnd), _DWMWA_BORDER_COLOR,
            ctypes.byref(value), ctypes.sizeof(value),
        )
