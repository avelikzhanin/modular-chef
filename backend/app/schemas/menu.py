"""Pydantic-зеркало Dart-моделей из `lib/models/weekly_menu.dart`.

Поля и имена должны совпадать байт-в-байт — клиент десериализует ответ
этого API через `WeeklyMenu.fromJson(...)`.
"""
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class _ApiModel(BaseModel):
    """Строгая база для ОТВЕТА: запрещаем extra-поля чтобы рано ловить дрейф LLM."""

    model_config = ConfigDict(extra="forbid", populate_by_name=True)


class _ReqModel(BaseModel):
    """Терпимая база для ЗАПРОСА: игнорируем незнакомые поля, чтобы более
    новый клиент (с доп. полями) не получал 422 от старого/строгого бэка."""

    model_config = ConfigDict(extra="ignore", populate_by_name=True)


# ---------- Request ----------


class _Picks(_ReqModel):
    proteins: list[str] = Field(default_factory=list)
    sides: list[str] = Field(default_factory=list)
    soups: list[str] = Field(default_factory=list)
    breakfasts: list[str] = Field(default_factory=list)
    custom: list[str] = Field(default_factory=list)
    # Уточнения внутри типов завтрака. Пустой список значит «Шеф не уточнял» —
    # тогда выбор за моделью; непустой обязателен к исполнению, иначе в покупки
    # едут добавки, которых Шеф не выбирал.
    eggStyles: list[str] = Field(default_factory=list)
    eggAddins: list[str] = Field(default_factory=list)
    porridgeKinds: list[str] = Field(default_factory=list)
    sandwichFillings: list[str] = Field(default_factory=list)


class PreferencesSchema(_ReqModel):
    allergies: list[str] = Field(default_factory=list)
    prepTimeLimitMinutes: int = 120
    weekStyle: str | None = None


class FavouriteComboSchema(_ReqModel):
    protein: str
    side: str
    sauce: str | None = None


class GenerationRequestSchema(_ReqModel):
    picks: _Picks
    preferences: PreferencesSchema = Field(default_factory=PreferencesSchema)
    favourites: list[FavouriteComboSchema] = Field(default_factory=list)
    # Горизонт меню. Старый клиент поле не шлёт — для него остаются две недели.
    weeks: int = Field(default=2, ge=1, le=3)


# ---------- Response ----------


class MealComponentSchema(_ApiModel):
    moduleId: str
    role: Literal[
        "protein",
        "side",
        "vegetable",
        "sauce",
        "base",
        "standalone",
        # завтрак-конструктор
        "egg_style",
        "addition",
        "jar_base",
        "jar_barrier",
        "jar_middle",
        "jar_top",
    ]
    name: str
    emoji: str = ""


class PlannedMealSchema(_ApiModel):
    title: str
    kind: Literal["main", "breakfast", "soup", "snack"] = "main"
    components: list[MealComponentSchema] = Field(default_factory=list)
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
    snack: PlannedMealSchema | None = None


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
