# packages/display/

Display packages that render sensor data onto the OLED screen. Each package
`!extend`s the hardware-owned `oled` display entity declared by
`grove-expansion-base.yaml`.

---

## `oled-airquality.yaml`

**What it configures:** Air-quality display lambda — overrides the default clock display
on the OLED with a 4-row air-quality dashboard (temperature/humidity, PM2.5/PM10,
VOC/NOx, VOC bar graph).

**Hardware / package dependencies:**
- `grove-expansion-base.yaml` — provides `oled` (display entity) and `roboto` (font)
- `sen55.yaml` — provides `sen_pm25`, `sen_pm10`, `sen_voc`, `sen_nox`
- `sht41.yaml` — provides `sht_temp`, `sht_hum`

> **Note:** This package validates only in composition (e.g. `examples/sensor-station.yaml`).
> Do not add it to `examples/` for standalone validation — the cross-package ids above
> do not exist in isolation and `esphome config` will fail with unknown-id errors.

**Exposed ids:**

*(No new ids declared — this package only `!extend`s the hardware-owned `oled` entity)*

**Substitutions:**

*(No substitutions)*

**Example override with `!extend`:**

```yaml
# Replace the air-quality dashboard with a custom one-line display
display:
  - id: !extend oled
    lambda: |-
      it.printf(0, 0, id(roboto), "VOC: %.0f", id(sen_voc).state);
```

**Import:**

```yaml
packages:
  oled_display: github://zeroflow/wifi-airquality/packages/display/oled-airquality.yaml@v1.0.0
  # local development:
  # oled_display: !include packages/display/oled-airquality.yaml
```
