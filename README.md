# Taskline

A cross-platform task & deadline reminder app. Create a task, set a deadline, and Taskline fires a local notification when the time comes — even if the app is closed.

> **Status:** v1.0.0 shipped for Windows. Mobile and macOS ports planned. See [CHANGELOG.md](CHANGELOG.md) and [PLAN.md](PLAN.md).

## Why

Bills, appointments, and one-off chores ("pay the electric bill by today") slip through the cracks. Taskline is a small, focused app that does one thing well: remind you on time.

## Platforms

Built with [Flutter](https://flutter.dev) for a single codebase across:

- **Windows** — v1 shipped
- **Android** — planned
- **iOS** — planned
- **macOS** — planned

## Features (v1)

- Tasks with title, description, due date and time
- Two tabs: **Upcoming** / **Complete**, with swipe-to-complete and swipe-to-delete
- Recurring tasks (daily / weekly / monthly)
- Smart reminders: six configurable lead-time buckets (1 hour out → more than a year out), each with a user-defined frequency
- Windows toast notifications, fired even when the app window is closed
- System tray icon, closing the window minimizes to tray
- Launch at Windows startup (optional)
- Customizable 12/24-hour clock and date format
- All data local; no accounts, no cloud, no telemetry

## Install (Windows)

1. **Download the latest release** — grab `taskline.msix` and `taskline.cer` from the [Releases](https://github.com/POSTTTT/Taskline/releases) page.

2. **Trust the signing certificate (one-time).** The MSIX is self-signed, so Windows won't trust it until you install the public cert. In PowerShell **as Administrator**:

   ```powershell
   Import-Certificate -FilePath taskline.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
   ```

   Or via the GUI: right-click `taskline.cer` → **Install Certificate** → **Local Machine** → **Place all certificates in the following store** → **Browse** → **Trusted People** → **Next** → **Finish**.

3. **Install the app.** Double-click `taskline.msix`. Windows shows the install dialog → click **Install**. Taskline appears in the Start Menu.

4. **First run.** Open Taskline from the Start Menu. The first launch sets up notifications. Optional: open **Settings → General** and turn on **Launch at startup**.

To uninstall later, use **Settings → Apps → Installed apps → Taskline → Uninstall**.

## Build from source

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (stable channel)
- Visual Studio 2022 / Build Tools with the **Desktop development with C++** workload **and** **C++ ATL for v143 build tools (x86 & x64)**
- Git
- PowerShell

Verify your setup:

```powershell
flutter doctor
```

Expect green checks for **Flutter**, **Windows Version**, and **Visual Studio**.

### Run in dev

```powershell
git clone https://github.com/POSTTTT/Taskline.git
cd Taskline/taskline
flutter pub get
flutter run -d windows
```

### Build an unsigned release exe

```powershell
flutter build windows --release
```

Output: `taskline/build/windows/x64/runner/Release/taskline.exe`.

### Build a signed MSIX release

```powershell
# One-time: generate the self-signed code-signing cert
powershell -ExecutionPolicy Bypass -File scripts/create-signing-cert.ps1

# Each release: build + sign
powershell -ExecutionPolicy Bypass -File scripts/build-release.ps1
```

Output: `taskline/build/windows/x64/runner/Release/taskline.msix`, signed with `scripts/taskline.pfx`. The matching public certificate is `scripts/taskline.cer` (committed to the repo).

## Project structure

```
Taskline/
├── PLAN.md               # Roadmap and phases
├── CHANGELOG.md          # Version history
├── README.md
├── LICENSE
├── scripts/              # Release tooling
│   ├── create-signing-cert.ps1
│   ├── build-release.ps1
│   ├── generate-icon.ps1
│   ├── install-windows-shortcut.ps1   # legacy, only needed for unpackaged dev builds
│   └── taskline.cer      # public signing cert (committed)
└── taskline/             # Flutter project
    ├── lib/
    │   ├── main.dart
    │   ├── models/       # Task and AppSettings classes
    │   ├── providers/    # Riverpod state
    │   ├── screens/      # Home, edit, settings
    │   ├── services/     # SQLite, notifications, tray, settings
    │   ├── theme/        # iOS-style theme
    │   └── widgets/      # Reusable UI components
    ├── assets/           # App icon, bundled with the app
    ├── windows/          # Windows shell, runner, MSIX config
    ├── android/          # Android shell (mobile port pending)
    ├── ios/              # iOS shell
    └── macos/            # macOS shell
```

## Roadmap

See [PLAN.md](PLAN.md) for details.

- [x] Phase 0 — Project scaffold
- [x] Phase 1 — Task model + SQLite repository
- [x] Phase 2 — Task list and add/edit screens
- [x] Phase 3 — Local notifications (incl. recurring)
- [x] Phase 4 — Windows polish, app icon, installer
- [x] Phase 5 — Ship Windows v1
- [ ] Phase 6 — Mobile port (Android, iOS)
- [ ] Phase 7 — Cloud sync (v2)

## License

See [LICENSE](LICENSE).
