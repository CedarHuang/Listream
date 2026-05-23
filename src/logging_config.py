import logging
import time

_FORMAT = "%(asctime)s | %(levelname)-5s | %(module)s | %(message)s"
_DATE_FORMAT = "%H:%M:%S"


class _Formatter(logging.Formatter):
    def format(self, record):
        record.module = record.name.rsplit(".", 1)[-1]
        return super().format(record)

    def formatTime(self, record, datefmt=None):
        ct = self.converter(record.created)
        base = time.strftime(datefmt or self.default_time_format, ct)
        return f"{base}.{int(record.msecs):03d}"


def setup() -> None:
    handler = logging.StreamHandler()
    handler.setFormatter(_Formatter(_FORMAT, _DATE_FORMAT))
    logging.basicConfig(level=logging.INFO, handlers=[handler])
