import json
import logging
import os
import shutil
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


def _appdata_dir() -> Path:
    base = os.environ.get("LISTREAM_DATA_DIR")
    if base:
        return Path(base)
    return Path(os.environ["APPDATA"]) / "CedarHuang" / "Listream"


def config_path() -> Path:
    return _appdata_dir() / "config.json"


def cache_dir() -> Path:
    return _appdata_dir() / "cache"


def logo_cache_dir() -> Path:
    return cache_dir() / "logos"


def ensure_dirs() -> None:
    cache_dir().mkdir(parents=True, exist_ok=True)
    logo_cache_dir().mkdir(parents=True, exist_ok=True)


def load_json(path: Path) -> dict:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}
    except json.JSONDecodeError:
        logger.warning("JSON 解析失败 path=%s", path)
        return {}


def save_json(path: Path, data: dict) -> None:
    tmp = path.with_suffix(".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(tmp, path)


def load_config() -> dict:
    return load_json(config_path())


def save_config(data: dict) -> None:
    save_json(config_path(), data)


def load_channel_cache(subscription_id: str) -> Optional[list[dict]]:
    path = cache_dir() / f"{subscription_id}.json"
    data = load_json(path)
    channels = data.get("channels")
    return channels if isinstance(channels, list) else None


def save_channel_cache(subscription_id: str, channels: list[dict]) -> None:
    path = cache_dir() / f"{subscription_id}.json"
    save_json(path, {"channels": channels})


def delete_channel_cache(subscription_id: str) -> None:
    path = cache_dir() / f"{subscription_id}.json"
    try:
        os.remove(path)
    except FileNotFoundError:
        pass


def load_volume() -> int:
    data = load_config()
    v = data.get("volume")
    return int(v) if isinstance(v, (int, float)) else 80


def save_volume(vol: int) -> None:
    data = load_config()
    data["volume"] = vol
    save_config(data)


def load_proxy_config() -> dict:
    """返回 proxy 配置字典 {enabled, type, host, port}，无配置时返回空。"""
    data = load_config()
    proxy = data.get("proxy")
    if isinstance(proxy, dict):
        return proxy
    return {}


def save_proxy_config(proxy: dict) -> None:
    data = load_config()
    data["proxy"] = proxy
    save_config(data)


def load_last_channel() -> Optional[dict]:
    data = load_config()
    return data.get("last_channel")


def save_last_channel(url: str, name: str) -> None:
    data = load_config()
    data["last_channel"] = {"url": url, "name": name}
    save_config(data)
