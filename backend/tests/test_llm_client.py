"""Тесты парсинга ответа LLM. Реальных HTTP-вызовов нет — фикстура JSON
эмулирует то, что мог бы вернуть OpenAI (в JSON-mode).
"""
import pytest

from app.llm_client import enforce_palette, narrow_catalog, parse_llm_response
from app.schemas import GenerationRequestSchema

_LUNCH = (
    '{"title": "Курица + рис + брокколи + йогурт", "kind": "main", '
    '"components": ['
    '{"moduleId": "chicken_breast", "role": "protein", "name": "Курица", "emoji": "🍗"}, '
    '{"moduleId": "rice", "role": "side", "name": "Рис", "emoji": "🍚"}, '
    '{"moduleId": "broccoli", "role": "vegetable", "name": "Брокколи", "emoji": "🥦"}, '
    '{"moduleId": "yogurt_sauce", "role": "sauce", "name": "Йогуртовый соус", "emoji": "🥛"}'
    '], "reheatMinutes": 2, "fromContainer": "холодильник, №2"}'
)
_BREAKFAST = (
    '{"title": "Овсянка", "kind": "breakfast", '
    '"components": [{"moduleId": "oatmeal_jar", "role": "standalone", "name": "Овсянка", "emoji": "🥣"}], '
    '"reheatMinutes": 0, "fromContainer": "холодильник"}'
)
_DINNER = (
    '{"title": "Лосось + булгур", "kind": "main", '
    '"components": ['
    '{"moduleId": "salmon", "role": "protein", "name": "Лосось"}, '
    '{"moduleId": "bulgur", "role": "side", "name": "Булгур"}'
    '], "reheatMinutes": 3, "fromContainer": "вакуум"}'
)

_VALID_RESPONSE = (
    '{"weeks": [{"index": 0, "name": "Неделя 1", "days": ['
    f'{{"weekday": "monday", "shortName": "Пн", '
    f'"breakfast": {_BREAKFAST}, "lunch": {_LUNCH}, "dinner": {_DINNER}}}'
    ']}], '
    '"summary": {"uniqueDishes": 3, "totalMeals": 3, "modulesUsed": 6, "flavourProfiles": ["mediterranean"]}}'
)


def test_parses_clean_json() -> None:
    menu = parse_llm_response(_VALID_RESPONSE)
    assert len(menu.weeks) == 1
    lunch = menu.weeks[0].days[0].lunch
    assert lunch.title == "Курица + рис + брокколи + йогурт"
    assert lunch.kind == "main"
    assert len(lunch.components) == 4
    assert lunch.components[0].role == "protein"
    assert menu.summary.uniqueDishes == 3


def test_parses_json_with_markdown_fence() -> None:
    """Если модель внезапно обернёт ответ в ```json … ``` — снимаем."""
    wrapped = f"```json\n{_VALID_RESPONSE}\n```"
    menu = parse_llm_response(wrapped)
    assert menu.summary.totalMeals == 3


def test_parses_json_with_leading_prose() -> None:
    """Если перед JSON есть «Вот меню:» — игнорируем."""
    prefixed = f"Вот ваше меню на 14 дней:\n\n{_VALID_RESPONSE}"
    menu = parse_llm_response(prefixed)
    assert menu.weeks[0].days[0].breakfast.components[0].moduleId == "oatmeal_jar"


def test_rejects_invalid_json() -> None:
    with pytest.raises((ValueError, Exception)):
        parse_llm_response("это не JSON")


def test_rejects_schema_violation() -> None:
    """Если weekday не из набора, валидация падает."""
    bad = _VALID_RESPONSE.replace('"monday"', '"someday"')
    with pytest.raises(Exception):
        parse_llm_response(bad)


def test_rejects_unknown_role() -> None:
    """Роль вне набора — extra/Literal валидация падает."""
    bad = _VALID_RESPONSE.replace('"role": "protein"', '"role": "dessert"')
    with pytest.raises(Exception):
        parse_llm_response(bad)


# --- Сужение каталога ------------------------------------------------------


class _FakeModule:
    """Утиная замена ORM-модели: narrow_catalog читает только id/category/tags."""

    def __init__(self, mid: str, category: str, tags: list[str] | None = None):
        self.id = mid
        self.category = category
        self.tags = tags or []


