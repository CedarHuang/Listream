from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, QSortFilterProxyModel, Slot

from ..models.channel import Channel


class ChannelListModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    LogoRole = Qt.UserRole + 2
    UrlRole = Qt.UserRole + 3
    GroupRole = Qt.UserRole + 4
    EpgIdRole = Qt.UserRole + 5
    SubIdRole = Qt.UserRole + 6

    _ROLE_MAP = {
        NameRole: b"name",
        LogoRole: b"logo",
        UrlRole: b"url",
        GroupRole: b"group",
        EpgIdRole: b"epgId",
        SubIdRole: b"subscriptionId",
    }

    def __init__(self, parent=None):
        super().__init__(parent)
        self._channels: list[Channel] = []

    def roleNames(self):
        return self._ROLE_MAP

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._channels)

    def data(self, index, role):
        if not index.isValid() or index.row() >= len(self._channels):
            return None
        ch = self._channels[index.row()]
        return {
            self.NameRole: ch.name,
            self.LogoRole: ch.logo,
            self.UrlRole: ch.url,
            self.GroupRole: ch.group,
            self.EpgIdRole: ch.epg_id,
            self.SubIdRole: ch.subscription_id,
        }.get(role)

    def replace_all(self, channels: list[Channel]) -> None:
        self.beginResetModel()
        self._channels = list(channels)
        self.endResetModel()

    def get_at(self, row: int) -> Channel | None:
        if 0 <= row < len(self._channels):
            return self._channels[row]
        return None

    @property
    def count(self) -> int:
        return len(self._channels)


class ChannelFilterModel(QSortFilterProxyModel):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._filter_text = ""
        self.setDynamicSortFilter(True)

    def filterAcceptsRow(self, source_row, source_parent):
        if not self._filter_text:
            return True
        model = self.sourceModel()
        idx = model.index(source_row, 0, source_parent)
        name = (model.data(idx, ChannelListModel.NameRole) or "").lower()
        group = (model.data(idx, ChannelListModel.GroupRole) or "").lower()
        needle = self._filter_text.lower()
        return needle in name or needle in group

    def setFilterText(self, text: str) -> None:
        self._filter_text = text
        self.invalidateFilter()

    @Slot(int, result=str)
    def getUrl(self, row: int) -> str:
        src_idx = self.mapToSource(self.index(row, 0))
        model = self.sourceModel()
        return model.data(src_idx, ChannelListModel.UrlRole) or ""

    @Slot(int, result=str)
    def getName(self, row: int) -> str:
        src_idx = self.mapToSource(self.index(row, 0))
        model = self.sourceModel()
        return model.data(src_idx, ChannelListModel.NameRole) or ""
