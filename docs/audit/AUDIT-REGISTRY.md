# AUDIT CODE REGISTRY

Реєстр кодів аудитів і діапазонів ID дефектів (формат як у `~/vida/docs/audit/AUDIT-REGISTRY.md`). Протоколи лишаються незмінними (append-only); зміна статусу дефекту фіксується в колонці «Статус» нижче.

| Код | Підсистема | Діапазон | Серйозні (CRITICAL/HIGH) | Протокол |
|---|---|---|---|---|
| `ORG` | Весь проєкт | `ORG-01..ORG-08` | 2 | [AUDIT-2026-10-26-ORG-PROJECT-ORGANIZATION.md](AUDIT-2026-10-26-ORG-PROJECT-ORGANIZATION.md) |
| `BLD` | `assets/`, `export_presets.cfg`, `build/` | `BLD-01..BLD-06` | 3 | [AUDIT-2026-10-26-BLD-ASSETS-EXPORT-AND-BUILD.md](AUDIT-2026-10-26-BLD-ASSETS-EXPORT-AND-BUILD.md) |
| `COD` | `scripts/`, `scenes/` | `COD-01..COD-07` | 2 | [AUDIT-2026-10-26-COD-GAMEPLAY-SCRIPTS-ARCHITECTURE.md](AUDIT-2026-10-26-COD-GAMEPLAY-SCRIPTS-ARCHITECTURE.md) |
| `ADP` | `difficulty.gd`, `player_model.gd`, `telemetry*.gd` | `ADP-01..ADP-06` | 2 | [AUDIT-2026-10-26-ADP-ADAPTIVE-DIFFICULTY-AND-TELEMETRY.md](AUDIT-2026-10-26-ADP-ADAPTIVE-DIFFICULTY-AND-TELEMETRY.md) |
| `TST` | `test/`, `tools/run_tests.sh` | `TST-01..TST-07` | 1 | [AUDIT-2026-10-26-TST-TESTS-AND-VERIFICATION.md](AUDIT-2026-10-26-TST-TESTS-AND-VERIFICATION.md) |
| `TLS` | `tools/`, кореневі `*.py` | `TLS-01..TLS-08` | 2 | [AUDIT-2026-10-26-TLS-TOOLS-AND-PIPELINES.md](AUDIT-2026-10-26-TLS-TOOLS-AND-PIPELINES.md) |
| `DOC` | `README.md`, `CONTRIBUTING.md`, `INSTALL.md`, `docs/` | `DOC-01..DOC-06` | 1 | [AUDIT-2026-10-26-DOC-DOCUMENTATION-CONFORMANCE.md](AUDIT-2026-10-26-DOC-DOCUMENTATION-CONFORMANCE.md) |

Статус дефектів станом на 2026-10-26: усі `open`, крім виправлених у `TST` (TST-01…04, 07), `TLS` (TLS-01, 02, 04…07; TLS-03 частково) та `ORG-03`; див. «Журнал виправлень» у відповідних протоколах. Виправлення ще не закомічені.

Оновлення: ADP-01, 04, 06 виправлено; ADP-02 прийнято власником (телеметрія ввімкнена на ранньому етапі); ADP-03 open.
Оновлення (2026-10-26): BLD (BLD-01, 03, 04, 05, 06) виправлено; COD (COD-02, 04, 05, 06) виправлено; DOC (DOC-01..DOC-06) повністю виправлено.