def _catalog() -> list[_FakeModule]:
    mods = [_FakeModule(f"protein_{i}", "protein") for i in range(6)]
    mods += [_FakeModule(f"side_{i}", "side") for i in range(20)]
    mods += [_FakeModule(f"sauce_{i}", "sauce") for i in range(23)]
    mods += [_FakeModule(f"veg_{i}", "vegetable") for i in range(6)]
    mods += [_FakeModule(f"soup_{i}", "soup") for i in range(22)]
    mods += [_FakeModule(b, "breakfast") for b in ("eggs", "jar", "syrniki")]
    mods += [_FakeModule(f"egg_style_{i}", "egg_style") for i in range(6)]
    mods += [_FakeModule(f"addin_{i}", "egg_addin") for i in range(15)]
    mods += [_FakeModule(f"jar_base_{i}", "jar_base") for i in range(15)]
    mods.append(_FakeModule("soy_sesame", "sauce", ["asian", "long_keep"]))
    return mods


def _request(**picks) -> GenerationRequestSchema:
    base = {"proteins": [], "sides": [], "soups": [], "breakfasts": [], "custom": []}
    base.update(picks)
    return GenerationRequestSchema.model_validate({"picks": base})


def _ids(mods: list, category: str) -> list[str]:
    return [m.id for m in mods if m.category == category]


def test_narrow_catalog_caps_auto_categories():
    out = narrow_catalog(_request(proteins=["protein_1"], sides=["side_2"]), _catalog())

    # то, что модель добирает сама, — с потолком: иначе раздувается список покупок
    assert len(_ids(out, "sauce")) == 3
    assert len(_ids(out, "vegetable")) == 3
    # выбор Шефа проходит целиком и без чужих добавок
    assert _ids(out, "protein") == ["protein_1"]
    assert _ids(out, "side") == ["side_2"]


def test_narrow_catalog_drops_unpicked_kinds():
    out = narrow_catalog(_request(proteins=["protein_1"], breakfasts=["syrniki"]), _catalog())

    assert _ids(out, "breakfast") == ["syrniki"]
    # яичные и банковые категории без соответствующего типа завтрака не нужны
    assert _ids(out, "egg_addin") == []
    assert _ids(out, "jar_base") == []
    # супов не выбирали — и предлагать нечего
    assert _ids(out, "soup") == []


def test_narrow_catalog_keeps_egg_parts_when_eggs_picked():
    out = narrow_catalog(_request(proteins=["protein_1"], breakfasts=["eggs"]), _catalog())

    assert len(_ids(out, "egg_style")) == 6  # способ готовки покупок не добавляет
    assert len(_ids(out, "egg_addin")) == 4  # а добавки — добавляют, отсюда потолок


def test_narrow_catalog_gives_slack_for_allergies():
    req = GenerationRequestSchema.model_validate({
        "picks": {"proteins": ["protein_1"], "sides": [], "soups": [],
                  "breakfasts": [], "custom": []},
        "preferences": {"allergies": ["dairy"]},
    })
    out = narrow_catalog(req, _catalog())

    # с аллергией палитра шире: модели нужно из чего выбирать, чтобы её соблюсти
    assert len(_ids(out, "sauce")) == 5


def test_narrow_catalog_prefers_style_sauces():
    req = GenerationRequestSchema.model_validate({
        "picks": {"proteins": ["protein_1"], "sides": [], "soups": [],
                  "breakfasts": [], "custom": []},
        "preferences": {"weekStyle": "asian"},
    })
    out = narrow_catalog(req, _catalog())

    assert "soy_sesame" in _ids(out, "sauce")


def test_narrow_catalog_sides_capped_when_chef_picked_none():
    out = narrow_catalog(_request(proteins=["protein_1"]), _catalog())

    # гарниры не выбраны — модель получает три варианта, а не все двадцать
    assert len(_ids(out, "side")) == 3


# --- Принудительная палитра ------------------------------------------------


def _raw_menu(*meals: list[str]) -> dict:
    days = [{"weekday": "monday", "lunch": {"kind": "main", "modules": list(m)}}
            for m in meals]
    return {"weeks": [{"index": 0, "days": days}]}


def test_enforce_palette_replaces_ids_outside_catalog():
    allowed = [_FakeModule("rice", "side"), _FakeModule("buckwheat", "side"),
               _FakeModule("chicken_breast", "protein")]
    module_map = {m.id: m for m in allowed} | {"quinoa": _FakeModule("quinoa", "side")}

    out = enforce_palette(_raw_menu(["chicken_breast", "quinoa"]), module_map, allowed)
    ids = out["weeks"][0]["days"][0]["lunch"]["modules"]

    assert ids[0] == "chicken_breast"  # выбор Шефа не трогаем
    assert ids[1] in {"rice", "buckwheat"}  # киноа не в палитре — заменена


