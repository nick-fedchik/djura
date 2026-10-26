import urllib.request
import re

url = "https://www.meshy.ai/3d-models/Djura-Character-Turnaround-01a1738f-543b-73ef-8b2d-5b52848aab85"
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
html = urllib.request.urlopen(req).read().decode("utf-8")

# Let's search for any occurrence of 'glb' or 'download' or 'task'
for m in re.finditer(r'\{[^{}]*01a1738f-543b-73ef-8b2d-5b52848aab85[^{}]*\}', html):
    print("Match:", m.group(0))

# Also search for api endpoint
print("--- Endpoints ---")
for line in html.split('\n'):
    if "api.meshy.ai" in line or "assets" in line:
        for u in re.findall(r'https?://[^\s"\'<>]+', line):
            if any(ext in u for ext in ['glb', 'gltf', 'obj', 'fbx', 'preview', 'download']):
                print("URL:", u)
