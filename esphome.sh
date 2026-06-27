#!/bin/bash
# Pinned ESPHome Docker wrapper. Mounts the repo root as /config and forwards
# all args to the esphome CLI inside the container.
set -euo pipefail
docker run --rm -v "${PWD}":/config -i ghcr.io/esphome/esphome:2026.5.0 "$@"
