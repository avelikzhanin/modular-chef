"""Кулинарный модуль — каталог (seeded из JSON)."""
from sqlalchemy import JSON, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class Module(Base):
    __tablename__ = "modules"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)  # e.g. "chicken_breast"
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    emoji: Mapped[str] = mapped_column(String(16), nullable=False)
    category: Mapped[str] = mapped_column(String(32), nullable=False)
    tags: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    methods: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    storage_zone: Mapped[str] = mapped_column(String(16), nullable=False)
    storage_days: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    storage_tip: Mapped[str | None] = mapped_column(Text, nullable=True)
    calories_per_100g: Mapped[int | None] = mapped_column(Integer, nullable=True)
    prep_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)

    __table_args__ = (
        Index("ix_modules_category", "category"),
    )
