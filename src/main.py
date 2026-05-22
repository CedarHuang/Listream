import os
import sys
from pathlib import Path

_SRC_DIR = str(Path(__file__).resolve().parent)
os.environ["PATH"] = _SRC_DIR + os.pathsep + os.environ["PATH"]

from PySide6.QtGui import QGuiApplication


def main() -> None:
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Listream")
    app.setOrganizationName("Listream")

    if __package__ is None:
        _root = str(Path(__file__).resolve().parent.parent)
        sys.path.insert(0, _root)
        from src.engine import create_engine
    else:
        from .engine import create_engine

    # 保持 engine 引用，防止 Python GC 销毁 QML 窗口
    engine = create_engine()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
