# packages/hardware/

Hardware packages for the Seeed XIAO series and Grove peripherals. Each package
configures the MCU or a Grove board and exposes stable `id`s for composition.

---

## `xiao-esp32c3.yaml`

**What it configures:** Seeed XIAO ESP32-C3 MCU and ESP-IDF framework — nothing else.

**Hardware / package dependencies:**
- None (board-only package; no Grove peripherals)

**Exposed ids:**

*(No ids exposed — MCU and framework declaration only)*

**Substitutions:**

| name | value | purpose |
|------|-------|---------|
| `pin_a0` | `"2"` | A0 silkscreen → GPIO2 |
| `pin_d3` | `"5"` | D3 silkscreen → GPIO5 |
| `pin_d4` | `"6"` | D4 / SDA → GPIO6 |
| `pin_d5` | `"7"` | D5 / SCL → GPIO7 (== legacy MVP GPIO07) |

These substitutions are a **workaround** for missing XIAO C3 silkscreen aliases in ESPHome
2026.5.0 (pinned). ESPHome PR #17002 adds C3/S3 aliases but targets the unreleased 2026.6.0.
Feature packages (e.g. `grove-led-driver-i2c.yaml`) reference `${pin_a0}` / `${pin_d5}` /
`${pin_d3}` directly at point of use — no nested substitution-in-substitution indirection.

**Example override with `!extend`:**

The XIAO C3 package has no exposed ids, so `!extend` is not applicable.
Consumer adds device identity, networking, and peripherals in their own config.

**Import:**

```yaml
packages:
  mcu: github://zeroflow/wifi-airquality/packages/hardware/xiao-esp32c3.yaml@v1.0.0
  # local development:
  # mcu: !include packages/hardware/xiao-esp32c3.yaml
```

---

## `xiao-esp32c6.yaml`

**What it configures:** Seeed XIAO ESP32-C6 MCU and ESP-IDF framework — nothing else.

**Hardware / package dependencies:**
- None (board-only package; no Grove peripherals)

**Exposed ids:**

*(No ids exposed — MCU and framework declaration only)*

**Substitutions:**

| name | value | purpose |
|------|-------|---------|
| `pin_a0` | `"0"` | A0 silkscreen → GPIO0 |
| `pin_d3` | `"21"` | D3 silkscreen → GPIO21 |
| `pin_d4` | `"22"` | D4 / SDA → GPIO22 |
| `pin_d5` | `"23"` | D5 / SCL → GPIO23 |

See C3 note above — same workaround applies for the C6 pin-name substitutions.

**Example override with `!extend`:**

The XIAO C6 package has no exposed ids, so `!extend` is not applicable.
Consumer adds device identity, networking, and peripherals in their own config.

**Import:**

```yaml
packages:
  mcu: github://zeroflow/wifi-airquality/packages/hardware/xiao-esp32c6.yaml@v1.0.0
  # local development:
  # mcu: !include packages/hardware/xiao-esp32c6.yaml
```

---

## `grove-expansion-base.yaml`

**What it configures:** All onboard peripherals of the Seeed XIAO Expansion Base — I2C bus,
0.96" OLED (shows clock by default), PCF8563 RTC with SNTP write-back, passive buzzer,
and user button.

**Hardware / package dependencies:**
- Requires a XIAO board package (`xiao-esp32c3.yaml` or `xiao-esp32c6.yaml`) for the
  underlying MCU

**Exposed ids:**

| id | type | notes |
|----|------|-------|
| `bus_a` | i2c | SDA=D4, SCL=D5 (overridable via substitutions); consumed by sensor and display packages |
| `oled` | display (ssd1306\_i2c 0x3C) | 128×64 OLED; default lambda shows clock; `!extend` target for custom display content |
| `roboto` | font (Roboto, size 14) | Referenced in display lambdas |
| `rtc_time` | time (pcf8563 0x51) | Hardware RTC; SNTP writes back to it on sync |
| `sntp_time` | time (sntp) | SNTP source; writes to `rtc_time` on sync |
| `user_button` | binary\_sensor (gpio D1, pullup, inverted) | Bare GPIO — no automations in package |
| `buzzer_out` | output (ledc D3) | LEDC PWM output driving the buzzer |
| `buzzer` | rtttl | RTTTL player; play tones via `rtttl.play` |

**Substitutions:**

| name | default | purpose |
|------|---------|---------|
| `i2c_sda` | `D4` | I2C SDA pin |
| `i2c_scl` | `D5` | I2C SCL pin |

**Example override with `!extend`:**

```yaml
# Change the OLED content without forking the package
display:
  - id: !extend oled
    lambda: |-
      it.printf(0, 0, id(roboto), "PM2.5: %.0f", id(sen_pm25).state);
```

**Import:**

```yaml
packages:
  shield: github://zeroflow/wifi-airquality/packages/hardware/grove-expansion-base.yaml@v1.0.0
  # local development:
  # shield: !include packages/hardware/grove-expansion-base.yaml
```

---

## `grove-led-driver-i2c.yaml`

**What it configures:** Seeed LED Driver Board for XIAO — **I2C variant**.

- `aqi_strip` — WS2812 addressable LED strip on the terminal-block LED connector (A0 / `${pin_a0}`)
- `driver_button` — user button on D3 / `${pin_d3}` (INPUT_PULLUP, inverted, no automations)

The Grove I2C connector is **left free** for the consumer. Pair with `grove-expansion-base.yaml`
or add your own `i2c:` block to use I2C sensors/OLED on that connector.