def test_enforce_palette_does_not_duplicate_within_meal():
    allowed = [_FakeModule("addin_cheese", "egg_addin"),
               _FakeModule("addin_tomatoes", "egg_addin")]
    module_map = {m.id: m for m in allowed} | {
        "addin_bacon": _FakeModule("addin_bacon", "egg_addin"),
        "addin_feta": _FakeModule("addin_feta", "egg_addin"),
    }

    out = enforce_palette(_raw_menu(["addin_bacon", "addin_feta"]), module_map, allowed)
    ids = out["weeks"][0]["days"][0]["lunch"]["modules"]

    assert len(set(ids)) == 2, "«омлет · сыр, сыр» — это баг, а не блюдо"


def test_enforce_palette_keeps_unknown_ids_untouched():
    allowed = [_FakeModule("rice", "side")]
    out = enforce_palette(_raw_menu(["nonsense_id"]), {}, allowed)

    # категория неизвестна — подменять не на что; пусть дальше решает expand_menu
    assert out["weeks"][0]["days"][0]["lunch"]["modules"] == ["nonsense_id"]


def test_narrow_catalog_side_palette_has_grains():
    mods = [_FakeModule(f"bean_{i}", "side") for i in range(10)]
    mods += [_FakeModule(f"grain_{i}", "side", ["grain"]) for i in range(9)]
    mods.append(_FakeModule("protein_1", "protein"))

    for _ in range(20):  # выбор случайный — проверяем, что крупы есть всегда
        out = narrow_catalog(_request(proteins=["protein_1"]), mods)
        sides = _ids(out, "side")
        assert len(sides) == 3
        assert sum(s.startswith("grain_") for s in sides) >= 2, sides


def _request_full(**kw) -> GenerationRequestSchema:
    picks = {"proteins": [], "sides": [], "soups": [], "breakfasts": [],
             "custom": [], "eggStyles": [], "eggAddins": [],
             "porridgeKinds": [], "sandwichFillings": []}
    picks.update(kw.pop("picks", {}))
    return GenerationRequestSchema.model_validate({"picks": picks, **kw})


def test_narrow_catalog_honours_chef_egg_picks():
    req = _request_full(picks={
        "proteins": ["protein_1"], "breakfasts": ["eggs"],
        "eggStyles": ["egg_style_0"], "eggAddins": ["addin_0", "addin_1"],
    })
    out = narrow_catalog(req, _catalog())

    # Шеф уточнил — значит это приказ, а не пожелание: никаких бекона и феты,
    # которых он не выбирал.
    assert _ids(out, "egg_style") == ["egg_style_0"]
    assert sorted(_ids(out, "egg_addin")) == ["addin_0", "addin_1"]


def test_narrow_catalog_falls_back_when_chef_did_not_specify():
    req = _request_full(picks={"proteins": ["protein_1"], "breakfasts": ["eggs"]})
    out = narrow_catalog(req, _catalog())

    # Не уточнял — добираем сами, но с потолком.
    assert len(_ids(out, "egg_style")) == 6
    assert len(_ids(out, "egg_addin")) == 4


def test_narrow_catalog_ignores_stale_egg_picks_without_eggs_breakfast():
    req = _request_full(picks={
        "proteins": ["protein_1"], "breakfasts": ["syrniki"],
        "eggStyles": ["egg_style_0"], "eggAddins": ["addin_0"],
    })
    out = narrow_catalog(req, _catalog())

    # Тип завтрака «яйца» не выбран — старые уточнения не должны его воскрешать.
    assert _ids(out, "egg_style") == []
    assert _ids(out, "egg_addin") == []


def test_narrow_catalog_keeps_porridge_kinds():
    mods = _catalog() + [_FakeModule("porridge_oat", "breakfast"),
                         _FakeModule("porridge_millet", "breakfast")]
    req = _request_full(picks={
        "proteins": ["protein_1"], "breakfasts": ["syrniki"],
        "porridgeKinds": ["porridge_oat"],
    })
    out = narrow_catalog(req, mods)

    assert sorted(_ids(out, "breakfast")) == ["porridge_oat", "syrniki"]


def test_weeks_defaults_to_two_for_old_clients():
    assert _request_full().weeks == 2
    assert _request_full(weeks=3).weeks == 3
