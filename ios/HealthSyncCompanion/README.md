# Health Sync Companion

Small iPhone app that reads Apple Health daily steps and nutrition totals, then syncs them to the `health-sync` InsForge function.

## Local config

Create an ignored local config file:

```bash
cp Config/LocalConfig.example.xcconfig Config/LocalConfig.xcconfig
```

Then set:

```text
INSFORGE_HEALTH_SYNC_URL = https:/$()/your-project.insforge.app/functions/health-sync
HEALTH_SYNC_TOKEN = your-secret-token
```

The `https:/$()/` spelling is the standard xcconfig escape for a URL containing `//`.

## Run

Open `HealthSyncCompanion.xcodeproj` in Xcode, select a real iPhone, choose a signing team, and run. HealthKit reads are only meaningful on a real device.

The app syncs:

- steps
- dietary energy, in kcal
- protein, carbs, and total fat, in grams

Manual sync sends the last 30 days on first run and the last 7 days after that. Background refresh is registered as a best-effort sync for the last 7 days.
