from dataclasses import dataclass


@dataclass
class Channel:
    name: str
    url: str
    logo: str = ""
    group: str = "未分组"
    epg_id: str = ""
    subscription_id: str = ""

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "url": self.url,
            "logo": self.logo,
            "group": self.group,
            "epg_id": self.epg_id,
            "subscription_id": self.subscription_id,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "Channel":
        return cls(
            name=d.get("name", ""),
            url=d.get("url", ""),
            logo=d.get("logo", ""),
            group=d.get("group", "未分组"),
            epg_id=d.get("epg_id", ""),
            subscription_id=d.get("subscription_id", ""),
        )
