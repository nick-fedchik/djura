#!/usr/bin/env python3
"""Емпірична оцінка складності рівнів і гравців за телеметрією (SWR-002-07).

Читає події схеми v1 (`events.jsonl`), будує:
  * воронку (початі / завершені / залишені рівні);
  * калібровку Раша з дробовим результатом: P(виконання) = σ(θ_гравця − (log2 K + c_етапу));
    c_етапу — емпірична поправка складності етапу серії (аналог статичного зсуву level_difficulty.gd);
  * точність прогнозу моделі гри (p_pred проти фактичної якості);
  * прапорці «надто легко / надто важко».
Без зовнішніх залежностей. Нічого не надсилає в мережу.
"""
import argparse
import json
import math
import os
import sys
from collections import defaultdict

DEFAULT_PATH = os.path.expanduser("~/.local/share/godot/app_userdata/Geek Jack/telemetry/events.jsonl")
SERIES = 5


def load_events(paths):
    events = []
    for p in paths:
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    e = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if isinstance(e, dict) and e.get("v") == 1 and "type" in e:
                    events.append(e)
    return events


def sigmoid(x):
    return 1.0 / (1.0 + math.exp(-max(-30.0, min(30.0, x))))


def stage_of(level):
    return (int(level) - 1) % SERIES + 1


def observations(events):
    """Список (pid, stage, log2K, y) із завершених рівнів."""
    obs = []
    for e in events:
        if e["type"] == "level_end" and e.get("completed", True) and "quality" in e and "k" in e and "level" in e:
            obs.append((e["pid"], stage_of(e["level"]), math.log2(max(float(e["k"]), 0.05)), min(1.0, max(0.0, float(e["quality"])))))
    return obs


def fit_rasch(obs, iters=60, prior_theta_var=1.0, prior_stage_var=0.25):
    """Спільна оцінка θ_p і c_s методом Ньютона з гауссівськими апріорами (дробові результати)."""
    players = sorted({o[0] for o in obs})
    stages = sorted({o[1] for o in obs})
    theta = {p: 0.0 for p in players}
    c = {s: 0.0 for s in stages}
    for _ in range(iters):
        g = defaultdict(float); h = defaultdict(float)
        for pid, s, lk, y in obs:
            p = sigmoid(theta[pid] - (lk + c[s]))
            g[("p", pid)] += y - p
            h[("p", pid)] += max(p * (1 - p), 1e-3)
        for pid in players:
            gr = g[("p", pid)] - theta[pid] / prior_theta_var
            hs = h[("p", pid)] + 1 / prior_theta_var
            theta[pid] += gr / hs
        g = defaultdict(float); h = defaultdict(float)
        for pid, s, lk, y in obs:
            p = sigmoid(theta[pid] - (lk + c[s]))
            g[s] += (y - p)       # градієнт втрат за c: більша c — важче, тож результат нижчий
            h[s] += max(p * (1 - p), 1e-3)
        for s in stages:
            gr = g[s] + c[s] / prior_stage_var
            hs = h[s] + 1 / prior_stage_var
            c[s] -= gr / hs
        # ідентифікованість: нульова середня поправка етапів
        m = sum(c.values()) / len(c)
        for s in c:
            c[s] -= m
    return theta, c


def summarize(events):
    by_type = defaultdict(int)
    for e in events:
        by_type[e["type"]] += 1
    obs = observations(events)
    theta, c = fit_rasch(obs) if obs else ({}, {})
    starts = defaultdict(int); ends = defaultdict(int); aband = defaultdict(int)
    qual = defaultdict(list); times = defaultdict(list); hits = defaultdict(list)
    errs = []
    for e in events:
        lv = e.get("level")
        if e["type"] == "level_start" and lv is not None:
            starts[stage_of(lv)] += 1
        elif e["type"] == "level_end" and lv is not None and e.get("completed", True):
            s = stage_of(lv)
            ends[s] += 1
            if "quality" in e: qual[s].append(float(e["quality"]))
            if "time_s" in e: times[s].append(float(e["time_s"]))
            if "hits" in e: hits[s].append(float(e["hits"]))
            if "p_pred" in e and "quality" in e:
                errs.append(float(e["quality"]) - float(e["p_pred"]))
        elif e["type"] == "abandon" and lv is not None:
            aband[stage_of(lv)] += 1
    stages = sorted(set(starts) | set(ends) | set(aband))
    mean = lambda xs: sum(xs) / len(xs) if xs else None
    rows = []
    for s in stages:
        q = mean(qual[s])
        flag = ""
        if q is not None and len(qual[s]) >= 3:
            flag = "надто важко" if q < 0.35 else ("надто легко" if q > 0.9 else "")
        rows.append({"stage": s, "started": starts[s], "completed": ends[s], "abandoned": aband[s],
                     "mean_quality": q, "mean_time_s": mean(times[s]), "mean_hits": mean(hits[s]),
                     "rasch_offset": c.get(s), "flag": flag})
    return {
        "events": len(events), "event_types": dict(by_type), "players": len({e["pid"] for e in events}),
        "sessions": len({e["sid"] for e in events}),
        "stages": rows,
        "players_theta": {p[:6]: round(t, 3) for p, t in theta.items()},
        "model_bias": mean(errs), "model_rmse": math.sqrt(mean([x * x for x in errs])) if errs else None,
        "levels_observed": len(obs),
    }


def render_markdown(s):
    out = ["# Звіт телеметрії", "",
           f"Подій: {s['events']}, гравців: {s['players']}, сесій: {s['sessions']}, пройдених рівнів: {s['levels_observed']}", ""]
    out.append("| Етап | Початих | Завершених | Залишених | Якість | Час, с | Удари | Поправка Раша | Прапорець |")
    out.append("|---|---|---|---|---|---|---|---|---|")
    f = lambda x, n=2: "–" if x is None else f"{x:.{n}f}"
    for r in s["stages"]:
        out.append(f"| {r['stage']} | {r['started']} | {r['completed']} | {r['abandoned']} | {f(r['mean_quality'])} | {f(r['mean_time_s'], 1)} | {f(r['mean_hits'], 1)} | {f(r['rasch_offset'])} | {r['flag']} |")
    out += ["", f"Прогноз моделі: зсув {f(s['model_bias'], 3)}, RMSE {f(s['model_rmse'], 3)} (чим ближче до 0, тим краще)"]
    if s["players_theta"]:
        out += ["", "Оцінка вміння гравців (логіти): " + ", ".join(f"{p}: {t:+.2f}" for p, t in s["players_theta"].items())]
    return "\n".join(out) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("paths", nargs="*", default=[DEFAULT_PATH, DEFAULT_PATH.replace("events.jsonl", "events.1.jsonl")])
    ap.add_argument("--json", action="store_true", help="вивести підсумок у JSON")
    ap.add_argument("--out", help="записати Markdown-звіт у файл")
    a = ap.parse_args(argv)
    events = load_events(a.paths)
    if not events:
        print("Телеметрії ще немає: пограйте хоча б один рівень (шлях: %s)" % a.paths[0], file=sys.stderr)
        return 1
    s = summarize(events)
    text = json.dumps(s, ensure_ascii=False, indent=2) if a.json else render_markdown(s)
    if a.out:
        with open(a.out, "w", encoding="utf-8") as f:
            f.write(render_markdown(s))
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
