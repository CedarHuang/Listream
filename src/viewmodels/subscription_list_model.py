from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt

from ..models.subscription import Subscription


class SubscriptionListModel(QAbstractListModel):
    IdRole = Qt.UserRole + 1
    NameRole = Qt.UserRole + 2
    UrlRole = Qt.UserRole + 3
    ChannelCountRole = Qt.UserRole + 4
    LastUpdatedRole = Qt.UserRole + 5
    EnabledRole = Qt.UserRole + 6
    RefreshingRole = Qt.UserRole + 7

    _ROLE_MAP = {
        IdRole: b"subId",
        NameRole: b"subName",
        UrlRole: b"subUrl",
        ChannelCountRole: b"channelCount",
        LastUpdatedRole: b"lastUpdated",
        EnabledRole: b"enabled",
        RefreshingRole: b"refreshing",
    }

    def __init__(self, parent=None):
        super().__init__(parent)
        self._subscriptions: list[Subscription] = []
        self._refreshing_ids: set[str] = set()

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
            self.EnabledRole: s.enabled,
            self.RefreshingRole: s.id in self._refreshing_ids,
        }.get(role)

    def set_refreshing(self, sub_id: str, refreshing: bool) -> None:
        if refreshing:
            self._refreshing_ids.add(sub_id)
        else:
            self._refreshing_ids.discard(sub_id)
        self.notify_item(sub_id)

    def replace_all(self, subscriptions: list[Subscription]) -> None:
        self.beginResetModel()
        self._subscriptions = list(subscriptions)
        self.endResetModel()

    def moveRows(self, sourceParent, sourceRow, count, destParent, destChild):
        return True

    def move_item(self, from_index: int, to_index: int) -> bool:
        n = len(self._subscriptions)
        if from_index < 0 or from_index >= n or to_index < 0 or to_index >= n:
            return False
        if from_index == to_index:
            return False
        # beginMoveRows 的 destinationChild 是「移除源行后」的插入索引。
        # 下移时最终位置 to_index 在缩表中等价于 to_index （pop 后原
        # to_index 处的元素已左移），而 beginMoveRows 的语义是将行插入
        # 到 destinationChild 之前，因此下移需 +1。
        dest = to_index + 1 if to_index > from_index else to_index
        super().beginMoveRows(QModelIndex(), from_index, from_index,
                                QModelIndex(), dest)
        sub = self._subscriptions.pop(from_index)
        self._subscriptions.insert(to_index, sub)
        super().endMoveRows()
        return True

    def _find_row(self, sub_id: str) -> int:
        for i, s in enumerate(self._subscriptions):
            if s.id == sub_id:
                return i
        return -1

    def notify_item(self, sub_id: str) -> None:
        row = self._find_row(sub_id)
        if row < 0:
            return
        idx = self.index(row)
        self.dataChanged.emit(idx, idx, [])
