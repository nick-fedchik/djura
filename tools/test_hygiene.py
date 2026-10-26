#!/usr/bin/env python3
"""Гігієна інструментів (TLS-01, TLS-02, TLS-07): жодних абсолютних домашніх шляхів,
вихідні каталоги генераторів звуку всередині репозиторію, сторонні залежності задекларовані."""
import os
import re
import runpy
import unittest

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
TOOLS = os.path.join(ROOT, "tools")
HOME_PATH = re.compile(r"/home/[a-z][a-z0-9_-]*/")
THIRD_PARTY = {"numpy": "numpy", "PIL": "Pillow"}


def tool_files(exts):
    for base, dirs, files in os.walk(TOOLS):
        dirs[:] = [d for d in dirs if d != "__pycache__"]
        for f in files:
            if f.endswith(exts) and f != "test_hygiene.py":
                yield os.path.join(base, f)


class ToolHygiene(unittest.TestCase):
    def test_no_absolute_home_paths(self):
        bad = []
        for path in tool_files((".py", ".sh", ".js")):
            with open(path, encoding="utf-8") as fh:
                for n, line in enumerate(fh, 1):
                    if HOME_PATH.search(line):
                        bad.append(f"{os.path.relpath(path, ROOT)}:{n}")
        self.assertEqual(bad, [], "абсолютні шляхи до домашнього каталогу")

    def test_audio_generators_write_inside_repo(self):
        audio_dir = os.path.join(TOOLS, "audio")
        scripts = [f for f in os.listdir(audio_dir) if f.endswith(".py")]
        self.assertGreaterEqual(len(scripts), 10)
        target = os.path.join(ROOT, "assets", "audio")
        for name in scripts:
            ns = runpy.run_path(os.path.join(audio_dir, name), run_name="not_main")
            self.assertEqual(os.path.normpath(ns["OUT_DIR"]), target, name)

    def test_third_party_imports_are_declared(self):
        with open(os.path.join(TOOLS, "requirements.txt"), encoding="utf-8") as fh:
            declared = fh.read().lower()
        for path in tool_files((".py",)):
            if os.sep + "blender" + os.sep in path:
                continue  # bpy/mathutils постачає Blender
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
            for module, package in THIRD_PARTY.items():
                if re.search(rf"^\s*(import|from) {module}\b", text, re.M):
                    self.assertIn(package.lower(), declared, f"{os.path.relpath(path, ROOT)} імпортує {module}")


if __name__ == "__main__":
    unittest.main(verbosity=1)
