"""Базовый declarative class для всех ORM-моделей."""
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Все модели наследуются от этого класса — общая metadata для Alembic."""
