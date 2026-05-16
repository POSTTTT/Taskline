# Taskline

A cross-platform task & deadline reminder app. Create a task, set a deadline, and Taskline fires a local notification when the time comes — even if the app is closed.

> **Status:** Early development. Phase 0 (project scaffold) complete. See [PLAN.md](PLAN.md) for the full roadmap.

## Why

Bills, appointments, and one-off chores ("pay the electric bill by today") slip through the cracks. Taskline is a small, focused app that does one thing well: remind you on time.

## Platforms

Built with [Flutter](https://flutter.dev) for a single codebase across:

- **Windows** — first release target
- **Android** — planned
- **iOS** — planned
- **macOS** — planned

## Planned features (v1)

- Create, edit, and delete tasks with a title, description, and deadline
- Local notification at the deadline
- Recurring tasks: daily, weekly, monthly
- Mark tasks done
- List view sorted by deadline

Not in v1: cloud sync, accounts, sharing, categories, priorities.

## Tech stack

| Layer | Choice |
|---|---|
| UI framework | Flutter (Dart) |
| Local storage | SQLite (`sqflite` / `sqflite_common_ffi`) |
| Notifications | `flutter_local_notifications` |
| State management | Riverpod |
| Windows installer | `msix` |

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (stable channel)
- Visual Studio 2022 / Build Tools with the **Desktop development with C++** workload
- Git

Verify your setup:

```powershell
flutter doctor
```

You should see green checks for **Flutter**, **Windows Version**, and **Visual Studio**.

### Run the app

```powershell
git clone https://github.com/POSTTTT/Taskline.git
cd Taskline/taskline
flutter pub get
flutter run -d windows
```

### Build a release executable

```powershell
flutter build windows
```

Output: `taskline/build/windows/x64/runner/Release/taskline.exe`

## Project structure

```
Taskline/
├── PLAN.md              # Roadmap and phases
├── README.md
├── LICENSE
└── taskline/            # Flutter project
    ├── lib/
    │   ├── main.dart
    │   ├── models/      # Task and other data classes
    │   ├── screens/     # Top-level pages
    │   ├── services/    # SQLite, notifications, etc.
    │   └── widgets/     # Reusable UI components
    ├── windows/
    ├── android/
    ├── ios/
    └── macos/
```

## Roadmap

See [PLAN.md](PLAN.md) for the phased plan. Current focus:

- [x] Phase 0 — Project scaffold
- [ ] Phase 1 — Task model + SQLite repository
- [ ] Phase 2 — Task list and add/edit screens
- [ ] Phase 3 — Local notifications (incl. recurring)
- [ ] Phase 4 — Windows polish, app icon, installer
- [ ] Phase 5 — Ship Windows v1
- [ ] Phase 6 — Mobile port (Android, iOS)
- [ ] Phase 7 — Cloud sync (v2)

## License

See [LICENSE](LICENSE).
