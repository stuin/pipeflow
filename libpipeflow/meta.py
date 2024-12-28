import typing

from dataclasses import dataclass, fields
from PySide6.QtCore import Property, Signal, QProcess, QAbstractListModel, QByteArray, Qt, QModelIndex

@dataclass
class Meta:
	default_sink: str
	default_source: str

class MetaModel(QAbstractListModel):
	def __init__(self, parent=None):
		super().__init__(parent=parent)
		self._meta_list = []

	def data(self, index: QModelIndex, role: int = Qt.DisplayRole) -> typing.Any:
		if 0 <= index.row() < self.rowCount():
			meta = self._meta_list[index.row()]
			name = self.roleNames().get(role)
			if name:
				return getattr(meta, name.decode())

	def set_data(self, row, value, role):
		node = self._meta_list[row]
		if node:
			setattr(node, role, value)
			idx = self.index(row, 0)
			self.dataChanged.emit(idx, idx, [role])
			return True
		return False

	def roleNames(self) -> dict[int, QByteArray]:
		d = {}
		for i, field in enumerate(fields(Meta)):
			d[Qt.DisplayRole + i] = field.name.encode()
		return d

	def rowCount(self, index: QModelIndex = QModelIndex()) -> int:
		return len(self._meta_list)

	def add_meta(self, meta: Meta) -> None:
		self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
		self._meta_list.append(meta)
		self.endInsertRows()
