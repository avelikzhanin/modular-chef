"""Тесты парсинга ответа Claude. Реальных HTTP-вызовов нет — фикстура JSON
эмулирует то, что мог бы вернуть API.
"""
import pytest

from app.claude_client import parse_claude_response


_VALID_RESPONSE = """{
  "weeks": [
    {
      "index": 0,
      "name": "Неделя 1",
      "days": [
        {
          "weekday": "monday",
          "shortName": "Пн",
          "breakfast": {"title": "Овсянка", "moduleIds": ["oatmeal_jar"], "reheatMinutes": 0, "fromContainer": "холодильник"},
          "lunch": {"title": "Курица + рис", "moduleIds": ["chicken_breast", "rice"], "reheatMinutes": 2, "fromContainer": "холодильник, №2"},
          "dinner": {"title": "Лосось + булгур", "moduleIds": ["salmon", "bulgur"], "reheatMinutes": 3, "fromContainer": "вакуум"}
        }
      ]
    }
  ],
  "summary": {"uniqueDishes": 3, "totalMeals": 3, "modulesUsed": 5, "flavourProfiles": ["mediterranean"]}
}"""


def test_parses_clean_json() -> None:
    menu = parse_claude_response(_VALID_RESPONSE)
    assert len(menu.weeks) == 1
    assert menu.weeks[0].days[0].lunch.title == "Курица + рис"
    assert menu.summary.uniqueDishes == 3


def test_parses_json_with_markdown_fence() -> None:
    """Claude иногда оборачивает ответ в ```json … ```."""
    wrapped = f"```json\n{_VALID_RESPONSE}\n```"
    menu = parse_claude_response(wrapped)
    assert menu.summary.totalMeals == 3


def test_parses_json_with_leading_prose() -> None:
    """Иногда модель добавляет «Вот меню:» перед JSON."""
    prefixed = f"Вот ваше меню на 14 дней:\n\n{_VALID_RESPONSE}"
    menu = parse_claude_response(prefixed)
    assert menu.weeks[0].days[0].breakfast.moduleIds == ["oatmeal_jar"]


def test_rejects_invalid_json() -> None:
    with pytest.raises((ValueError, Exception)):
        parse_claude_response("это не JSON")


def test_rejects_schema_violation() -> None:
    """Если weekday не из набора, валидация падает."""
    bad = _VALID_RESPONSE.replace('"monday"', '"someday"')
    with pytest.raises(Exception):
        parse_claude_response(bad)
