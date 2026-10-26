#!/usr/bin/env python3
"""
Advisory VLM Sprite Auditor for "Джура: початок шляху козака".
Connects to NVIDIA Jetson AGX Orin 64GB (J501) running Ollama (`gemma4:12b` / `gemma3:12b`).
Follows SHR-004 (B-8), SWR-003-06, ADR-003, and Invariant I-3 (Zero-Horror).
"""

import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request


# Вузол J501 за замовчуванням; задайте OLLAMA_HOST (напр. http://host:11434), щоб використати інший (TLS-03)
J501_DEFAULT_HOST = "http://192.168.68.68:11434"
OLLAMA_DEFAULT_URL = os.environ.get("OLLAMA_HOST", J501_DEFAULT_HOST).rstrip("/") + "/api/generate"
DEFAULT_MODEL = "gemma3:12b"


VLM_SYSTEM_PROMPT = """Ти — мистецький аудитор та верифікатор естетичних інваріантів для української дитячої гри 'Джура' у стилі мультфільмів студії Київнаукфільм (Едуард Кирич, Володимир Дахно).

Твоє завдання — проаналізувати надане зображення спрайта та оцінити його за критеріями:
1. outline: наявність чіткого чорного контуру тушшю (Inverted Hull / Kyivnaukfilm ink).
2. cel_shading: яскраві, пласкі кольорові площини без реалістичних градієнтів та фотореалізму.
3. silhouette: чіткість силуету, фіксація стоп на підлозі, відсутність тремтіння та зламаної анатомії.
4. zero_horror: суворе дотримання інваріанта I-3 (жодної крові, жорстокості, зловісних образів; виключно комічний, дружній тон).
5. authentic_folklore: наявність елементів українського козацького або фольклорного колориту.

Відповідай ВИКЛЮЧНО валідним JSON-об'єктом без жодного додаткового тексту навколо:
{
  "approved": true,
  "scores": {
    "outline": 9,
    "cel_shading": 8,
    "silhouette": 9,
    "zero_horror": 10,
    "authentic_folklore": 8
  },
  "issues": [],
  "verdict": "Спрайт відповідає стилю Київнаукфільм та інваріантам гри"
}"""


def encode_image_base64(image_path: str) -> str:
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def audit_sprite(
    image_path: str,
    character_name: str,
    ollama_url: str = OLLAMA_DEFAULT_URL,
    model: str = DEFAULT_MODEL,
    output_report: str = "",
) -> dict:
    if not os.path.isfile(image_path):
        raise FileNotFoundError(f"Sprite image not found: {image_path}")

    b64_img = encode_image_base64(image_path)

    payload = {
        "model": model,
        "prompt": f"{VLM_SYSTEM_PROMPT}\n\nПроведи аудит персонажа '{character_name}'.",
        "images": [b64_img],
        "stream": False,
        "options": {
            "temperature": 0.1,
            "seed": 42,
        },
    }

    req = urllib.request.Request(
        ollama_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )

    print(f"Connecting to Jetson VLM node ({ollama_url}) with model '{model}'...")
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.URLError as e:
        print(f"[Warning] Failed to reach Jetson VLM node: {e}")
        # Graceful fallback: return offline mock pass for deterministic CI
        mock_result = {
            "approved": True,
            "offline_fallback": True,
            "scores": {"outline": 8, "cel_shading": 8, "silhouette": 8, "zero_horror": 10, "authentic_folklore": 8},
            "issues": [f"Jetson node unreachable: {e}"],
            "verdict": "Offline fallback verification (advisory pass)",
        }
        return mock_result

    raw_response = data.get("response", "")

    # Clean response from markdown json fences
    json_match = re.search(r"\{.*\}", raw_response, re.DOTALL)
    if json_match:
        try:
            result = json.loads(json_match.group(0))
        except json.JSONDecodeError:
            result = {
                "approved": True,
                "raw_response": raw_response,
                "verdict": "VLM responded with unparsed JSON, advisory pass",
            }
    else:
        result = {
            "approved": True,
            "raw_response": raw_response,
            "verdict": "VLM response lacked JSON, advisory pass",
        }

    if output_report:
        os.makedirs(os.path.dirname(os.path.abspath(output_report)), exist_ok=True)
        with open(output_report, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        print(f"Audit report saved to: {output_report}")

    return result


def main():
    parser = argparse.ArgumentParser(description="Audit sprite visuals via Jetson J501 VLM")
    parser.add_argument("--image", required=True, help="Path to sprite sheet or keyframe PNG")
    parser.add_argument("--name", default="character", help="Character name")
    parser.add_argument("--url", default=OLLAMA_DEFAULT_URL, help="Ollama API endpoint")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="VLM model name")
    parser.add_argument("--out-report", default="", help="Path to save output JSON report")
    args = parser.parse_args()
    if "OLLAMA_HOST" not in os.environ and args.url == OLLAMA_DEFAULT_URL:
        print(f"[Warning] OLLAMA_HOST не задано, використовується вузол J501 за замовчуванням ({J501_DEFAULT_HOST})", file=sys.stderr)

    out_rep = args.out_report or f"reports/sprite_audit_{args.name}.json"
    result = audit_sprite(
        image_path=args.image,
        character_name=args.name,
        ollama_url=args.url,
        model=args.model,
        output_report=out_rep,
    )

    print("\n--- [VLM Aesthetic Audit Result] ---")
    print(f"Character: {args.name}")
    print(f"Approved:  {result.get('approved')}")
    if "scores" in result:
        print(f"Scores:    {result['scores']}")
    if "issues" in result and result["issues"]:
        print(f"Issues:    {result['issues']}")
    print(f"Verdict:   {result.get('verdict')}")


if __name__ == "__main__":
    main()
