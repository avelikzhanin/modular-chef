"""Async-клиент LLM: грузит промпт-шаблон, отправляет каталог + запрос,
возвращает строго `WeeklyMenuSchema`.

Реализация — OpenAI с JSON mode (`response_format={"type": "json_object"}`),
который гарантирует валидный JSON в ответе. Имя файла нейтральное —
если решим сменить провайдера, меняется только это место.

Источник промпта: ``../assets/prompts/menu_generator.md``.
"""
from __future__ import annotations

import json
import logging
import random
import re
import zlib
from pathlib import Path

from openai import AsyncOpenAI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import Module
from app.schemas import GenerationRequestSchema, WeeklyMenuSchema

logger = logging.getLogger(__name__)


def _prompt_path() -> Path:
    """assets/prompts/menu_generator.md в корне репозитория."""
    here = Path(__file__).resolve()
    project_root = here.parents[2]  # backend/app/llm_client.py → modular_chef/
    return project_root / "assets" / "prompts" / "menu_generator.md"


def _strip_json_wrapper(text: str) -> str:
    """В JSON-mode OpenAI отдаёт чистый JSON, но на всякий случай снимаем
    возможный ```json … ``` или ведущую прозу — пайплайн будет устойчив
    и если случайно переключимся на модель без JSON mode."""
    fence = re.search(r"```(?:json)?\s*(.+?)\s*```", text, flags=re.DOTALL)
    candidate = fence.group(1) if fence else text
    first = candidate.find("{")
    last = candidate.rfind("}")
    if first == -1 or last == -1:
        return candidate
    return candidate[first : last + 1]


def parse_llm_response(raw: str) -> WeeklyMenuSchema:
    """Pure-функция парсинга. Тестируется напрямую без сетевых вызовов."""
    cleaned = _strip_json_wrapper(raw)
    data = json.loads(cleaned)
    return WeeklyMenuSchema.model_validate(data)


# --- Компактный контракт LLM → полное меню --------------------------------
# Чтобы не жечь токены, LLM возвращает на каждый приём только `kind` + список
# `modules` (id в порядке ролей). Роли, имена, эмодзи, заголовки, контейнеры и
# статистику достраивает бэкенд из каталога. Экономия вывода в 3-4 раза.

_WEEKDAY_SHORT = {
    "monday": "Пн", "tuesday": "Вт", "wednesday": "Ср", "thursday": "Чт",
    "friday": "Пт", "saturday": "Сб", "sunday": "Вс",
}
_CAT_ROLE = {
    "protein": "protein", "side": "side", "vegetable": "vegetable",
    "sauce": "sauce", "egg_style": "egg_style", "egg_addin": "addition",
    "jar_base": "jar_base", "jar_barrier": "jar_barrier",
    "jar_middle": "jar_middle", "jar_top": "jar_top",
    "breakfast": "standalone", "soup": "standalone", "snack": "standalone",
}
_ZONE_RU = {
    "fridge": "холодильник", "freezer": "морозилка",
    "vacuum": "вакуум", "pantry": "кладовая",
}


def _component(mod_id: str, module_map: dict) -> dict:
    m = module_map.get(mod_id)
    if m is None:
        return {"moduleId": mod_id, "role": "standalone", "name": mod_id, "emoji": ""}
    return {
        "moduleId": mod_id,
        "role": _CAT_ROLE.get(m.category, "standalone"),
        "name": m.name,
        "emoji": m.emoji or "",
    }


def _derive_title(comps: list[dict], kind: str) -> str:
    names = [c["name"] for c in comps]
    if not names:
        return "—"
    if kind == "main":
        return " + ".join(names)
    if len(names) == 1:
        return names[0]
    return names[0] + " · " + ", ".join(n.lower() for n in names[1:])


def _derive_container(comps: list[dict], module_map: dict) -> str:
    for c in comps:
        m = module_map.get(c["moduleId"])
        if m is not None:
            return _ZONE_RU.get(m.storage_zone, "")
    return ""


def _build_meal(raw: dict, module_map: dict) -> dict:
    kind = raw.get("kind", "main")
    ids = raw.get("modules")
    if ids is None:  # терпим и старый формат с готовыми components
        ids = [c.get("moduleId") for c in raw.get("components", []) if c.get("moduleId")]
    comps = [_component(i, module_map) for i in ids]
    return {
        "title": raw.get("title") or _derive_title(comps, kind),
        "kind": kind,
        "components": comps,
        "reheatMinutes": int(raw.get("reheatMinutes", 0) or 0),
        "fromContainer": raw.get("fromContainer") or _derive_container(comps, module_map),
    }


