# wifi-airquality

Air-quality monitor with a visual air-quality indicator, built with
[ESPHome](https://esphome.io/) and [Home Assistant](https://www.home-assistant.io/).
Companion project to a fan controller: when the basement air gets dirty, the
lightbar shows it and the fans throttle down or switch off.

*Sponsored by [Seeed Studio](https://www.seeedstudio.com/).*

## Devices

| Config                         | MCU             | Hardware                                              |
| ------------------------------ | --------------- | ----------------------------------------------------- |
| [`sensor.yaml`](sensor.yaml)   | Seeed XIAO ESP32-C6 | Sensirion SEN55 (PM/VOC/NOx/T/RH) + SHT41, OLED, RTC, buzzer |
| [`ledbar.yaml`](ledbar.yaml)   | Seeed XIAO ESP32-C3 | 10-LED WS2812 lightbar as an AQI gauge            |

The **sensor** station measures particulate matter, VOC, NOx, temperature and
humidity and publishes them to Home Assistant. The **lightbar** subscribes to a
Home Assistant air-quality score and visualizes it (green = good, breathing red
= warning, blinking red = critical), with configurable thresholds and brightness.

## Package Library

This repository is an ESPHome **package library** — composable building blocks you import
directly into your own device config via `packages: github://`. No forking required.

All packages are tagged at `@v1.0.0`. Use this tag in production configs for stability.
See each layer's `README.md` for full documentation, exposed ids, and `!extend` examples.

### Hardware layer — [`packages/hardware/`](packages/hardware/)

| Package | One-liner | Import key |
|---------|-----------|------------|
| `xiao-esp32c3.yaml` | Seeed XIAO ESP32-C3 MCU + ESP-IDF framework | `mcu` |
| `xiao-esp32c6.yaml` | Seeed XIAO ESP32-C6 MCU + ESP-IDF framework | `mcu` |
| `grove-expansion-base.yaml` | XIAO Expansion Base — I2C, OLED, RTC, buzzer, button | `shield` |
| `grove-led-driver.yaml` | Grove LED Driver Board — 10-LED WS2812 strip on GPIO07 | `led_hw` |

### Sensors layer — [`packages/sensors/`](packages/sensors/)

| Package | One-liner | Import key |
|---------|-----------|------------|
| `sen55.yaml` | Sensirion SEN55 — PM1/2.5/4/10 + VOC + NOx + T/RH | `sensors_sen` |
| `sht41.yaml` | Sensirion SHT41 — temperature + humidity | `sensors_sht` |

### Display layer — [`packages/display/`](packages/display/)

| Package | One-liner | Import key |
|---------|-----------|------------|
| `oled-airquality.yaml` | Air-quality dashboard on the OLED (T/RH, PM, VOC/NOx, bar) | `oled_display` |

### AQI gauge layer — [`packages/aqi/`](packages/aqi/)

| Package | One-liner | Import key |
|---------|-----------|------------|
| `ledbar-gauge.yaml` | AQI Gauge effect on LED strip — 4-state visual from HA sensor | `aqi_gauge` |

---

### Copy-paste import snippets

**Sensor station** (XIAO C6 + Expansion Base + SEN55 + SHT41 + OLED):

```yaml
# Shorthand — no substitution overrides needed
packages:
  mcu:          github://zeroflow/wifi-airquality/packages/hardware/xiao-esp32c6.yaml@v1.0.0
  shield:       github://zeroflow/wifi-airquality/packages/hardware/grove-expansion-base.yaml@v1.0.0
  sensors_sen:  github://zeroflow/wifi-airquality/packages/sensors/sen55.yaml@v1.0.0
  sensors_sht:  github://zeroflow/wifi-airquality/packages/sensors/sht41.yaml@v1.0.0
  oled_display: github://zeroflow/wifi-airquality/packages/display/oled-airquality.yaml@v1.0.0
```

**LED bar gauge** (XIAO C3 + LED Driver + AQI Gauge):

```yaml
# Shorthand — uses default HA entity sensor.air_quality_score
packages:
  mcu:       github://zeroflow/wifi-airquality/packages/hardware/xiao-esp32c3.yaml@v1.0.0
  led_hw:    github://zeroflow/wifi-airquality/packages/hardware/grove-led-driver.yaml@v1.0.0
  aqi_gauge: github://zeroflow/wifi-airquality/packages/aqi/ledbar-gauge.yaml@v1.0.0
```

**LED bar gauge with custom HA entity** (long-form with `vars:`):

```yaml
# Long-form — override aqi_entity_id to match your Home Assistant entity name
packages:
  mcu:    github://zeroflow/wifi-airquality/packages/hardware/xiao-esp32c3.yaml@v1.0.0
  led_hw: github://zeroflow/wifi-airquality/packages/hardware/grove-led-driver.yaml@v1.0.0
  aqi_gauge:
    url: github://zeroflow/wifi-airquality/packages/aqi/ledbar-gauge.yaml@v1.0.0
    vars:
      aqi_entity_id: sensor.basement_air_quality
```

**Custom LED strip** (long-form overriding `led_count` and `led_pin`):

```yaml
packages:
  led_hw:
    url: github://zeroflow/wifi-airquality/packages/hardware/grove-led-driver.yaml@v1.0.0
    vars:
      led_count: "30"
      led_pin: GPIO04
```

**Custom SEN55 poll rate** (long-form overriding `sen55_update_interval`):

```yaml
packages:
  sensors_sen:
    url: github://zeroflow/wifi-airquality/packages/sensors/sen55.yaml@v1.0.0
    vars:
      sen55_update_interval: "10s"
```

---

## Enclosures

3D-printable mounts for both devices live in [`enclosure/`](enclosure/).

## Setup

Secrets are kept out of git. Create a `secrets.yaml` next to the configs:

```yaml
wifi_ssid: "your-ssid"
wifi_password: "your-password"
```

## Build

Validate and flash with ESPHome:

```bash
esphome config sensor.yaml
esphome run sensor.yaml
esphome run ledbar.yaml
```

## License

[MIT](LICENSE)
