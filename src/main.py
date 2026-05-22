import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtCore import Qt

from .engine import create_engine


def main() -> None:
    QGuiApplication.setAttribute(Qt.ApplicationAttribute.AA_EnableHighDpiScaling, True)
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Listream")
    app.setOrganizationName("Listream")
    create_engine()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
