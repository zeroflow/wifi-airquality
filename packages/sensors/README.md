# packages/sensors/

Sensor packages for Grove air-quality modules. Each package wires a sensor to
the `bus_a` I2C bus (owned by `grove-expansion-base.yaml`) and exposes stable
`id`s for display and automation packages.

---

## `sen55.yaml`

**What it configures:** Sensirion SEN55 particulate + gas sensor — PM1.0, PM2.5, PM4.0,
PM10, VOC index, NOx index, temperature, and humidity over I2C.

**Hardware / package dependencies:**
- `grove-expansion-base.yaml` — provides `bus_a` (I2C bus at D4/D5)

**Exposed ids:**

| id | type | notes |
|----|------|-------|
| `sen55` | sensor (sen5x) | SEN55 parent sensor; used for autoclean trigger |
| `sen_pm25` | sensor sub-id (pm\_2\_5) | PM2.5 weight concentration; consumed by `oled-airquality.yaml` |
| `sen_pm10` | sensor sub-id (pm\_10\_0) | PM10 weight concentration; consumed by `oled-airquality.yaml` |
| `sen_voc` | sensor sub-id (voc) | VOC index; consumed by `oled-airquality.yaml` |
| `sen_nox` | sensor sub-id (nox) | NOx index; consumed by `oled-airquality.yaml` |

**Substitutions:**

| name | default | purpose |
|------|---------|---------|
| `sen55_update_interval` | `"60s"` | How often the sensor reads; reduce for faster dashboard updates |

**Example override with `!extend`:**

```yaml
# Speed up SEN55 readings for a responsive dashboard
sensor:
  - id: !extend sen55
    update_interval: 10s
```

**Import:**

```yaml
packages:
  sensors_sen: github://zeroflow/wifi-airquality/packages/sensors/sen55.yaml@v1.0.0
  # local development:
  # sensors_sen: !include packages/sensors/sen55.yaml
```

---

## `sht41.yaml`

**What it configures:** Sensirion SHT41 temperature and humidity sensor over I2C.

**Hardware / package dependencies:**
- `grove-expansion-base.yaml` — provides `bus_a` (I2C bus at D4/D5)

**Exposed ids:**

| id | type | notes |
|----|------|-------|
| `sht_temp` | sensor (sht4x temperature) | Temperature reading; consumed by `oled-airquality.yaml` |
| `sht_hum` | sensor (sht4x humidity) | Humidity reading; consumed by `oled-airquality.yaml` |

**Substitutions:**

| name | default | purpose |
|------|---------|---------|
| `sht41_update_interval` | `"60s"` | How often the sensor reads; reduce for faster dashboard updates |

**Example override with `!extend`:**

```yaml
# Speed up SHT41 readings to 10s without forking the package
sensor:
  - id: !extend sht_temp
    update_interval: 10s
```

**Import:**

```yaml
packages:
  sensors_sht: github://zeroflow/wifi-airquality/packages/sensors/sht41.yaml@v1.0.0
  # local development:
  # sensors_sht: !include packages/sensors/sht41.yaml
```
