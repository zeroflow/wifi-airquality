# ID-REGISTER.md — ESPHome Shared ID Ownership

This register maps every shared ESPHome `id` to exactly one owning package file (or a
declared variant-sibling pair — see Variant-Suffix Convention below).
No `id` may be declared in more than one package file (enforced by `test-examples.sh`),
unless the files are recognized variant siblings differing only by a `-i2c` / `-neopixel` suffix.
Consumers reference ids across packages using `!extend <id>`.

**Owning package** = the package file that declares the `id:` in its YAML.
**Consumers** = packages or example configs that reference (but do not declare) the id.

The no-duplicate-id contract is enforced automatically by the duplicate-`id` check in
`test-examples.sh`. Any id declared in more than one package file causes the check to
fail before `esphome config` runs (with the variant-sibling exemption; see below).

---

## From `sensor.yaml` (hardware + sensor + display ids)

| id | type | owning package file | consumers | notes |
|----|------|---------------------|-----------|-------|
| `bus_a` | i2c | `packages/hardware/grove-expansion-base.yaml` | sen55, sht41, oled, rtc_time | SDA=D4, SCL=D5 |
| `oled` | display (ssd1306_i2c 0x3C) | `packages/hardware/grove-expansion-base.yaml` | oled-airquality.yaml | `!extend` target for display lambda |
| `roboto` | font (Roboto, size 14) | `packages/hardware/grove-expansion-base.yaml` | oled-airquality.yaml | referenced in display lambda |
| `rtc_time` | time (pcf8563 0x51) | `packages/hardware/grove-expansion-base.yaml` | — | write-back target for sntp_time |
| `sntp_time` | time (sntp) | `packages/hardware/grove-expansion-base.yaml` | — | writes to rtc_time on_time_sync |
| `user_button` | binary_sensor (gpio D1, pullup, inverted) | `packages/hardware/grove-expansion-base.yaml` | — | triggers fan autoclean + buzzer |
| `buzzer_out` | output (ledc D3) | `packages/hardware/grove-expansion-base.yaml` | buzzer | ledc PWM output |
| `buzzer` | rtttl | `packages/hardware/grove-expansion-base.yaml` | — | driven by buzzer_out |
| `sen55` | sensor (sen5x) | `packages/sensors/sen55.yaml` | user_button (autoclean) | SEN55 parent sensor |
| `sen_pm25` | sensor sub-id (pm_2_5) | `packages/sensors/sen55.yaml` | oled-airquality.yaml | child of sen55 |
| `sen_pm10` | sensor sub-id (pm_10_0) | `packages/sensors/sen55.yaml` | oled-airquality.yaml | child of sen55 |
| `sen_voc` | sensor sub-id (voc) | `packages/sensors/sen55.yaml` | oled-airquality.yaml | child of sen55 |
| `sen_nox` | sensor sub-id (nox) | `packages/sensors/sen55.yaml` | oled-airquality.yaml | child of sen55 |
| `sht_temp` | sensor (sht4x temperature) | `packages/sensors/sht41.yaml` | oled-airquality.yaml | |
| `sht_hum` | sensor (sht4x humidity) | `packages/sensors/sht41.yaml` | oled-airquality.yaml | |

## From `ledbar.yaml` (AQI gauge + light ids)

| id | type | owning package file | consumers | notes |
|----|------|---------------------|-----------|-------|
| `aqi_strip` | light (esp32_rmt_led_strip A0/${pin_a0}) | `grove-led-driver-i2c.yaml` / `grove-led-driver-neopixel.yaml` | ledbar-gauge.yaml | variant-pair; shared by design, never composed together — see Variant-Suffix Convention |
| `grove_strip` | light (esp32_rmt_led_strip D5/${pin_d5}) | `packages/hardware/grove-led-driver-neopixel.yaml` | — | neopixel variant only; Grove I2C connector repurposed as second strip data output |
| `driver_button` | binary_sensor (gpio ${pin_d3} INPUT_PULLUP inverted) | `grove-led-driver-i2c.yaml` / `grove-led-driver-neopixel.yaml` | — | variant-pair; D3 reuse across boards is acceptable (different physical hardware from user_button/buzzer_out) |
| `air_quality` | sensor (homeassistant entity) | `packages/aqi/ledbar-gauge.yaml` | addressable_lambda | HA entity: sensor.air_quality_score |
| `threshold_green` | number (template) | `packages/aqi/ledbar-gauge.yaml` | addressable_lambda | AQI gauge lower threshold |
| `threshold_warn` | number (template) | `packages/aqi/ledbar-gauge.yaml` | addressable_lambda | AQI gauge warning threshold |
| `threshold_critical` | number (template) | `packages/aqi/ledbar-gauge.yaml` | addressable_lambda | AQI gauge critical threshold |
| `brightness` | number (template, %) | `packages/aqi/ledbar-gauge.yaml` | addressable_lambda | overall brightness cap; initial 10% |
| `breath` | number (template, %) | `packages/aqi/ledbar-gauge.yaml` | addressable_lambda | breath depth for warning state; initial 80% |

---

## Variant-Suffix Convention

Package files that differ **only** by a trailing variant suffix (`-i2c` or `-neopixel`)
before the `.yaml` extension are **sibling packages**. A consumer imports exactly one of them;
the two variants are mutually exclusive and must never be composed together.

Examples:
- `packages/hardware/grove-led-driver-i2c.yaml` — terminal strip + button; Grove I2C connector left free
- `packages/hardware/grove-led-driver-neopixel.yaml` — terminal strip + Grove strip + button; Grove connector repurposed

Sibling packages intentionally share ids (`aqi_strip`, `driver_button`). This is valid by design
and is NOT a duplicate-id violation. `test-examples.sh` Guard 2 strips the `-i2c` / `-neopixel`
variant suffix before deduplication, so both siblings map to the same canonical stem
(`grove-led-driver`) and are counted once — not flagged.

A genuine id collision in **unrelated** package files (files with different non-variant-suffixed
basenames) still maps to two distinct canonical stems and is correctly reported by Guard 2.

---

## Cross-Check Notes

All ids were verified against the frozen MVP YAMLs (`sensor.yaml` and `ledbar.yaml`) at initial
seeding (2026-06-07) and updated for the LED Driver Board variant refactor (2026-06-27).

Sub-ids (`sen_pm25`, `sen_pm10`, `sen_voc`, `sen_nox`) carry their own `id:` declarations
within the `sen5x` platform block in `sensor.yaml`, making them independently referenceable
via `!extend`.

`driver_button` (D3, LED Driver Board) is distinct from `user_button` (D1, Expansion Base) and
`buzzer_out` (D3 LEDC, Expansion Base). The D3 reuse across different physical boards is
intentional; consumers never compose the Expansion Base and the LED Driver Board together.

---

## Enforcement

The duplicate-id check in `test-examples.sh` scans all `packages/**/*.yaml` files at
validation time. If any `id:` value appears in more than one package file (after variant-sibling
normalization), the script exits non-zero before running `esphome config`. The register is the
written contract; the script is its automated enforcement.

---

*Seeded: 2026-06-07 from sensor.yaml (15 ids) and ledbar.yaml (7 ids)*
*Last updated: 2026-06-27 — Quick task 260627-qc8: LED Driver Board variant refactor (D1–D6)*
