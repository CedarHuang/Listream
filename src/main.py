import os
import sys
from pathlib import Path

_SRC_DIR = str(Path(__file__).resolve().parent)
os.environ["PATH"] = _SRC_DIR + os.pathsep + os.environ["PATH"]

from PySide6.QtGui import QGuiApplication

from .engine import create_engine


def main() -> None:
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Listream")
    app.setOrganizationName("Listream")
    create_engine()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
