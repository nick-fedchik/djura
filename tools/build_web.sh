#!/usr/bin/env bash
set -e

# tools/build_web.sh — Швидка збірка HTML5/WebAssembly для Geek Jack

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

echo "=================================================="
echo " 🚀 Експорт Geek Jack у Web / HTML5 (Godot 4)"
echo "=================================================="

# Перевірка наявності godot
if ! command -v godot &> /dev/null; then
    echo "❌ Помилка: godot не знайдено в PATH."
    exit 1
fi

mkdir -p build/web

# Запуск експорту в релізному режимі
echo "📦 Компіляція та пакування ресурсів у build/web/index.html..."
godot --headless --path . --export-release "Web" build/web/index.html

echo "--------------------------------------------------"
echo "✅ Веб-збірку успішно створено!"
echo "   Файли:"
ls -lh build/web/
echo "--------------------------------------------------"
echo "👉 Щоб роздавати гру в локальній мережі для Xbox:"
echo "   ./tools/lan_server.py"
echo "=================================================="
