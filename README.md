# Kindle Planner Dashboard

Monochrome, Kindle-friendly planner dashboard with Telegram bot updates.

## Requirements

- A jailbroken Kindle with KUAL installed for the native dashboard.
- Node.js 20+ and npm for scripts, checks, and backend bootstrapping.
- An InsForge account for the database, edge functions, and secrets.
- A Telegram bot token from BotFather for chat-based planner updates.
- Optional: an OpenAI API key for natural-language message parsing. Without
  it, the webhook uses the built-in command parser.
- Optional: Zig or a Kindle-compatible ARM cross compiler to rebuild the KUAL
  package.
- Optional: Xcode and a real iPhone for the Health Sync companion app.

## For Other Kindle Owners

This repo can be published as a bring-your-own-backend kit. Each owner runs
their own InsForge project, Telegram bot, and KUAL package config instead of
connecting to this checkout's production backend.

Start with [docs/INSTALL_FOR_USERS.md](docs/INSTALL_FOR_USERS.md).

If you are using a coding assistant for setup, use
[docs/SETUP_WITH_ASSISTANT.md](docs/SETUP_WITH_ASSISTANT.md).

## Cloud Planner Flow

The production flow is:

1. Telegram bot receives a message from your allowed chat.
2. Telegram posts the update to the `telegram-webhook` InsForge function.
3. The webhook parses the message into a list action.
4. The function updates `planner_items`.
5. The Kindle native C++ app polls the read-only `kindle-dashboard-data` function, renders directly on e-ink, and keeps a cached offline copy.

## Project Structure

- `functions/`: InsForge edge functions for dashboard JSON, live events,
  item toggles, Telegram parsing/actions, version checks, and Health Sync
  uploads.
- `migrations/`: Postgres schema and optional sample-data migrations used by
  the bring-your-own-backend setup.
- `kindle/native/`: Native C++ e-ink dashboard renderer, local render check,
  and KUAL package build targets.
- `kindle/kual/kindle-dashboard/`: KUAL extension files, shell launchers,
  placeholder assets, and `config.sh.example`.
- `kindle/launch-dashboard.sh`: Kindle-side launcher used by installed
  shortcuts and native install helpers.
- `ios/HealthSyncCompanion/`: Optional iOS app that reads Apple Health daily
  aggregates and posts them to the `health-sync` function.
- `scripts/`: Setup and maintenance helpers for InsForge bootstrapping,
  Telegram webhook configuration, Kindle native install, and Kindle proof
  checks.
- `docs/`: Human and coding-assistant setup guides.

## Native Kindle App

The primary Kindle target is a native C++ app launched by KUAL. It does not use
the Kindle browser and does not store InsForge admin credentials on the device.
The KUAL menu can start the always-on dashboard, refresh once, or stop the
native process. Build, install, and config steps live in
[docs/INSTALL_FOR_USERS.md](docs/INSTALL_FOR_USERS.md).

## Message Examples

These are example Telegram messages you can send to your bot after the backend
and webhook are configured:

```text
add milk and eggs to groceries
add leg day to workout
mark milk done
remove eggs from groceries
clear todo
```

## Health Sync Companion

The native iOS companion app lives in:

```text
ios/HealthSyncCompanion
```

It reads Apple Health daily steps and nutrition totals, then sends daily
aggregate rows to the `health-sync` InsForge function. See
[docs/INSTALL_FOR_USERS.md](docs/INSTALL_FOR_USERS.md) for setup.
