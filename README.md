<div align="center">

<img src="taskline/assets/app_icon.png" alt="Taskline" width="120" />

# Taskline ⏳

*Set a deadline. Get reminded on time. Even if the app is closed.*

[Download](https://github.com/POSTTTT/Taskline/releases/latest) · [Report a bug](https://github.com/POSTTTT/Taskline/issues)

![Release](https://img.shields.io/github/v/release/POSTTTT/Taskline?style=for-the-badge&label=RELEASE&labelColor=0a0a0a&color=00ff66)
![Platform](https://img.shields.io/badge/PLATFORM-Windows-a0a0a0?style=for-the-badge&labelColor=0a0a0a)
![Built with](https://img.shields.io/badge/BUILT%20WITH-Flutter%20%C2%B7%20Dart%20%C2%B7%20SQLite-00ff66?style=for-the-badge&labelColor=0a0a0a)

</div>

**A small, focused task & deadline reminder** — one thing, done well. Create a task, set a deadline, and Taskline fires a local notification when the time comes, even if the window is closed.

## The idea

Bills, appointments, and one-off chores — "pay the electric bill by today" — slip through the cracks. The heavyweight to-do apps want accounts, cloud sync, and a monthly fee to do it. I just wanted a thing that reminds me on time and then gets out of the way.

So Taskline does exactly that: local-only, no accounts, no telemetry, no network. It lives in the tray, fires a Windows toast when a deadline approaches, and that's it. Open it, set it, forget it.

## Features

### Tasks
- Title, description, due date and time.
- Two tabs — **Upcoming** / **Complete** — with swipe-to-complete and swipe-to-delete.
- **Recurring tasks** — daily / weekly / monthly (monthly clamps to month-end so Jan 31 → Feb 28).
- A calendar view of everything on your plate.

### Reminders
- **Smart lead times** — six configurable buckets (1 hour out → more than a year out), each with its own frequency. A deadline a month away nudges you differently than one an hour away.
- **Windows toasts** that fire even when the app window is closed.
- All scheduling is derived automatically — change a task or a setting and the whole reminder schedule re-computes.

### Around the app
- **System tray** — closing the window minimizes to tray so notifications keep working; real quit is in the tray menu.
- **Launch at Windows startup** (optional).
- **Single instance** — a second launch just surfaces the running window.
- Customizable 12/24-hour clock and date format.
- Terminal-brutalist theme — monospace type, CRT-phosphor green palette, hard-edged boxes.

## How it works

A single Flutter codebase; Windows desktop is the shipped target.

- **Local-only storage** — SQLite for tasks, `shared_preferences` for settings. Nothing leaves your machine.
- **State via Riverpod** — mutations are optimistic (the list updates instantly, then persists), and loading the task list re-derives the full notification schedule.
- **DateTimes are UTC at rest, local for display** — recurrence and reminder math stay pure and unit-tested.
- **Slotted notification IDs** — each task owns a 100-ID block, so cancelling and rescheduling a task never collides with another's reminders.

## Install (Windows)

1. **Download** `taskline.msix` and `taskline.cer` from the [Releases](https://github.com/POSTTTT/Taskline/releases) page.

2. **Trust the signing certificate (one-time).** The MSIX is self-signed. In PowerShell **as Administrator**:

   ```powershell
   Import-Certificate -FilePath taskline.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
   ```

   Or via the GUI: right-click `taskline.cer` → **Install Certificate** → **Local Machine** → **Place all certificates in the following store** → **Browse** → **Trusted People** → **Finish**.

3. **Install.** Double-click `taskline.msix` → **Install**. Taskline appears in the Start Menu.

4. **First run.** Open it from the Start Menu. Optional: **Settings → General → Launch at startup**.

To uninstall: **Settings → Apps → Installed apps → Taskline → Uninstall**.

## Develop

Prerequisites: [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (stable), Visual Studio 2022 with the **Desktop development with C++** workload **and** **C++ ATL for v143 build tools**, Git, PowerShell. Run `flutter doctor` and expect green checks for Flutter, Windows, and Visual Studio.

```powershell
git clone https://github.com/POSTTTT/Taskline.git
cd Taskline/taskline
flutter pub get
flutter run -d windows
```

## Build

```powershell
# Unsigned exe → taskline/build/windows/x64/runner/Release/taskline.exe
flutter build windows --release

# Signed MSIX (from repo root)
powershell -ExecutionPolicy Bypass -File scripts/create-signing-cert.ps1   # one-time cert
powershell -ExecutionPolicy Bypass -File scripts/build-release.ps1         # build + sign
```

The signed `taskline.msix` lands in `taskline/build/windows/x64/runner/Release/`; the matching public cert is `scripts/taskline.cer` (committed).

## Roadmap

See [PLAN.md](PLAN.md). Windows v1 has shipped (Phases 0–5). Next up: mobile port (Android, iOS), then cloud sync.

## License

See [LICENSE](LICENSE).
</content>
</invoke>
