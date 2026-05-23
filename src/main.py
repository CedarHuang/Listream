import logging
import os
import sys
from pathlib import Path

_SRC_DIR = Path(__file__).resolve().parent
os.environ["PATH"] = str(_SRC_DIR / "libs") + os.pathsep + os.environ["PATH"]

from PySide6.QtGui import QGuiApplication

if __package__ is None:
    _ROOT = str(Path(__file__).resolve().parent.parent)
    sys.path.insert(0, _ROOT)
    from src.logging_config import setup
    from src.engine import create_engine
else:
    from .logging_config import setup
    from .engine import create_engine


def main() -> None:
    setup()
    logging.getLogger("main").info("Listream 启动")

    app = QGuiApplication(sys.argv)
    app.setApplicationName("Listream")
    app.setOrganizationName("Listream")

    # 保持 engine 引用，防止 Python GC 销毁 QML 窗口
    engine = create_engine()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
