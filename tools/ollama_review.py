#!/usr/bin/env python3
"""Дорадчий огляд досвіду гравців через Ollama (SWR-002-08). Поза ігровим циклом, лише для розробника.

Модель отримує ЛИШЕ агрегований підсумок (без подій і ідентифікаторів гравців), повертає JSON із пропозиціями
змін параметрів; кожна пропозиція проходить tools/tuning_validator.py. Результат — файл для людини,
код гри не змінюється. Сервер задається OLLAMA_HOST (за замовчуванням вузол J501), модель OLLAMA_MODEL.
"""
import argparse
import json
import os
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import analyze_telemetry as at  # noqa: E402
import tuning_validator as tv  # noqa: E402

J501_DEFAULT_HOST = "http://192.168.68.68:11434"  # вузол J501; інший задайте через OLLAMA_HOST (TLS-03)
HOST = os.environ.get("OLLAMA_HOST", J501_DEFAULT_HOST)
MODEL = os.environ.get("OLLAMA_MODEL", "gemma4:12b")

SCHEMA_HINT = {
    "observations": ["коротке спостереження про досвід гравців (рядок)"],
    "proposals": [{"param": "одне з: " + ", ".join(sorted(tv.ALLOWED)), "suggested": 0.0, "rationale": "чому (до 400 символів)"}],
}


def aggregate_for_model(summary):
    """Прибирає все, що ідентифікує гравця; лишає лише агрегати."""
    keep = {k: summary[k] for k in ("events", "players", "sessions", "levels_observed", "model_bias", "model_rmse")}
    keep["stages"] = summary["stages"]
    thetas = list(summary.get("players_theta", {}).values())
    keep["skill_spread"] = {"min": min(thetas), "max": max(thetas)} if thetas else None
    return keep


def build_prompt(agg):
    return (
        "Ти аналітик ігрового досвіду дитячої платформної гри (вік 8+). Нижче агрегована телеметрія без особистих даних.\n"
        "Оціни, чи достатньо адаптується складність, і запропонуй НЕ БІЛЬШЕ 5 змін параметрів. Дозволені параметри та межі:\n"
        + "\n".join(f"- {k}: [{lo}, {hi}]" for k, (lo, hi) in sorted(tv.ALLOWED.items()))
        + "\nВідповідай ЛИШЕ JSON за схемою: " + json.dumps(SCHEMA_HINT, ensure_ascii=False)
        + "\nДані:\n" + json.dumps(agg, ensure_ascii=False)
    )


def ask_ollama(prompt, host=HOST, model=MODEL, timeout=120):
    body = json.dumps({"model": model, "prompt": prompt, "stream": False, "format": "json",
                       "options": {"temperature": 0.2}}).encode()
    req = urllib.request.Request(host.rstrip("/") + "/api/generate", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())["response"]


def review(summary, ask=ask_ollama):
    prompt = build_prompt(aggregate_for_model(summary))
    raw = ask(prompt)
    try:
        payload = json.loads(raw)
    except (json.JSONDecodeError, TypeError):
        return {"raw": str(raw)[:2000], "accepted": [], "rejected": [{"proposal": None, "reason": "відповідь не є JSON"}], "observations": []}
    accepted, rejected = tv.validate(payload)
    obs = payload.get("observations", []) if isinstance(payload, dict) else []
    obs = [o[:400] for o in obs if isinstance(o, str)][:10]
    return {"accepted": accepted, "rejected": [{"proposal": p, "reason": r} for p, r in rejected], "observations": obs}


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="*", default=[at.DEFAULT_PATH, at.DEFAULT_PATH.replace("events.jsonl", "events.1.jsonl")])
    ap.add_argument("--dry-run", action="store_true", help="лише показати запит до моделі")
    ap.add_argument("--out-dir", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "reports"))
    a = ap.parse_args(argv)
    if "OLLAMA_HOST" not in os.environ and not a.dry_run:
        print(f"[Warning] OLLAMA_HOST не задано, використовується вузол J501 за замовчуванням ({J501_DEFAULT_HOST})", file=sys.stderr)
    events = at.load_events(a.paths)
    if not events:
        print("Телеметрії ще немає.", file=sys.stderr)
        return 1
    summary = at.summarize(events)
    if a.dry_run:
        print(build_prompt(aggregate_for_model(summary)))
        return 0
    result = review(summary)
    os.makedirs(a.out_dir, exist_ok=True)
    path = os.path.join(a.out_dir, "tuning_proposals_%s.json" % time.strftime("%Y%m%d_%H%M%S"))
    with open(path, "w", encoding="utf-8") as f:
        json.dump({"model": MODEL, "host_set": bool(os.environ.get("OLLAMA_HOST")), **result}, f, ensure_ascii=False, indent=2)
    print("Прийнято пропозицій: %d, відхилено: %d. Файл для людини: %s" % (len(result["accepted"]), len(result["rejected"]), path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
