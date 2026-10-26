#!/usr/bin/env bash
# SWR-001-01: усі перевірки правил гри однією командою; код повернення 0 лише якщо всі пройшли.
# Запуск: tools/run_tests.sh   (потрібен godot у PATH; перевірки запускаються у headless-режимі)
set -u
cd "$(dirname "$0")/.."
godot_bin="${GODOT:-godot}"
failed=()

# Рядки, що означають збій навіть при коді 0 (TST-01). Діагностика завершення рушія (витоки при виході)
# не входить: це шум headless-режиму, а не помилка перевірки.
fail_re='SCRIPT ERROR|Parse Error|\[FAIL\]|Assertion failed|ASSERT|^ERROR:|Failed (to )?load'
shutdown_re='ObjectDB instances were leaked|resources still in use at exit'

min_markers() { # мінімум маркерів успіху для тесту з test/expected_markers.txt (за замовчуванням 1)
	awk -v n="$1" '$1==n {print $2; found=1} END {if (!found) print 1}' test/expected_markers.txt 2>/dev/null
}

for t in test/test_*.gd; do
	name="$(basename "$t" .gd)"
	out="$(timeout "${TEST_TIMEOUT:-120}" "$godot_bin" --headless --path . -s "res://$t" 2>&1)"
	code=$?
	errs="$(grep -E "$fail_re" <<<"$out" | grep -vE "$shutdown_re")"
	markers="$(grep -cE "PASSED|\[OK\]" <<<"$out")"
	need="$(min_markers "${name#test_}")"
	if [ $code -eq 0 ] && [ -z "$errs" ] && [ "$markers" -ge "$need" ]; then
		echo "PASS  $name"
	else
		echo "FAIL  $name (код $code, маркерів успіху $markers із $need)"
		grep -E "$fail_re|недосяжн" <<<"$out" | grep -vE "$shutdown_re" | head -8 | sed 's/^/        /'
		failed+=("$name")
	fi
done

# Python-тести: при падінні показуємо кінець виводу (TST-02)
for py in tools/test_tools.py tools/test_sprite_generator.py tools/test_hygiene.py; do
	command -v python3 >/dev/null 2>&1 && [ -f "$py" ] || continue
	name="$(basename "$py" .py)"
	if pyout="$(python3 "$py" 2>&1)"; then
		echo "PASS  $name (python)"
	else
		echo "FAIL  $name (python)"
		tail -8 <<<"$pyout" | sed 's/^/        /'
		failed+=("$name")
	fi
done

if [ ${#failed[@]} -gt 0 ]; then
	echo "Провалено: ${failed[*]}"
	exit 1
fi
echo "Усі перевірки пройшли"