def _empty_meal(kind: str) -> dict:
    return {"title": "—", "kind": kind, "components": [], "reheatMinutes": 0, "fromContainer": ""}


def expand_menu(raw: dict, module_map: dict) -> dict:
    """Компактный ответ LLM → полная `WeeklyMenu`-схема (роли/имена/эмодзи/
    контейнеры/статистика из каталога)."""
    titles: set[str] = set()
    module_ids: set[str] = set()
    total = 0
    weeks_out = []
    for wi, w in enumerate(raw.get("weeks", [])):
        days_out = []
        for d in w.get("days", []):
            weekday = d.get("weekday", "monday")
            day_out = {
                "weekday": weekday,
                "shortName": d.get("shortName") or _WEEKDAY_SHORT.get(weekday, ""),
            }
            for slot, default_kind in (("breakfast", "breakfast"), ("lunch", "main"), ("dinner", "main")):
                raw_meal = d.get(slot)
                if raw_meal:
                    meal = _build_meal(raw_meal, module_map)
                    day_out[slot] = meal
                    total += 1
                    titles.add(meal["title"])
                    module_ids.update(c["moduleId"] for c in meal["components"])
                else:
                    day_out[slot] = _empty_meal(default_kind)
            if d.get("snack"):
                meal = _build_meal(d["snack"], module_map)
                day_out["snack"] = meal
                total += 1
                titles.add(meal["title"])
                module_ids.update(c["moduleId"] for c in meal["components"])
            days_out.append(day_out)
        weeks_out.append({
            "index": w.get("index", wi),
            "name": w.get("name") or f"Неделя {wi + 1}",
            "days": days_out,
        })
    summary_raw = raw.get("summary") or {}
    return {
        "weeks": weeks_out,
        "summary": {
            "uniqueDishes": len(titles),
            "totalMeals": total,
            "modulesUsed": len(module_ids),
            "flavourProfiles": summary_raw.get("flavourProfiles", []),
        },
    }


# --- Сужение каталога перед отправкой в LLM --------------------------------
# Модель, получив весь каталог, насыпает на 14 дней по 12 соусов и 11 гарниров:
# меню выглядит богато, а список покупок становится нереальным. Просить её
# «не разнообразить» бесполезно — проверено, правило в промпте игнорируется.
# Поэтому выбор сужаем здесь: чего нет в каталоге, того модель не закажет.
# Мил-преп держится на повторном использовании одних и тех же продуктов.
_AUTO_CAPS = {
    "vegetable": 3,
    "sauce": 3,
    "egg_addin": 4,
    "jar_base": 2,
    "jar_barrier": 2,
    "jar_middle": 3,
    "jar_top": 2,
    "snack": 2,
    "side": 3,  # сработает только если Шеф не выбрал гарниры сам
    "protein": 3,  # то же: страховка на случай пустых picks
}

# Соус «под кухню»: при выбранном стиле недели сначала берём подходящие по
# тегам, иначе палитра из трёх позиций легко окажется мимо стиля.
_STYLE_TAGS = {
    "mediterranean": {"italian", "fresh"},
    "asian": {"asian"},
    "russian_classic": {"comfort", "classic"},
}

# Категории, которых в каталоге быть не должно, если соответствующий тип
# завтрака не выбран: иначе модель подмешает банки в дни, где их не просили.
_EGG_CATS = {"egg_style", "egg_addin"}
_JAR_CATS = {"jar_base", "jar_barrier", "jar_middle", "jar_top"}


def _pick_some(
    pool: list,
    cap: int,
    rng,
    style: str | None = None,
    must_tag: str | None = None,
    must_count: int = 0,
) -> list:
    """Берёт из категории не больше `cap` модулей. `must_tag` гарантирует, что
    в палитре будет хотя бы `must_count` позиций с этим тегом: чистый random
    выдаёт наборы вроде «нут + чечевица» — две недели без единой крупы."""
    if len(pool) <= cap:
        return pool
    wanted = _STYLE_TAGS.get(style or "", set())
    ranked = list(pool)
    rng.shuffle(ranked)
    if wanted:
        ranked.sort(key=lambda m: 0 if wanted & set(m.tags or []) else 1)
    picked: list = []
    if must_tag and must_count:
        picked = [m for m in ranked if must_tag in (m.tags or [])][:must_count]
    for m in ranked:
        if len(picked) >= cap:
            break
        if m not in picked:
            picked.append(m)
    return picked[:cap]


