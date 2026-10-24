#!/usr/bin/env python3
"""Детермінований валідатор пропозицій від Ollama (SWR-002-08): «евристика пропонує, детермінований код допускає».

Приймає лише параметри з білого списку й значення в межах; відкидає невідоме, нечислове, NaN/Inf, зайві ключі,
надто довгі пояснення та перевищення кількості пропозицій. Нічого не змінює в коді гри: результат лише для людини.
"""
import math

# параметр -> (мін, макс)
ALLOWED = {
    "Difficulty.PAR_TIME_S": (45.0, 180.0),
    "Difficulty.SERIES_GROWTH": (0.10, 0.60),
    "Difficulty.QUALITY_SWING": (0.20, 0.80),
    "Difficulty.MAX_ALIVE_ENEMIES": (6.0, 14.0),
    "PlayerModel.PROCESS_NOISE": (0.01, 0.20),
    "PlayerModel.SLEW": (0.10, 0.40),
    "PlayerModel.CURRICULUM_BETA": (0.0, 0.60),
    "PlayerModel.TARGETS.novice": (0.60, 0.90),
    "PlayerModel.TARGETS.casual": (0.55, 0.85),
    "PlayerModel.TARGETS.experienced": (0.50, 0.80),
    "LevelDifficulty.SCALE": (0.05, 0.40),
}
MAX_PROPOSALS = 8
MAX_RATIONALE = 400
ALLOWED_KEYS = {"param", "suggested", "rationale"}


def validate(payload):
    """Повертає (прийняті, відхилені); відхилені — список (пропозиція, причина)."""
    accepted, rejected = [], []
    if not isinstance(payload, dict) or not isinstance(payload.get("proposals"), list):
        return [], [(payload, "очікується об'єкт із масивом proposals")]
    for i, p in enumerate(payload["proposals"]):
        if i >= MAX_PROPOSALS:
            rejected.append((p, f"понад {MAX_PROPOSALS} пропозицій"))
            continue
        if not isinstance(p, dict):
            rejected.append((p, "пропозиція має бути об'єктом"))
            continue
        extra = set(p) - ALLOWED_KEYS
        if extra:
            rejected.append((p, f"зайві ключі: {sorted(extra)}"))
            continue
        param = p.get("param")
        if param not in ALLOWED:
            rejected.append((p, f"параметр поза білим списком: {param!r}"))
            continue
        v = p.get("suggested")
        if isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v):
            rejected.append((p, "значення має бути скінченним числом"))
            continue
        lo, hi = ALLOWED[param]
        if not (lo <= v <= hi):
            rejected.append((p, f"значення {v} поза межами [{lo}, {hi}]"))
            continue
        why = p.get("rationale", "")
        if not isinstance(why, str) or len(why) > MAX_RATIONALE:
            rejected.append((p, f"пояснення має бути рядком до {MAX_RATIONALE} символів"))
            continue
        accepted.append({"param": param, "suggested": float(v), "rationale": why})
    return accepted, rejected
