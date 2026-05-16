# Taskline — Project Plan

A cross-platform task & deadline reminder app. Users create tasks with deadlines; the app fires local notifications at the right time, even when closed. Windows first, then Android, iOS, macOS.

## Decisions

| Question | Decision | Reason |
|---|---|---|
| UI framework | **Flutter (Dart)** | One codebase for Windows, macOS, iOS, Android |
| Storage (v1) | **SQLite, local only** | No backend, no accounts, no hosting cost |
| Cloud sync | **Deferred to v2** | Avoid tripling v1 scope; add once the app proves useful |
| First platform | **Windows** | User's primary machine |

## Tech stack

| Layer | Choice |
|---|---|
| UI framework | Flutter (Dart) |
| Local DB | `sqflite` (mobile) + `sqflite_common_ffi` (desktop) |
| Notifications | `flutter_local_notifications` |
| State management | `riverpod` |
| Date/time correctness | `timezone` package |
| Windows installer | `msix` package |

## Data model

```
Task
  id            INTEGER PRIMARY KEY
  title         TEXT NOT NULL
  description   TEXT
  deadline      DATETIME (stored as UTC ISO-8601)
  is_done       BOOLEAN
  recurrence    TEXT  -- none | daily | weekly | monthly
  created_at    DATETIME
```

## v1 feature scope (Windows release)

- [x] Add / edit / delete tasks
- [x] Deadline (date + time)
- [x] One local notification fired at the deadline
- [x] Recurring tasks (daily, weekly, monthly) — auto-reschedule after each fire
- [x] Mark task done
- [x] List view sorted by deadline

Out of scope for v1: categories, tags, priorities, sync, sharing, attachments.

## Phased roadmap

### Phase 0 — Setup (1–2 days)
- Install Flutter SDK and configure PATH
- `flutter doctor` passes for Windows desktop
- `flutter create taskline` inside this repo
- Verify `flutter run -d windows` opens the default counter app
- Folder layout: `lib/models`, `lib/screens`, `lib/services`, `lib/widgets`
- Commit baseline

### Phase 1 — Core data layer (2–3 days)
- `Task` model class with `toMap` / `fromMap`
- `TaskRepository` using SQLite (CRUD + query by deadline)
- Initialize `sqflite_common_ffi` on Windows
- Unit tests for the repository

### Phase 2 — UI: task list + add/edit (3–5 days)
- Home screen: list of tasks, sorted by deadline, with overdue styling
- Add/edit screen: title, description, date+time picker, recurrence dropdown
- Mark-done toggle, swipe-to-delete
- Empty state, basic theming

### Phase 3 — Notifications (3–4 days) — the trickiest part
- Initialize `flutter_local_notifications` for Windows
- Schedule a notification when a task is created or edited
- Cancel the notification when a task is deleted or marked done
- For recurring tasks: reschedule the next occurrence after each fire
- Verify behavior when: app closed, app in background, system restarted

### Phase 4 — Polish for Windows v1 (2–3 days)
- App icon, window title
- Build Windows installer with the `msix` package
- Optional "start on boot" so notifications fire even if app was never opened
- Settings screen: notification sound, default reminder lead time

### Phase 5 — Ship Windows v1 🎯

### Phase 6 — Mobile port (later)
- Run on Android emulator; fix platform-specific bugs
- Adjust UI for smaller screens
- Android 13+ runtime notification permission
- For iOS / macOS: need access to a Mac, Xcode, Apple Developer account ($99/yr)

### Phase 7 — Cloud sync (v2)
- Backend options: Firebase (fastest) or custom ASP.NET / FastAPI server
- Add accounts / login, sync logic, conflict resolution

## Timeline estimate

At ~2–3 hours a day: **Windows v1 in 4–6 weeks**. Notifications and recurring logic typically take longer than expected — budget extra there.

## Top risks

1. **Windows notification quirks** — `flutter_local_notifications` on Windows is newer than on mobile. Prototype Phase 3 early, not at the end.
2. **Timezone bugs** — always store UTC, display local. Use the `timezone` package; do not rely on `DateTime.now()` alone.
3. **Background scheduling on Windows** — if the app process is fully killed, notifications won't fire unless you either register with the OS scheduler or run on startup.

## Folder structure (target)

```
Taskline/
  PLAN.md
  README.md
  LICENSE
  taskline/                 # Flutter project (created in Phase 0)
    lib/
      main.dart
      models/
      screens/
      services/
      widgets/
    test/
    windows/
    android/
    ios/
    macos/
```
