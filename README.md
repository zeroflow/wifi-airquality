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
