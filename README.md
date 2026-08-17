# vespera

A new Flutter project.

## Run on web (permanent dev workflow)

**Do not** use `flutter run -d web-server` for day-to-day UI work. That mode leaves an old process on port `8080` and the browser often shows a stale build until you restart.

### Recommended (hot reload — changes show when you save)

**Option A — Cursor / VS Code**

1. Open this folder in Cursor.
2. Press **F5** or Run → **Vespera Web (Chrome + Hot Reload)**.
3. Edit any `.dart` file and **save** — the app updates automatically (`dart.flutterHotReloadOnSave` is enabled in `.vscode/settings.json`).

**Option B — Terminal**

```powershell
cd D:\App
.\scripts\dev_web.ps1
```

Or double-click `scripts\dev_web.bat`.

- **Save** a file → hot reload (with Cursor) or press **`r`** in the terminal.
- Press **`R`** for a full hot restart.
- Press **`q`** to quit.

The script always frees port `8080` before starting, so you never get a stuck old server.

### Only if you need a fixed localhost URL

```powershell
.\scripts\dev_web.ps1 -Server
```

Then open http://localhost:8080 and use **Ctrl+F5** after each change (no hot reload).

## Getting Started

This project is a starting point for a Flutter application.

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
