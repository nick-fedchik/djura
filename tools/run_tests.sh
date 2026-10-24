#!/usr/bin/env bash
# SWR-001-01: усі перевірки правил гри однією командою; код повернення 0 лише якщо всі пройшли.
# Запуск: tools/run_tests.sh   (потрібен godot у PATH; перевірки запускаються у headless-режимі)
set -u
cd "$(dirname "$0")/.."
godot_bin="${GODOT:-godot}"
failed=()
for t in test/test_*.gd; do
	name="$(basename "$t" .gd)"
	out="$(timeout "${TEST_TIMEOUT:-120}" "$godot_bin" --headless --path . -s "res://$t" 2>&1)"
	code=$?
	# Успіх: код 0, є маркер успіху, немає помилок скрипта чи провалених перевірок
	if [ $code -eq 0 ] && grep -qE "PASSED|\[OK\]" <<<"$out" && ! grep -qE "SCRIPT ERROR|\[FAIL\]|Assertion failed|ASSERT" <<<"$out"; then
		echo "PASS  $name"
	else
		echo "FAIL  $name (код $code)"
		grep -E "SCRIPT ERROR|\[FAIL\]|Assertion failed|ASSERT|недосяжн" <<<"$out" | head -8 | sed 's/^/        /'
		failed+=("$name")
	fi
done
if [ ${#failed[@]} -gt 0 ]; then
	echo "Провалено: ${failed[*]}"
	exit 1
fi
echo "Усі перевірки пройшли"