def narrow_catalog(
    request: GenerationRequestSchema,
    modules: list,
    rng: random.Random | None = None,
) -> list:
    """Оставляет в каталоге выбранное Шефом плюс ограниченную палитру того,
    что модель добирает сама. Палитра каждый раз новая — разнообразие живёт
    между меню, а не внутри одного списка покупок."""
    rng = rng or random.Random()
    picks = request.picks
    style = request.preferences.weekStyle
    # С аллергиями палитру из трёх позиций модель может не суметь собрать —
    # даём запас, чтобы ей было из чего выбирать, не нарушая ограничение.
    slack = 2 if request.preferences.allergies else 0

    by_cat: dict[str, list] = {}
    for m in modules:
        by_cat.setdefault(m.category, []).append(m)

    # Выбор Шефа внутри типа завтрака. Пустой список значит «не уточнял» —
    # тогда добираем сами; непустой отдаём как есть, без потолков.
    explicit_by_cat = {
        "protein": set(picks.proteins),
        "side": set(picks.sides),
        "soup": set(picks.soups),
        "breakfast": set(picks.breakfasts) | set(picks.porridgeKinds),
        "egg_style": set(picks.eggStyles),
        "egg_addin": set(picks.eggAddins),
    }
    # Начинка бутербродов — такие же покупки, как всё остальное, и живёт она в
    # чужих категориях (добавки к яйцам, овощи), поэтому проносим её отдельно.
    forced = set(picks.custom)
    if "sandwiches" in picks.breakfasts:
        forced |= set(picks.sandwichFillings)

    chosen: list = []
    for cat, pool in by_cat.items():
        # Сначала отсекаем категории целиком: если тип завтрака не выбран, его
        # составные части не нужны, даже если что-то осталось в старых пиках.
        if cat in _EGG_CATS and "eggs" not in picks.breakfasts:
            continue
        if cat in _JAR_CATS and "jar" not in picks.breakfasts:
            continue
        explicit = explicit_by_cat.get(cat)
        if explicit is not None:
            picked = [m for m in pool if m.id in explicit or m.id in forced]
            if picked:
                chosen.extend(picked)
                continue
            if cat == "soup":
                continue  # супов не выбрали — и не предлагаем
        if cat == "egg_style":
            chosen.extend(pool)  # способ готовки яиц покупок не добавляет
            continue
        cap = _AUTO_CAPS.get(cat)
        if cap is None:
            chosen.extend(pool)
            continue
        forced_mods = [m for m in pool if m.id in forced]
        rest = [m for m in pool if m.id not in forced]
        must_tag, must_count = ("grain", 2) if cat == "side" else (None, 0)
        chosen.extend(
            forced_mods
            + _pick_some(rest, cap + slack, rng, style, must_tag, must_count)
        )
    return chosen


def enforce_palette(raw: dict, module_map: dict, allowed: list) -> dict:
    """Заменяет id, которых не было в суженном каталоге, на разрешённые той же
    категории. Сужение каталога модель обходит: id вроде `rice` она знает и
    подставляет по памяти, даже когда их в каталоге нет. Замена делается по
    crc32 от исходного id — так выбор стабилен и равномерно расходится по
    палитре, а не сваливает всё в первый вариант."""
    allowed_ids = {m.id for m in allowed}
    by_cat: dict[str, list] = {}
    for m in allowed:
        by_cat.setdefault(m.category, []).append(m.id)
    for pool in by_cat.values():
        pool.sort()

    def fix(mod_id: str, used: set[str]) -> str:
        if mod_id in allowed_ids:
            return mod_id
        module = module_map.get(mod_id)
        pool = by_cat.get(module.category) if module is not None else None
        if not pool:
            return mod_id
        start = zlib.crc32(mod_id.encode()) % len(pool)
        # Две добавки в одном завтраке не должны схлопнуться в одну и ту же —
        # «омлет · сыр, сыр» выглядит как баг, поэтому крутим палитру дальше.
        for step in range(len(pool)):
            candidate = pool[(start + step) % len(pool)]
            if candidate not in used:
                return candidate
        return pool[start]

    for week in raw.get("weeks", []):
        for day in week.get("days", []):
            for slot in ("breakfast", "lunch", "dinner", "snack"):
                meal = day.get(slot)
                if not isinstance(meal, dict):
                    continue
                used: set[str] = set()
                if meal.get("modules"):
                    fixed = []
                    for mod_id in meal["modules"]:
                        picked = fix(mod_id, used)
                        used.add(picked)
                        fixed.append(picked)
                    meal["modules"] = fixed
                for comp in meal.get("components", []) or []:
                    if comp.get("moduleId"):
                        comp["moduleId"] = fix(comp["moduleId"], used)
                        used.add(comp["moduleId"])
                # Заголовок мог ссылаться на подменённое блюдо — пусть бэкенд
                # соберёт его заново из фактических модулей.
                meal.pop("title", None)
    return raw


