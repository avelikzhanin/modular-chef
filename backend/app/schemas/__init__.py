"""Pydantic-схемы для API. Используются FastAPI для request/response validation."""
from app.schemas.menu import (
    DayPlanSchema,
    GenerationRequestSchema,
    MenuSummarySchema,
    MenuWeekSchema,
    PlannedMealSchema,
    PreferencesSchema,
    WeeklyMenuSchema,
)

__all__ = [
    "DayPlanSchema",
    "GenerationRequestSchema",
    "MenuSummarySchema",
    "MenuWeekSchema",
    "PlannedMealSchema",
    "PreferencesSchema",
    "WeeklyMenuSchema",
]
