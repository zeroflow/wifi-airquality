# packages/aqi/

AQI gauge packages that drive the LED strip as a visual air-quality indicator.
Each package `!extend`s the hardware-owned `aqi_strip` light entity declared
by `grove-led-driver.yaml`.

---

## `ledbar-gauge.yaml`

**What it configures:** AQI Gauge code package — adds the "AQI Gauge" `addressable_lambda`
effect to the `aqi_strip` light, subscribes to a Home Assistant air-quality score entity,
and exposes 5 HA-configurable number entities for thresholds and brightness.

The gauge has four visual states:

| Score range | State | Visual |
|---|---|---|
| < threshold\_green | Very good | 2 green LEDs at center |
| threshold\_green – threshold\_warn | Normal | Gauge expands center-out, green→yellow→red |
| threshold\_warn – threshold\_critical | Warning | All red, sine breathing |
| ≥ threshold\_critical | Critical | All red, hard 5 Hz blink |

Decorative effects (Rainbow, Scan, etc.) are intentionally **not included** in this
package. A consumer who wants them adds their own `!extend aqi_strip` with additional
effects (D-25).

**Hardware / package dependencies:**
- `grove-led-driver.yaml` — provides `aqi_strip` (the `!extend` target)
- Requires a XIAO board package for the underlying MCU

> **Note:** This package validates only in composition (e.g. `examples/ledbar.yaml`).
> Do not add it to `examples/` for standalone validation — `aqi_strip` is declared by
> `grove-led-driver.yaml` and does not exist in isolation.

**Exposed ids:**

| id | type | notes |
|----|------|-------|
| `air_quality` | sensor (homeassistant) | Subscribes to the HA entity set by `aqi_entity_id`; drives the gauge lambda |
| `threshold_green` | number (template) | Lower AQI threshold; initial 5 (range 1–30) |
| `threshold_warn` | number (template) | Warning AQI threshold; initial 85 (range 50–100) |
| `threshold_critical` | number (template) | Critical AQI threshold; initial 95 (range 80–100) |
| `brightness` | number (template, %) | Overall LED brightness cap; initial 10% |
| `breath` | number (template, %) | Breath depth for warning sine animation; initial 80% |

**Substitutions:**

| name | default | purpose |
|------|---------|---------|
| `aqi_entity_id` | `sensor.air_quality_score` | Which Home Assistant entity feeds the gauge; override to match your HA entity name |

**Example override with `!extend`:**

**Option A — Simple: change the HA entity via substitution** (most consumers):

```yaml
packages:
  aqi_gauge:
    url: github://zeroflow/wifi-airquality/packages/aqi/ledbar-gauge.yaml@v1.0.0
    vars:
      aqi_entity_id: sensor.basement_air_quality
```

**Option B — Power user: override the sensor entity with `!extend`** (D-27):

Use `!extend air_quality` when you need to change more than the `entity_id` —
for example, to add `filters:`, set a custom `name:`, or bind a different platform:

```yaml
sensor:
  - id: !extend air_quality
    entity_id: sensor.my_custom_aqi
    filters:
      - sliding_window_moving_average:
          window_size: 5
          send_every: 1
```

**Adding decorative effects** (D-25): The package ships only the AQI Gauge effect.
To add Rainbow, Scan, or other effects without forking, extend the strip:

```yaml
light:
  - id: !extend aqi_strip
    effects:
      - addressable_rainbow:
          name: "Rainbow"
          speed: 10
          width: 50
```

**Import:**

```yaml
packages:
  aqi_gauge: github://zeroflow/wifi-airquality/packages/aqi/ledbar-gauge.yaml@v1.0.0
  # local development:
  # aqi_gauge: !include packages/aqi/ledbar-gauge.yaml
```