Consumers add effects via `!extend aqi_strip`. See `packages/aqi/ledbar-gauge.yaml` for an
AQI gauge effect that extends this strip.

**Hardware / package dependencies:**
- Requires a XIAO board package (`xiao-esp32c3.yaml` or `xiao-esp32c6.yaml`) — the board
  package exports `pin_a0` and `pin_d3` consumed here

**Exposed ids:**

| id | type | notes |
|----|------|-------|
| `aqi_strip` | light (esp32\_rmt\_led\_strip) | 10 LEDs, WS2812, GRB order; `!extend` target for effect packages |
| `driver_button` | binary\_sensor (gpio INPUT\_PULLUP inverted) | Bare GPIO on D3 — no automations in package |

**Substitutions:**

| name | default | purpose |
|------|---------|---------|
| `led_count` | `"10"` | Number of LEDs in the strip |

Pins (`pin_a0`, `pin_d3`) are exported by the board package — override them at the board level,
not here. Do not nest `${pin_a0}` inside another substitution value.

**Pin map:**

| Silkscreen | C3 GPIO | C6 GPIO | Connected to |
|------------|---------|---------|-------------|
| A0 | GPIO2 | GPIO0 | Terminal-block LED strip data (`aqi_strip`) |
| D3 | GPIO5 | GPIO21 | User button (`driver_button`) |

Note: The GPIO numbers are provided by the board package substitutions as a workaround for
missing C3 silkscreen aliases in ESPHome 2026.5.0 (PR #17002 not yet released).

**Example override with `!extend`:**

```yaml
# Add a Rainbow effect to the strip without forking the package
light:
  - id: !extend aqi_strip
    effects:
      - random:
          name: "Twinkle"
          transition_length: 600ms
          update_interval: 300ms
```

**Import:**

```yaml
packages:
  mcu:    github://zeroflow/wifi-airquality/packages/hardware/xiao-esp32c3.yaml@v1.0.0
  led_hw: github://zeroflow/wifi-airquality/packages/hardware/grove-led-driver-i2c.yaml@v1.0.0
  # local development:
  # led_hw: !include packages/hardware/grove-led-driver-i2c.yaml
```

---

## `grove-led-driver-neopixel.yaml`

**What it configures:** Seeed LED Driver Board for XIAO — **Neopixel variant**.

- `aqi_strip` — WS2812 addressable LED strip on the terminal-block LED connector (A0 / `${pin_a0}`)
- `grove_strip` — second WS2812 strip on the Grove I2C connector repurposed as D5 / `${pin_d5}` data output
- `driver_button` — user button on D3 / `${pin_d3}` (INPUT_PULLUP, inverted, no automations)

The Grove I2C connector is **repurposed** as a neopixel data line in this variant.
The Grove connector is **NOT available for I2C** here. Use the I2C variant
(`grove-led-driver-i2c.yaml`) if you need I2C sensors/OLED on the Grove connector.

**Hardware / package dependencies:**
- Requires a XIAO board package (`xiao-esp32c3.yaml` or `xiao-esp32c6.yaml`) — the board
  package exports `pin_a0`, `pin_d3`, and `pin_d5` consumed here

**Exposed ids:**

| id | type | notes |
|----|------|-------|
| `aqi_strip` | light (esp32\_rmt\_led\_strip) | 10 LEDs, WS2812, GRB order; terminal-block strip on A0; `!extend` target for effect packages |
| `grove_strip` | light (esp32\_rmt\_led\_strip) | 10 LEDs, WS2812, GRB order; Grove-connector strip on D5 |
| `driver_button` | binary\_sensor (gpio INPUT\_PULLUP inverted) | Bare GPIO on D3 — no automations in package |

**Substitutions:**

| name | default | purpose |
|------|---------|---------|
| `led_count` | `"10"` | Number of LEDs per strip (applies to both `aqi_strip` and `grove_strip`) |

Pins (`pin_a0`, `pin_d3`, `pin_d5`) are exported by the board package — override them at the
board level. Do not nest `${pin_*}` inside another substitution value.

**Pin map:**

| Silkscreen | C3 GPIO | C6 GPIO | Connected to |
|------------|---------|---------|-------------|
| A0 | GPIO2 | GPIO0 | Terminal-block LED strip data (`aqi_strip`) |
| D5 | GPIO7 | GPIO23 | Grove-connector LED strip data (`grove_strip`); note D5/GPIO7 == legacy MVP GPIO07 |
| D3 | GPIO5 | GPIO21 | User button (`driver_button`) |

Note: The GPIO numbers are provided by the board package substitutions as a workaround for
missing C3 silkscreen aliases in ESPHome 2026.5.0 (PR #17002 not yet released).

**Variant sibling note:** `aqi_strip` and `driver_button` are intentionally shared with
`grove-led-driver-i2c.yaml`. These two packages are mutually exclusive — a consumer imports
exactly one. Guard 2 in `test-examples.sh` recognizes this as a valid sibling pair.

**Example override with `!extend`:**

```yaml
# Add a solid color effect to the Grove-connector strip
light:
  - id: !extend grove_strip
    effects:
      - random:
          name: "Twinkle"
          transition_length: 600ms
          update_interval: 300ms
```

**Import:**

```yaml
packages:
  mcu:    github://zeroflow/wifi-airquality/packages/hardware/xiao-esp32c3.yaml@v1.0.0
  led_hw: github://zeroflow/wifi-airquality/packages/hardware/grove-led-driver-neopixel.yaml@v1.0.0
  # local development:
  # led_hw: !include packages/hardware/grove-led-driver-neopixel.yaml
```
