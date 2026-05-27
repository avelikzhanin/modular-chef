"""Pydantic-зеркало Dart-моделей из `lib/models/weekly_menu.dart`.

Поля и имена должны совпадать байт-в-байт — клиент десериализует ответ
этого API через `WeeklyMenu.fromJson(...)`.
"""
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class _ApiModel(BaseModel):
    """База: запрещаем extra-поля чтобы рано ловить дрейф контракта."""

    model_config = ConfigDict(extra="forbid", populate_by_name=True)


# ---------- Request ----------


class _Picks(_ApiModel):
    proteins: list[str] = Field(default_factory=list)
    sides: list[str] = Field(default_factory=list)
    soups: list[str] = Field(default_factory=list)
    breakfasts: list[str] = Field(default_factory=list)
    custom: list[str] = Field(default_factory=list)


class PreferencesSchema(_ApiModel):
    allergies: list[str] = Field(default_factory=list)
    prepTimeLimitMinutes: int = 120
    weekStyle: str | None = None


class GenerationRequestSchema(_ApiModel):
    picks: _Picks
    preferences: PreferencesSchema = Field(default_factory=PreferencesSchema)


# ---------- Response ----------


class PlannedMealSchema(_ApiModel):
    title: str
    moduleIds: list[str] = Field(default_factory=list)
    reheatMinutes: int = 0
    fromContainer: str = ""


class DayPlanSchema(_ApiModel):
    weekday: Literal[
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
    ]
    shortName: str
    breakfast: PlannedMealSchema
    lunch: PlannedMealSchema
    dinner: PlannedMealSchema


class MenuWeekSchema(_ApiModel):
    index: int
    name: str
    days: list[DayPlanSchema]


class MenuSummarySchema(_ApiModel):
    uniqueDishes: int = 0
    totalMeals: int = 0
    modulesUsed: int = 0
    flavourProfiles: list[str] = Field(default_factory=list)


class WeeklyMenuSchema(_ApiModel):
    weeks: list[MenuWeekSchema]
    summary: MenuSummarySchema = Field(default_factory=MenuSummarySchema)
