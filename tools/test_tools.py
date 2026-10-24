#!/usr/bin/env python3
"""Тести інструментів телеметрії та дорадчого огляду (SWR-002-07, SWR-002-08)."""
import json
import math
import os
import random
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import analyze_telemetry as at
import ollama_review as orv
import tuning_validator as tv

TRUE_C = {1: 0.0, 2: 0.5, 3: -0.3, 4: -0.6, 5: 0.4}   # відомі поправки етапів (середня ≈ 0)


def synth_events(n_players=40, levels=15, seed=3):
    rng = random.Random(seed)
    ev = []
    for i in range(n_players):
        pid = "p%03d" % i
        theta = rng.gauss(0.0, 1.0)
        for lvl in range(1, levels + 1):
            k = 2 ** rng.uniform(-0.6, 0.9)
            b = math.log2(k) + TRUE_C[at.stage_of(lvl)]
            p = at.sigmoid(theta - b)
            q = min(1.0, max(0.0, p + rng.gauss(0, 0.06)))
            ev.append({"v": 1, "t": lvl, "sid": "s" + pid, "pid": pid, "type": "level_start", "level": lvl, "k": k})
            ev.append({"v": 1, "t": lvl, "sid": "s" + pid, "pid": pid, "type": "level_end", "level": lvl, "k": k,
                       "quality": q, "time_s": 90.0 * (1.6 - 0.9 * q), "hits": round((1 - q) * 4), "p_pred": p, "completed": True})
    return ev


class AnalyzeTests(unittest.TestCase):
    def test_rasch_recovers_stage_offsets(self):
        s = at.summarize(synth_events())
        est = {r["stage"]: r["rasch_offset"] for r in s["stages"]}
        for st, true in TRUE_C.items():
            self.assertAlmostEqual(est[st], true - sum(TRUE_C.values()) / 5, delta=0.2, msg=f"етап {st}")
        self.assertLess(s["model_rmse"], 0.1)

    def test_flags_and_report(self):
        ev = synth_events(10, 5)
        for e in ev:
            if e["type"] == "level_end" and at.stage_of(e["level"]) == 2:
                e["quality"] = 0.1
        s = at.summarize(ev)
        flags = {r["stage"]: r["flag"] for r in s["stages"]}
        self.assertEqual(flags[2], "надто важко")
        self.assertIn("| Етап |", at.render_markdown(s))

    def test_load_ignores_garbage(self):
        with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False, encoding="utf-8") as f:
            f.write("не json\n" + json.dumps({"v": 2, "type": "x"}) + "\n" + json.dumps({"v": 1, "type": "level_end", "pid": "a", "sid": "b"}) + "\n")
        self.assertEqual(len(at.load_events([f.name])), 1)
        os.unlink(f.name)


class ValidatorTests(unittest.TestCase):
    def test_accepts_valid(self):
        ok, bad = tv.validate({"proposals": [{"param": "Difficulty.PAR_TIME_S", "suggested": 75, "rationale": "час проходження коротший"}]})
        self.assertEqual(len(ok), 1)
        self.assertEqual(bad, [])

    def test_rejects_hostile(self):
        cases = [
            {"param": "os.system", "suggested": 1, "rationale": ""},                       # поза білим списком
            {"param": "Difficulty.PAR_TIME_S", "suggested": 9999, "rationale": ""},        # поза межами
            {"param": "Difficulty.PAR_TIME_S", "suggested": float("nan"), "rationale": ""},  # NaN
            {"param": "Difficulty.PAR_TIME_S", "suggested": "90; rm -rf", "rationale": ""},  # не число
            {"param": "Difficulty.PAR_TIME_S", "suggested": True, "rationale": ""},          # булеве
            {"param": "Difficulty.PAR_TIME_S", "suggested": 90, "rationale": "x" * 500},   # довге пояснення
            {"param": "Difficulty.PAR_TIME_S", "suggested": 90, "rationale": "", "exec": "x"},  # зайвий ключ
            "рядок",
        ]
        ok, bad = tv.validate({"proposals": cases})
        self.assertEqual(ok, [])
        self.assertEqual(len(bad), len(cases))

    def test_limits_count_and_shape(self):
        many = {"proposals": [{"param": "Difficulty.PAR_TIME_S", "suggested": 90, "rationale": ""}] * 12}
        ok, bad = tv.validate(many)
        self.assertEqual(len(ok), tv.MAX_PROPOSALS)
        self.assertEqual(len(bad), 4)
        self.assertEqual(tv.validate("не об'єкт")[0], [])


class ReviewTests(unittest.TestCase):
    def test_model_gets_only_aggregates(self):
        s = at.summarize(synth_events(5, 5))
        prompt = orv.build_prompt(orv.aggregate_for_model(s))
        for e in synth_events(5, 5):
            self.assertNotIn(e["pid"], prompt)   # ідентифікатори гравців не потрапляють у запит
            self.assertNotIn(e["sid"], prompt)
        self.assertNotIn("players_theta", prompt)

    def test_review_filters_model_output(self):
        s = at.summarize(synth_events(5, 5))
        fake = lambda _prompt: json.dumps({"observations": ["рівень 2 важкий"], "proposals": [
            {"param": "PlayerModel.SLEW", "suggested": 0.2, "rationale": "плавніше"},
            {"param": "Difficulty.K_MAX", "suggested": 99, "rationale": "зламати гру"}]})
        r = orv.review(s, ask=fake)
        self.assertEqual([p["param"] for p in r["accepted"]], ["PlayerModel.SLEW"])
        self.assertEqual(len(r["rejected"]), 1)

    def test_non_json_reply_is_safe(self):
        r = orv.review(at.summarize(synth_events(3, 3)), ask=lambda _p: "Звісно! Ось поради...")
        self.assertEqual(r["accepted"], [])
        self.assertEqual(len(r["rejected"]), 1)


if __name__ == "__main__":
    unittest.main(verbosity=1)
