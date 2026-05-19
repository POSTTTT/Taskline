# Changelog

All notable changes to Taskline. Versioning follows [Semantic Versioning](https://semver.org).

## [1.0.0] — 2026-05-20

First public release. Windows-only desktop build; mobile and macOS ports planned.

### Features

- **Tasks with deadlines.** Add tasks with a title, optional description, due date, and due time. Edit or delete any time.
- **Two-tab view.** "Upcoming" shows pending tasks; "Complete" shows finished ones. Swipe right on a row to toggle complete, swipe left to delete.
- **Recurring tasks.** Pick Daily / Weekly / Monthly per task; the next occurrence is auto-scheduled after each fire.
- **Smart reminders.** Six configurable lead-time buckets (More than 1 year → Due in 1 hour). Each bucket has a user-defined frequency (`every N minutes/hours/days/weeks/months/years`) or can be turned off. Reminders fire as Windows toast notifications.
- **System tray integration.** Closing the window minimizes Taskline to the tray. Right-click the tray icon for Show / New task / Quit. The app keeps running in the background so scheduled notifications stay reliable.
- **Launch at startup.** Toggle in Settings → General. Writes to `HKCU\…\Run`.
- **iOS-style theme.** Clean light interface modeled after Apple Reminders / Things 3: grouped cards, blue accent, iOS-style switches and pickers.
- **Customisable date and time format.** 12 / 24-hour clock; DD/MM/YYYY, MM/DD/YYYY, or YYYY-MM-DD date order.
- **Local-only storage.** All tasks live in a SQLite database under your local app-support directory. No accounts, no cloud, no telemetry.

### Install

See the [README](README.md#install-windows) for step-by-step installation instructions — Windows requires installing the public code-signing certificate once before the signed MSIX will install.

### Known limitations

- **Windows only** for now. Android / iOS / macOS coming in v2.
- **No cloud sync.** Tasks live on this PC. Multi-device sync is on the roadmap.
- **Self-signed MSIX.** End users must install `scripts/taskline.cer` to *Local Machine → Trusted People* before installing the MSIX. A real CA-signed cert will replace this once usage justifies the cost.
- **Long-distance recurring reminders** that span months/years are approximated using fixed-day durations (30-day month, 365-day year). Accurate enough for v1; calendar-aware math may land in a later release.
