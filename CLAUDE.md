<!-- GSD:project-start source:PROJECT.md -->
## Project

**wifi-airquality — Composable ESPHome Packages**

A reusable ESPHome **package library** for Seeed XIAO + Grove air-quality hardware,
sponsored by Seeed Studio. The existing MVP (`sensor.yaml` + `ledbar.yaml`) gets
refactored into composable, `github://`-importable packages so anyone can build the
same air-quality monitor — or their own XIAO/Grove device — by importing a few
building blocks instead of copy-pasting a monolithic YAML. The hardware glue (Grove
shield I2C/SPI buses, onboard OLED/RTC/buzzer/button) is configured by the packages
so a consumer only declares what they actually want.

**Core Value:** Someone else can stand up a working device by importing this repo's packages with the
ESPHome `packages:` (`github://`) syntax — without understanding the Grove/XIAO wiring
details. Composability is the product.

### Constraints

- **Tech stack**: ESPHome YAML, esp-idf framework — no change to the runtime; this is a packaging/refactor effort.
- **Compatibility**: Packages must work when pulled remotely via `github://`; `!secret` and per-user values stay in the consumer's top-level config.
- **Hardware fidelity**: Pin maps and I2C addresses must match the real Seeed XIAO Expansion Base and Grove modules (D4/D5 I2C, D8/D9/D10 SPI, OLED 0x3C, RTC 0x51, buzzer D3, button D1, LED GPIO07).
- **Backward compat**: Existing MVP YAMLs and enclosures remain valid and untouched.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Technologies
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| ESPHome | 2026.5.0 (stable) | Runtime + YAML compiler | Current stable; substitution engine redesigned in 2026.5 (up to 18x faster config load with packages); use stable, not dev/beta, for production packages |
| esp-idf framework | as bundled with ESPHome | Firmware runtime for ESP32-C3/C6 | Already in use; required for XIAO boards; `type: esp-idf` in `esp32:` block |
| GitHub public repo | — | Package distribution host | `github://` protocol is built into ESPHome; zero infrastructure required; consumers import directly |
| Git tags | semver (e.g., `v1.0.0`) | Version pinning for consumers | Tags are immutable; lets consumers pin to `@v1.0.0` and upgrade intentionally |
### Packaging Layer
| Mechanism | Purpose | When to Use |
|-----------|---------|-------------|
| `packages: github://user/repo/path/file.yaml@ref` | Remote import — primary distribution primitive | Every package a consumer uses |
| `packages: !include path/file.yaml` | Local import — nested packages within the repo itself | Hardware package referencing a sub-module |
| `substitutions:` in package file | Expose overridable values with defaults | Every knob a consumer might need to change |
| `!extend component_id` | Consumer overrides a named entity inside a package | Changing `update_interval`, display lambda, effect list without forking |
| `!remove component_id` | Consumer drops an entity from a package | Removing unwanted sensors/entities |
### Development Tools
| Tool | Purpose | Notes |
|------|---------|-------|
| `esphome config <file>` | Fast YAML validation without compilation | Catches all config errors; runs in seconds; primary CI check |
| `esphome compile <file>` | Full C++ compilation | Catches lambda/code errors; slow (~minutes); run for release tags |
| `esphome/build-action@v7` | Official GitHub Action — compiles and produces flash-ready firmware | Use in CI matrix against `stable`, `beta`, `dev` ESPHome versions |
| Docker / `esphome.sh` wrapper | Hermetic local compile | Local reference: `wifi-fancontroller/compile.sh` and `esphome.sh` |
## Exact Syntax Reference
### 1. Remote `github://` Import (Consumer Side)
### 2. Substitutions — How Packages Expose Overridable Values
# packages/grove/sen55.yaml
# Consumer's device.yaml
### 3. Substitution Priority Order
### 4. `!extend` — Override a Package Entity Without Forking
# Consumer device.yaml — change the OLED update rate and display lambda
### 5. `!remove` — Drop a Package Entity Entirely
### 6. Version Pinning Strategy
| Ref type | Syntax | Behavior | Use for |
|----------|--------|----------|---------|
| Tag (immutable) | `@v1.0.0` | Always resolves to that commit | Production consumer configs |
| Branch (mutable) | `@main` | Follows HEAD; cached per `refresh:` | Package development, examples |
| Commit SHA | `@a1b2c3d` | Pinned to exact commit | Maximum stability / auditing |
- Default: `1d`
- During development: set `refresh: 0s` to always fetch fresh, or `refresh: never` in CI after pinning.
- For consumers on a tag: set `refresh: never` — the tag won't change.
## Repo Layout Convention
- Hardware packages: describe the physical board, not the application — `xiao-esp32c6.yaml`, not `sensor-board.yaml`
- Feature packages: describe the Grove module — `sen55.yaml`, `sht41.yaml`, `expansion-base.yaml`
- Examples: describe what the device does — `air-quality-sensor.yaml`
- Package IDs (`id:` inside packages): use snake_case stable names — `bus_a`, `oled`, `rtc_time`, `sen55` — so `!extend` targets are predictable
## CI Tooling
### Fast validation (PR gate — seconds)
# .github/workflows/ci.yml
### Full compilation (release gate — minutes)
### Local test script (mirrors `wifi-fancontroller/test-examples.sh`)
#!/bin/bash
# test-examples.sh — run esphome config on all examples
## Secrets and Per-User WiFi
- Packages declare NO networking config (no `wifi:`, no `api:`, no `ota:`)
- Networking stays entirely in the consumer's top-level config with `!secret`
- `examples/secrets.yaml` contains dummy values — just enough to make `esphome config` pass
- Never commit real credentials; `.gitignore` the real `secrets.yaml`
# examples/secrets.yaml (committed, dummy values)
# examples/air-quality-sensor.yaml (consumer pattern)
# Networking is consumer-only — never in packages
## Alternatives Considered
| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `github://` public repo packages | `external_components:` | `external_components:` is for C++ custom components, not YAML config reuse; wrong tool |
| `substitutions:` with defaults in package | `defaults:` block | `defaults:` is older, less understood; community advice is to avoid it; `substitutions:` works identically and is more familiar |
| Git tags for consumer version pinning | Branch (`@main`) | Branches move; tag consumers would silently get breaking changes on next `refresh:`. Tags are immutable. |
| `esphome config` for CI validation | `esphome compile` for CI | Compilation takes minutes per config and requires cross-compilation toolchains; `config` catches all YAML/logic errors in seconds |
| Packages with stable `id:`s + `!extend` | Substitutions for everything | Substitutions bloat the package surface area; `!extend` lets consumers override internals without the package author predicting every knob |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `!secret` inside packages | Blocked by ESPHome for remote packages; will error | `substitutions:` with a sensible default, or leave to consumer's top-level config |
| Networking (`wifi:`, `api:`, `ota:`) in packages | Credentials and addresses are per-user; cannot travel over `github://` | Consumer declares all networking in their own config |
| `@main` pinning for stable consumer configs | `main` changes; package updates may silently break consumer builds | Use git tags (`@v1.0.0`) for any config intended for production |
| `defaults:` block | Older pattern; community tutorial recommends abandoning it; behavior when combined with nested packages is less predictable | `substitutions:` block in the package file |
| Nested substitution-in-substitution | Known regression in 2026.4.x (open bug as of 2026-06-06; partially addressed in 2026.5 substitution engine rewrite, status unclear) | Keep substitution values flat; do not reference `${other_var}` inside a substitution value |
| All-in-one monolithic package | Defeats composability; forces consumers to take everything | Split into hardware layer (board + buses) and feature layer (sensors, displays) |
## Version Compatibility Notes
| Component | Compatible ESPHome | Notes |
|-----------|-------------------|-------|
| `packages: github://` | All versions (stable feature) | Core stable feature; no known version restrictions |
| `!extend` / `!remove` | Added ~2023; fully stable in 2024+ | Do not test against ESPHome < 2023.x |
| `esphome/build-action` | Use `@v7` (current) | `@v6` also works but `@v7` is the recommended version as of 2026 |
| `esp32: framework: type: esp-idf` | Requires ESPHome 2022.1+ | Already in use in both MVP YAMLs |
| XIAO ESP32-C6 board (`seeed_xiao_esp32c6`) | Requires ESP-IDF framework; may need recent ESPHome | C6 support is newer; test against `stable` and `beta` in CI matrix |
## Sources
- **ESPHome Packages docs** (official, HIGH confidence) — https://esphome.io/components/packages/
- **ESPHome Substitutions docs** (official, HIGH confidence) — https://esphome.io/components/substitutions/
- **Context7 `/esphome/esphome-docs`** (HIGH confidence) — query: packages substitutions extend remove
- **Local reference: `wifi-fancontroller/`** (HIGH confidence, same author/ecosystem)
- **Local reference: `fancontroller/AIR-1/.github/workflows/ci.yml`** (HIGH confidence)
- **konnected-io/konnected-esphome** (MEDIUM confidence) — https://github.com/konnected-io/konnected-esphome
- **ESPHome packages tutorial** (MEDIUM confidence) — https://olegtarasov.me/esphome-packages-substitutions-tutorial/
- **ESPHome 2026.4.0 regression issue** (MEDIUM confidence) — https://github.com/esphome/esphome/issues/16475
- **ESPHome 2026.5.0 changelog** (MEDIUM confidence) — https://esphome.io/changelog/2026.5.0/
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
