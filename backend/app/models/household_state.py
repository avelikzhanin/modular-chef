"""Ключ-значение состояние домохозяйства — синк между телефонами Шефа и Гостя."""
import uuid
from datetime import datetime

from sqlalchemy import JSON, DateTime, ForeignKey, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class HouseholdState(Base):
    """Одна запись = один ключ клиента (pantry_stock, today_plan, ...).

    Last-write-wins: клиент пишет целиком значение ключа, updated_at
    обновляется автоматически.
    """

    __tablename__ = "household_state"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True, native_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    key: Mapped[str] = mapped_column(String(64), primary_key=True)
    value: Mapped[dict] = mapped_column(JSON, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )
