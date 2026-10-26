#!/usr/bin/env python3
"""
Unit and integration tests for the 3D-to-2D Sprite Generator pipeline.
Follows SWR-003-07 and ADR-003.
"""

import os
_PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))  # корінь репозиторію (TLS-02)
import json
import os
import sys
import unittest
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "blender"))
import pack_spritesheet
import vlm_sprite_auditor


class TestSpriteGeneratorPipeline(unittest.TestCase):
    def setUp(self):
        self.project_root = _PROJECT_ROOT
        self.sprites_dir = os.path.join(self.project_root, "assets", "sprites")
        self.models_dir = os.path.join(self.project_root, "sources", "models")

    def test_model_glb_exists(self):
        glb_path = os.path.join(self.models_dir, "test_cossack.glb")
        self.assertTrue(os.path.isfile(glb_path), f"Test GLB model missing: {glb_path}")
        self.assertGreater(os.path.getsize(glb_path), 500)

    def test_spritesheet_png_dimensions_and_alpha(self):
        sheet_path = os.path.join(self.sprites_dir, "test_cossack_sheet.png")
        self.assertTrue(os.path.isfile(sheet_path), f"Sprite sheet PNG missing: {sheet_path}")

        img = Image.open(sheet_path)
        self.assertEqual(img.mode, "RGBA", "Sprite sheet must have RGBA alpha channel")
        self.assertEqual(img.size, (384, 384), "Sprite sheet dimensions must match 3x3 of 128x128")

        # Check that corners have transparency (alpha == 0)
        extrema = img.getextrema()
        alpha_min = extrema[3][0]
        self.assertEqual(alpha_min, 0, "Sprite sheet background must be transparent")

    def test_manifest_json_format_and_pivot(self):
        manifest_path = os.path.join(self.sprites_dir, "test_cossack_manifest.json")
        self.assertTrue(os.path.isfile(manifest_path), f"Manifest JSON missing: {manifest_path}")

        with open(manifest_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        self.assertEqual(data.get("format"), "djura_spritesheet_v1")
        self.assertEqual(data.get("frame_width"), 128)
        self.assertEqual(data.get("frame_height"), 128)
        self.assertEqual(data.get("pivot_point"), [64.0, 128.0])  # Lower-center feet anchor
        self.assertEqual(data.get("total_frames"), 8)
        self.assertEqual(len(data.get("frames", [])), 8)

    def test_spriteframes_tres_syntax(self):
        tres_path = os.path.join(self.sprites_dir, "test_cossack_frames.tres")
        self.assertTrue(os.path.isfile(tres_path), f"SpriteFrames resource missing: {tres_path}")

        with open(tres_path, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn('[gd_resource type="SpriteFrames"', content)
        self.assertIn('atlas = ExtResource("1_sheet")', content)
        self.assertIn('"name": &"idle"', content)
        self.assertIn('"speed": 12.0', content)

    def test_vlm_auditor_offline_fallback(self):
        # Test that auditor handles unreachable endpoints safely without crashing
        res = vlm_sprite_auditor.audit_sprite(
            image_path=os.path.join(self.sprites_dir, "test_cossack_sheet.png"),
            character_name="test_cossack",
            ollama_url="http://127.0.0.1:59999/api/generate",  # Non-existent port
        )
        self.assertTrue(res.get("approved"))
        self.assertTrue(res.get("offline_fallback"))
        self.assertIn("outline", res.get("scores", {}))


if __name__ == "__main__":
    unittest.main()
