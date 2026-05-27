"""Фактический предмет в холодильнике/морозилке/вакууме/кладовой пользователя."""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class StorageItem(Base):
    __tablename__ = "storage_items"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True, native_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True, native_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    # module_id опционален — пользователь мог добавить произвольный продукт.
    # При удалении модуля из каталога FK ставит NULL, denormalised name остаётся.
    module_id: Mapped[str | None] = mapped_column(
        String(64),
        ForeignKey("modules.id", ondelete="SET NULL"),
        nullable=True,
    )
    module_name: Mapped[str] = mapped_column(String(160), nullable=False)
    emoji: Mapped[str | None] = mapped_column(String(16), nullable=True)
    zone: Mapped[str] = mapped_column(String(16), nullable=False)
    portion_count: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    added_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    __table_args__ = (
        Index("ix_storage_items_user", "user_id"),
        Index("ix_storage_items_user_zone", "user_id", "zone"),
    )
