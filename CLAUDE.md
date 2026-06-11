# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

The repo root holds release tooling and docs; **the Flutter project lives in the `taskline/` subdirectory**. Run all `flutter`/`dart` commands from `taskline/`, not the repo root.

```
Taskline/
├── scripts/        # PowerShell release tooling + committed signing cert (.cer/.pfx)
├── README.md       # User-facing install/build docs (the root one — the taskline/ README is the default Flutter stub)
└── taskline/       # Flutter app
```

## Commands

All from within `taskline/`:

```powershell
flutter pub get                 # install deps
flutter run -d windows          # dev run (primary target)
flutter analyze                 # lint (flutter_lints + analysis_options.yaml)
flutter test                    # all tests
flutter test test/models/task_test.dart                       # single file
flutter test --plain-name "computes reminders"                # single test by name
flutter build windows --release # unsigned exe → build/windows/x64/runner/Release/taskline.exe
```

Release builds (from repo root, PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/create-signing-cert.ps1   # one-time: self-signed cert
powershell -ExecutionPolicy Bypass -File scripts/build-release.ps1         # build + sign → taskline.msix
```

The MSIX is configured via `msix_config:` in `pubspec.yaml`. `identity_name`/AUMID (`com.taskline.taskline`) and the toast activator CLSID must stay in sync with the notification GUID in `notification_service.dart` — a packaged install otherwise can't fire Windows toasts.

## Architecture

A single-codebase Flutter task/deadline reminder. Windows desktop is the shipped target; Android/iOS/macOS/Linux code paths exist but are unshipped. Local-only: SQLite for tasks, `shared_preferences` for settings, no network/accounts.

**State (Riverpod, in `lib/providers/`).** Two `AsyncNotifier`s drive everything:
- `tasksProvider` (`TasksNotifier`) — the task list. Mutations are **optimistic**: `_setTasks` pushes new state immediately (kept sorted by deadline to match `repo.getAll()`), then persists to SQLite and reschedules notifications; any failure falls back to `_reloadFromDb()`. Don't reintroduce loading-spinner round-trips on mutation.
- `settingsProvider` (`SettingsNotifier`) — `AppSettings`, persisted as JSON. `save()` also reconciles OS launch-at-startup via the `launch_at_startup` package.

`TasksNotifier.build()` depends on both the repository and settings, and calls `notificationService.syncAll()` on load — so changing settings or the task list re-derives the full notification schedule.

**Data layer (`lib/services/`, `lib/models/`).**
- `AppDatabase.open()` (database.dart) opens SQLite, switching to the FFI factory on desktop. Schema version 2; `TaskRepository.createSchema`/`migrate` own the DDL and migrations (v1→v2 added `recurrence_end_date`).
- `Task` (models/task.dart) **stores all DateTimes in UTC** (the constructor coerces), converting to local only for display/calendar. `occursOn` / `occurrencesIn` / `nextOccurrenceAfter` compute recurrence (none/daily/weekly/monthly, with monthly clamping to month-end). Recurrence logic is pure and unit-tested — keep it that way.

**Notifications (`notification_service.dart`).** This is the most intricate piece.
- `computeReminders` walks backward from a task's deadline through six distance buckets (1h, 1d, 1w, 1mo, 1y, >1y), emitting reminders at each bucket's user-configured `ReminderInterval`, always including the deadline itself, capped at 50 per task.
- Notification IDs are **slotted**: each task owns IDs `taskId * 100 .. taskId * 100 + 99` (`_slotSize = 100`). `schedule` fills slots from sorted reminders; `cancel(taskId)` clears the whole 100-ID block. This slot math is why a task can have at most ~50 reminders — don't change `_slotSize` without revisiting ID collisions.

**Desktop shell (`lib/main.dart`, `single_instance.dart`, `tray_service.dart`).**
- `SingleInstance.acquireOrForward` enforces one process by binding a fixed loopback TCP port (49150); a second launch connects, signals "show", and exits. The first instance surfaces its window via `window_manager` (Win32 `FindWindow`/`ShowWindow` is only a fallback — it doesn't reliably reverse `windowManager.hide()`).
- `TrayService` makes the window's close button **hide to tray** (`setPreventClose(true)`) so scheduled notifications keep working; real quit is in the tray menu.

**UI (`lib/screens/`, `lib/widgets/`, `lib/theme/`).** Terminal-brutalist theme — monospace type, CRT-phosphor green palette (green-on-black dark / green-on-paper light), zero-radius boxes, thick borders, hard offset shadows. Design tokens live in `theme/app_theme.dart` (`AppColors`, `AppTextStyles`, `AppRadii`, `NbStyles`); reusable primitives in `widgets/nb.dart` (`NbCard`, `NbButton`, `NbCheckbox`, `NbSwitch`, etc.). Screens consume only those tokens/primitives, so restyling happens centrally. `NbStyles.foregroundOn(fill)` picks legible text/icon colour over any fill (use it instead of hand-coding a foreground on accent fills). `home_screen` (Upcoming/Complete tabs + calendar), `task_edit_screen`, `settings_screen`. Date/time rendering is driven by `AppSettings` patterns (`combinedPattern`, `intl`).

## Conventions

- **DateTimes are UTC at rest, local for display.** New persistence or scheduling code must follow this; bugs here are subtle.
- Recurrence and reminder-computation logic stays pure and unit-testable (see `test/models/`, `test/services/`).
- The user handles their own commits — do not run `git commit`.
