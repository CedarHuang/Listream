from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt

from ..models.subscription import Subscription


class SubscriptionListModel(QAbstractListModel):
    IdRole = Qt.UserRole + 1
    NameRole = Qt.UserRole + 2
    UrlRole = Qt.UserRole + 3
    ChannelCountRole = Qt.UserRole + 4
    LastUpdatedRole = Qt.UserRole + 5

    _ROLE_MAP = {
        IdRole: b"subId",
        NameRole: b"subName",
        UrlRole: b"subUrl",
        ChannelCountRole: b"channelCount",
        LastUpdatedRole: b"lastUpdated",
    }

    def __init__(self, parent=None):
        super().__init__(parent)
        self._subscriptions: list[Subscription] = []

    def roleNames(self):
        return self._ROLE_MAP

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._subscriptions)

    def data(self, index, role):
        if not index.isValid() or index.row() >= len(self._subscriptions):
            return None
        s = self._subscriptions[index.row()]
        return {
            self.IdRole: s.id,
            self.NameRole: s.name,
            self.UrlRole: s.url,
            self.ChannelCountRole: s.channel_count,
            self.LastUpdatedRole: s.last_updated,
        }.get(role)

    def replace_all(self, subscriptions: list[Subscription]) -> None:
        self.beginResetModel()
        self._subscriptions = list(subscriptions)
        self.endResetModel()