class LlmClient:
    """Async обёртка над OpenAI SDK с промпт-template'ом и парсингом."""

    def __init__(
        self,
        api_key: str | None = None,
        model: str | None = None,
        prompt_path: Path | None = None,
    ) -> None:
        key = api_key or settings.openai_api_key
        if not key:
            raise RuntimeError(
                "OPENAI_API_KEY не задан. Проставьте env-переменную."
            )
        self._client = AsyncOpenAI(api_key=key)
        self._model = model or settings.openai_model
        self._prompt_path = prompt_path or _prompt_path()
        self._template: str | None = None  # lazy

    async def _template_text(self) -> str:
        if self._template is None:
            self._template = self._prompt_path.read_text(encoding="utf-8")
        return self._template

    def _payload(self, request: GenerationRequestSchema, modules: list) -> dict:
        """Готовит JSON, который пойдёт в промпт: запрос + суженный каталог."""
        return {
            **request.model_dump(),
            "catalog": {
                "modules": [
                    {
                        "id": m.id,
                        "name": m.name,
                        "emoji": m.emoji,
                        "category": m.category,
                        "tags": m.tags,
                        "methods": m.methods,
                        "storage": {
                            "zone": m.storage_zone,
                            "days": m.storage_days,
                            "tip": m.storage_tip or "",
                        },
                        "caloriesPer100g": m.calories_per_100g,
                        "prepMinutes": m.prep_minutes,
                    }
                    for m in modules
                ],
                "pairings": [],
                "templates": [],
            },
        }

    async def generate(
        self,
        request: GenerationRequestSchema,
        session: AsyncSession,
    ) -> WeeklyMenuSchema:
        """Запрос → компактный ответ LLM (только id модулей) → бэкенд достраивает
        полное меню из каталога. Компактный контракт экономит вывод в 3-4 раза."""
        template = await self._template_text()
        modules = (await session.execute(select(Module))).scalars().all()
        module_map = {m.id: m for m in modules}
        narrowed = narrow_catalog(request, modules)
        payload = self._payload(request, narrowed)
        full_prompt = (
            f"{template}\n\n## Текущий запрос\n\n```json\n"
            f"{json.dumps(payload, ensure_ascii=False, indent=2)}\n```\n"
            "\n## Формат ответа\n\nВерни **только** компактный JSON, как описано "
            "(на каждый приём `kind` + `modules`), без имён/эмодзи/ролей — бэкенд "
            "достроит их сам. Никакого markdown."
        )

        logger.info(
            "Calling OpenAI model=%s with %d modules in catalog",
            self._model,
            len(payload["catalog"]["modules"]),
        )

        completion = await self._client.chat.completions.create(
            model=self._model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Ты — кулинарный планировщик. Возвращай только компактный "
                        "JSON: на каждый приём `kind` и массив `modules` (id)."
                    ),
                },
                {"role": "user", "content": full_prompt},
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            # Компактный вывод (только id) маленький — лимита хватает с запасом.
            max_tokens=8000,
        )

        raw_text = (completion.choices[0].message.content or "").strip()
        logger.debug("LLM returned %d chars", len(raw_text))

        raw = enforce_palette(
            json.loads(_strip_json_wrapper(raw_text)), module_map, narrowed
        )
        return WeeklyMenuSchema.model_validate(expand_menu(raw, module_map))
