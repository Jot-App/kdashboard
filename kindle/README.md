# Kindle Native Dashboard Setup

The preferred Kindle surface is now a native C++ app launched by KUAL or upstart. It fetches read-only JSON from:

```text
https://your-project.insforge.app/functions/kindle-dashboard-data
```

The deployed dashboard endpoints require `DASHBOARD_READ_TOKEN`; the native
launcher sends it as `X-Dashboard-Read-Token` from local `config.sh`.

## Build

Run a local parser/render check on the Mac:

```sh
npm run native:check
```

Build a Kindle binary after installing an ARM Kindle-compatible toolchain:

```sh
make -C kindle/native kindle
```

The Makefile expects `arm-linux-gnueabi-g++`. If your compiler has another name, pass it explicitly:

```sh
make -C kindle/native kindle KINDLE_CXX=/path/to/arm-linux-gnueabi-g++
```

The current Mac does not include that GNU cross compiler by default. A Zig soft-float ARM build is available as a fallback:

```sh
make -C kindle/native extension-zig ZIG=/path/to/zig
```

Use `extension-zig` for a broadly compatible ARM EABI build. Override `ZIG_TARGET=arm-linux-gnueabihf ZIG_MCPU=generic+v7a` only if your device specifically needs a hard-float build.

## KUAL Install

Build the KUAL extension package:

```sh
make -C kindle/native extension
```

Or, with the Zig soft-float path:

```sh
make -C kindle/native extension-zig ZIG=/path/to/zig
```

Copy `kindle/native/build/kindle-dashboard-kual.tar.gz` to the Kindle and extract it into the KUAL extensions directory:

```sh
tar -C /mnt/us/extensions -xzf kindle-dashboard-kual.tar.gz
```

If the Kindle is mounted on this Mac at `/Volumes/Kindle`, install directly with:

```sh
DASHBOARD_DATA_URL=https://your-project.insforge.app/functions/kindle-dashboard-data DASHBOARD_READ_TOKEN=<read-token> npm run native:install
```

KUAL menu actions:

- `Start Dashboard (Light)`: starts the always-on e-ink dashboard for Kindle light mode.
- `Start Dashboard (Dark)`: starts the always-on e-ink dashboard for Kindle dark mode.
- `Refresh Once (Light)`: temporarily wakes the display, enables Wi-Fi, fetches, and renders one update for Kindle light mode.
- `Refresh Once (Dark)`: temporarily wakes the display, enables Wi-Fi, fetches, and renders one update for Kindle dark mode.
- `Stop Dashboard`: kills the native process and restores normal sleep behavior.

The native app caches the latest successful payload at:

```text
/mnt/us/documents/kindle-dashboard-data.json
```

If Wi-Fi is unavailable, it renders cached data with a `cached/offline` status line.

Always-on defaults can be overridden before launching:

```sh
INTERVAL=3600
DASHBOARD_SLEEP_WINDOW=off
DASHBOARD_KEEP_AWAKE=1
```

Set `DASHBOARD_SLEEP_WINDOW=HH:MM-HH:MM` to add overnight quiet mode, or `DASHBOARD_KEEP_AWAKE=0` to allow normal Kindle sleep while the dashboard is running.

## Manual Launcher

Copy the repo launcher onto the Kindle:

```sh
cp kindle/launch-dashboard.sh /mnt/us/documents/kindle-dashboard-launch.sh
chmod +x /mnt/us/documents/kindle-dashboard-launch.sh
```

Run it manually over SSH to test:

```sh
/mnt/us/documents/kindle-dashboard-launch.sh
```

If the native binary is missing, the launcher exits and writes the failure to the native dashboard log.

## Optional: Start On Boot

If SSH/root access is enabled and your Kindle uses upstart jobs, copy:

```text
kindle/upstart/kindle-dashboard.conf
```

to:

```text
/etc/init/kindle-dashboard.conf
```

Then adapt the command to run:

```sh
/mnt/us/documents/kindle-dashboard-launch.sh
```

On the next boot, the job should wait for the Kindle UI, enable Wi-Fi, wait briefly for networking, then launch the native dashboard.

If the Kindle hangs or behaves oddly, remove the upstart file:

```sh
stop kindle-dashboard
mntroot rw
rm /etc/init/kindle-dashboard.conf
mntroot ro
```

## Notes

- KUAL support varies by Kindle model and firmware.
- The native app needs Wi-Fi for fresh data but can render its cached payload offline.
- The default native profile keeps the Kindle awake, refreshes hourly, and does not use an overnight quiet window.
- Keeping Wi-Fi and a refresh process running will still use more battery than a static screensaver-style dashboard.
- If boot autostart is too aggressive, launch the native dashboard manually from KUAL.
