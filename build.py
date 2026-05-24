"""Listream 构建脚本

用法:
    python build.py              # 编译 qrc，下载 mpv DLL（如缺失）
    python build.py --package    # 编译 + PyInstaller 打包为 .exe
    python build.py --clean      # 打包前清理 PyInstaller 缓存
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path
from tempfile import TemporaryDirectory

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "src"
QRC = SRC / "resources.qrc"
QRC_OUT = SRC / "resources_rc.py"
DLL_DIR = SRC / "libs"
DLL = DLL_DIR / "libmpv-2.dll"
ICON_SVG = SRC / "assets" / "icon.svg"
ICON_ICO = SRC / "assets" / "icon.ico"

MPV_REPO = "shinchiro/mpv-winbuild-cmake"
MPV_API = f"https://api.github.com/repos/{MPV_REPO}/releases/latest"

# ---------------------------------------------------------------------------
# 排除模块定义 — 单一数据源，自动派生三类排除项
# ---------------------------------------------------------------------------
# 每条: (PySide6 模块短名, QML 目录名或 None)
#   - --exclude-module PySide6.{short}
#   - DLL glob: Qt6{short去掉Qt前缀}*
#   - QML dir: 如果非 None，从 pyside6_dir/qml/{dir} 删除
_EXCLUDED_MODULES: list[tuple[str, str | None]] = [
    # Qt3D 族 — 多模块共享 Qt3D QML 目录
    ("Qt3DAnimation",       "Qt3D"),
    ("Qt3DCore",            "Qt3D"),
    ("Qt3DExtras",          "Qt3D"),
    ("Qt3DInput",           "Qt3D"),
    ("Qt3DLogic",           "Qt3D"),
    ("Qt3DQuick",           "Qt3D"),
    ("Qt3DQuickAnimation",  "Qt3D"),
    ("Qt3DQuickExtras",     "Qt3D"),
    ("Qt3DQuickInput",      "Qt3D"),
    ("Qt3DQuickLogic",      "Qt3D"),
    ("Qt3DQuickRender",     "Qt3D"),
    ("Qt3DQuickScene2D",    "Qt3D"),
    ("Qt3DQuickScene3D",    "Qt3D"),
    ("Qt3DRender",          "Qt3D"),
    # 其他有 Python 绑定的模块
    ("QtCharts",            "QtCharts"),
    ("QtConcurrent",        None),
    ("QtDataVisualization", "QtDataVisualization"),
    ("QtGraphs",            "QtGraphs"),
    ("QtLocation",          "QtLocation"),
    ("QtMultimedia",        "QtMultimedia"),
    ("QtPdf",               None),
    ("QtPositioning",       "QtPositioning"),
    ("QtRemoteObjects",     "QtRemoteObjects"),
    ("QtScxml",             "QtScxml"),
    ("QtSensors",           "QtSensors"),
    ("QtShaderTools",       None),
    ("QtSpatialAudio",      None),
    ("QtSql",               None),
    ("QtStateMachine",      None),
    ("QtTest",              "QtTest"),
    ("QtTextToSpeech",      "QtTextToSpeech"),
    ("QtVirtualKeyboard",   None),
    ("QtWebChannel",        "QtWebChannel"),
    ("QtWebEngineCore",     "QtWebEngine"),
    ("QtWebEngineQuick",    "QtWebEngine"),
    ("QtWebSockets",        "QtWebSockets"),
    ("QtWebView",           "QtWebView"),
]

# 仅二进制层面需要清理的（无对应 Python 绑定，但 hook 会收集）
_EXCLUDED_DLL_GLOBS_EXTRA = [
    "Qt6Labs*",
    "Qt6Quick3D*",
    "Qt6QuickTimeline*",
    "Qt6QuickVectorImage*",
    "Qt6QuickTest*",
    "Qt6QuickControls2FluentWinUI3*",
    "Qt6QuickControls2Imagine*",
    "Qt6QuickControls2Material*",
    "Qt6QuickControls2Universal*",
    "Qt6QuickControls2WindowsStyleImpl*",
    "opengl32sw*",
]

_EXCLUDED_QML_DIRS_EXTRA = [
    "Qt5Compat",
    "QtQuick3D",
]


def _excluded_pyside6_modules() -> list[str]:
    """从主数据源派生 --exclude-module 列表。"""
    return [f"PySide6.{short}" for short, _ in _EXCLUDED_MODULES]


def _excluded_dll_globs() -> list[str]:
    """从主数据源派生 DLL glob 列表并合并额外项。"""
    # PySide6 模块名如 Qt3DAnimation → Qt DLL 名 Qt63DAnimation.dll
    derived = {f"Qt6{short.removeprefix('Qt')}*" for short, _ in _EXCLUDED_MODULES}
    derived.update(_EXCLUDED_DLL_GLOBS_EXTRA)
    return sorted(derived)


def _excluded_qml_dirs() -> list[str]:
    """从主数据源派生 QML 目录列表并合并额外项。"""
    derived = {qml_dir for _, qml_dir in _EXCLUDED_MODULES if qml_dir is not None}
    derived.update(_EXCLUDED_QML_DIRS_EXTRA)
    return sorted(derived)


# ---------------------------------------------------------------------------
# 图标生成
# ---------------------------------------------------------------------------

def compile_icon() -> None:
    """将 icon.svg 转换为 icon.ico（多尺寸）。"""
    if ICON_ICO.is_file() and ICON_ICO.stat().st_mtime >= ICON_SVG.stat().st_mtime:
        print(f"[icon] 已存在: {ICON_ICO.relative_to(ROOT)}")
        return

    print(f"[icon] 生成 {ICON_ICO.name} ...")
    from tempfile import TemporaryDirectory

    from PySide6.QtCore import QSize, Qt
    from PySide6.QtGui import QGuiApplication, QImage, QPainter
    from PySide6.QtSvg import QSvgRenderer

    from PIL import Image as PILImage

    app = QGuiApplication.instance()
    if app is None:
        app = QGuiApplication(["--platform", "offscreen"])

    renderer = QSvgRenderer(str(ICON_SVG))
    sizes = [256, 128, 64, 48, 32, 24, 16]
    pil_images = []

    with TemporaryDirectory() as tmp:
        for s in sizes:
            img = QImage(QSize(s, s), QImage.Format_ARGB32)
            img.fill(Qt.GlobalColor.transparent)
            painter = QPainter(img)
            painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform)
            renderer.render(painter)
            painter.end()
            png = Path(tmp) / f"icon_{s}.png"
            img.save(str(png), "PNG")
            with PILImage.open(png) as f:
                pil_images.append(f.copy())

    pil_images[0].save(
        str(ICON_ICO), format="ICO",
        sizes=[(p.width, p.height) for p in pil_images],
        append_images=pil_images[1:],
    )
    print(f"  -> {ICON_ICO.relative_to(ROOT)}")


# ---------------------------------------------------------------------------
# QRC 编译
# ---------------------------------------------------------------------------

def compile_qrc() -> None:
    """编译 .qrc → Python 资源模块。"""
    print(f"[qrc] 编译 {QRC.name} ...")
    result = subprocess.run(
        ["pyside6-rcc", str(QRC), "-o", str(QRC_OUT)],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        sys.exit(f"  失败: {result.stderr.strip()}")
    print(f"  -> {QRC_OUT.relative_to(ROOT)}")


# ---------------------------------------------------------------------------
# mpv DLL 下载
# ---------------------------------------------------------------------------

SEVENZR_URL = "https://www.7-zip.org/a/7zr.exe"


def _find_7z() -> str | None:
    """查找系统可用的 7-Zip 可执行文件路径。"""
    path = shutil.which("7z") or shutil.which("7za") or shutil.which("7zr")
    if path:
        return path
    for p in [
        os.environ.get("ProgramFiles", "") + r"\7-Zip\7z.exe",
        os.environ.get("ProgramFiles(x86)", "") + r"\7-Zip\7z.exe",
    ]:
        if Path(p).is_file():
            return p
    return None


def _ensure_7z(dl_dir: str) -> str | None:
    """确保 7z 可用，必要时下载 7zr.exe。"""
    existing = _find_7z()
    if existing:
        return existing

    print("  下载 7-Zip 便携版 ...")
    exe = Path(dl_dir) / "7zr.exe"
    try:
        urllib.request.urlretrieve(SEVENZR_URL, exe)
    except Exception as e:
        print(f"  下载 7zr.exe 失败: {e}")
        return None
    if exe.is_file():
        return str(exe)
    return None


def ensure_dll() -> None:
    """确保 libmpv-2.dll 存在，缺失时从 GitHub Releases 下载。"""
    if DLL.is_file():
        print(f"[dll] 已存在: {DLL.relative_to(ROOT)}")
        return

    print(f"[dll] 缺失，从 {MPV_REPO} 下载 ...")

    req = urllib.request.Request(MPV_API)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")

    try:
        with urllib.request.urlopen(req) as resp:
            release = json.loads(resp.read())
    except Exception as e:
        sys.exit(f"  GitHub API 请求失败: {e}")

    asset_url = None
    asset_name = None
    for asset in release.get("assets", []):
        name = asset["name"]
        if "mpv-dev-x86_64" in name and name.endswith(".7z"):
            asset_url = asset["browser_download_url"]
            asset_name = name
            break

    if not asset_url:
        sys.exit("  未找到 mpv-dev-x86_64.7z 资源，请手动下载 DLL")

    print(f"  下载: {asset_name}")
    with TemporaryDirectory() as tmp:
        archive = Path(tmp) / asset_name
        urllib.request.urlretrieve(asset_url, archive)

        seven_zip = _ensure_7z(tmp)
        if not seven_zip:
            sys.exit("  未找到 7-Zip，请手动解压后放入 src/libs/libmpv-2.dll")

        print("  解压 ...")
        subprocess.run(
            [seven_zip, "x", str(archive), f"-o{tmp}", "-y"],
            capture_output=True, check=True,
        )

        for root, _dirs, files in os.walk(tmp):
            for f in files:
                if f == "libmpv-2.dll":
                    DLL_DIR.mkdir(parents=True, exist_ok=True)
                    shutil.move(os.path.join(root, f), DLL)
                    print(f"  -> {DLL.relative_to(ROOT)}")
                    return

        sys.exit("  解压后未找到 libmpv-2.dll")


# ---------------------------------------------------------------------------
# PyInstaller 打包
# ---------------------------------------------------------------------------

def package(*, clean: bool = False) -> None:
    """PyInstaller 打包为独立 .exe。"""
    if not DLL.is_file():
        sys.exit("缺少 libmpv-2.dll，请先执行 python build.py")

    if not shutil.which("pyinstaller"):
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pyinstaller", "-q"])

    name = "Listream"

    print("[package] PyInstaller 打包 ...")
    cmd = [
        "pyinstaller", "--windowed", "--noconfirm",
        "--name", name,
        "--add-data", f"{DLL};.",
        "--icon", str(ICON_ICO),
    ]
    if clean:
        cmd.append("--clean")
    for mod in _excluded_pyside6_modules():
        cmd.extend(["--exclude-module", mod])
    cmd.append(str(SRC / "main.py"))

    result = subprocess.run(cmd, capture_output=False)
    if result.returncode != 0:
        sys.exit("打包失败")

    # ---- 以下为 PySide6 hook 无条件收集的文件的兜底清理 ----
    internal = ROOT / "dist" / name / "_internal"
    pyside6_dir = internal / "PySide6"

    print("[package] 清理冗余文件 ...")
    removed = 0

    for pattern in _excluded_dll_globs():
        for f in pyside6_dir.glob(pattern):
            f.unlink()
            removed += 1

    for d in _excluded_qml_dirs():
        path = pyside6_dir / "qml" / d
        if path.is_dir():
            shutil.rmtree(path)
            removed += 1

    # 移除 Qt 翻译文件
    translations = pyside6_dir / "translations"
    if translations.is_dir():
        shutil.rmtree(translations)
        removed += 1

    # 移除 QML 调试插件
    qmltooling = pyside6_dir / "plugins" / "qmltooling"
    if qmltooling.is_dir():
        shutil.rmtree(qmltooling)
        removed += 1

    # 精简 imageformats（仅保留 jpeg/svg/ico）
    for f in list((pyside6_dir / "plugins" / "imageformats").glob("*")):
        if f.stem not in ("qjpeg", "qsvg", "qico"):
            f.unlink()
            removed += 1

    # 精简 platforms（仅保留 qwindows）
    for f in list((pyside6_dir / "plugins" / "platforms").glob("*")):
        if f.stem != "qwindows":
            f.unlink()
            removed += 1

    # 移除不需要的插件
    for junk in [
        pyside6_dir / "plugins" / "tls" / "qcertonlybackend.dll",
        pyside6_dir / "plugins" / "generic" / "qtuiotouchplugin.dll",
        pyside6_dir / "plugins" / "platforminputcontexts",
    ]:
        if junk.is_file():
            junk.unlink()
            removed += 1
        elif junk.is_dir():
            shutil.rmtree(junk)
            removed += 1

    print(f"  已移除 {removed} 项冗余")
    print(f"  -> {ROOT / 'dist' / name / f'{name}.exe'}")


# ---------------------------------------------------------------------------
# 入口
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Listream 构建工具")
    parser.add_argument("--package", action="store_true", help="PyInstaller 打包")
    parser.add_argument("--clean", action="store_true", help="打包前清理 PyInstaller 缓存")
    args = parser.parse_args()

    compile_icon()
    compile_qrc()
    ensure_dll()

    if args.package:
        package(clean=args.clean)


if __name__ == "__main__":
    main()
