import uuid
from dataclasses import dataclass, field


@dataclass
class Subscription:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    name: str = ""
    url: str = ""
    last_updated: str = ""
    channel_count: int = 0
    enabled: bool = True

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "url": self.url,
            "last_updated": self.last_updated,
            "channel_count": self.channel_count,
            "enabled": self.enabled,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "Subscription":
        return cls(
            id=d.get("id", str(uuid.uuid4())),
            name=d.get("name", ""),
            url=d.get("url", ""),
            last_updated=d.get("last_updated", ""),
            channel_count=d.get("channel_count", 0),
            enabled=d.get("enabled", True),
        )
