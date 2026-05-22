import re
from urllib.parse import unquote

from ..models.channel import Channel

_LINE_RE = re.compile(r"^#EXTINF:\s*(-?\d+)\s*(.*?)\s*,\s*(.+)$")
_ATTR_RE = re.compile(r'(\w[\w-]*)="([^"]*)"')


def parse_m3u(content: str, subscription_id: str) -> list[Channel]:
    channels: list[Channel] = []
    if content.startswith("﻿"):
        content = content[1:]
    lines = content.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        m = _LINE_RE.match(line)
        if m:
            params_str = m.group(2)
            display_name = m.group(3).strip()
            attrs = _parse_attrs(params_str)
            url_line = ""
            if i + 1 < len(lines):
                url_line = lines[i + 1].strip()
            if url_line and not url_line.startswith("#"):
                channels.append(
                    Channel(
                        name=attrs.get("tvg-name", display_name),
                        url=url_line,
                        logo=unquote(attrs.get("tvg-logo", "")),
                        group=unquote(attrs.get("group-title", "未分组")),
                        epg_id=attrs.get("tvg-id", ""),
                        subscription_id=subscription_id,
                    )
                )
            i += 2
            continue
        i += 1
    return channels


def _parse_attrs(params: str) -> dict[str, str]:
    return {k: v for k, v in _ATTR_RE.findall(params)}
