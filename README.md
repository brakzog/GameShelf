# GameShelf

> A lightning-fast universal game launcher focused on speed, simplicity and ownership.

![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Flutter](https://img.shields.io/badge/Flutter-desktop-02569B)
![Status](https://img.shields.io/badge/status-foundation%20alpha-orange)
![License](https://img.shields.io/badge/license-MIT-green)

GameShelf is an open-source desktop application built with Flutter.

Its goal is simple:

> **Launch your installed games instantly, regardless of where they are installed.**

GameShelf focuses on fast startup, offline availability and a modular architecture instead of unnecessary complexity.

## Philosophy

### Performance first

The application must display the cached library immediately. Launcher scans and metadata refreshes must never block startup.

### Launcher agnostic

Steam, GOG, Epic Games, Battle.net and future integrations are treated as independent and equal sources.

### Offline first

Installed games must remain visible and launchable without an Internet connection.

### Modular architecture

Each launcher integration is isolated behind a common abstraction, making GameShelf easier to test, maintain and extend.

### Open source

GameShelf is developed in the open with an emphasis on clean architecture and long-term maintainability.

## Current features

- Steam installed-game detection
- GOG installed-game detection
- Support for game libraries located on multiple drives
- SQLite-backed local library
- Instant startup from the local cache
- Background library refresh
- Game search
- Persistent favorites
- Direct game launching

## Current status

GameShelf is currently in **Alpha**.

The project is currently focused on building a solid architectural foundation before adding additional launcher integrations. The current development phase focuses on stabilizing the architecture before adding more launcher integrations.

## Planned features

Launcher Integrations

- Epic Games
- Battle.net
- EA App
- Ubisoft Connect

User Experience

- Cover cache
- Game details
- Favorites improvements
- Quick Launcher

Distribution

- Automated Windows builds
- Microsoft Store

## Roadmap

### Foundation Alpha

- Application architecture cleanup
- Riverpod state management
- Structured logging
- Persistent application settings
- Steam and GOG integration stabilization

### Launcher Alpha

- Epic Games
- Battle.net
- EA App
- Ubisoft Connect

### Beta

- Cover cache
- Game details
- Quick Launcher
- User-interface improvements
- Automated releases

### 1.0

- Stable Windows release
- Complete documentation
- Final quality assurance
- Microsoft Store packaging

## Development

GameShelf currently targets Windows desktop.

### Requirements

- Flutter with Windows desktop support
- Visual Studio with Desktop development with C++
- Git

### Run locally

```powershell
flutter pub get
flutter run -d windows
```

### Build a Windows release

```powershell
flutter build windows --release
```

The generated application is located in:

```text
build\windows\x64\runner\Release\
```

## Git workflow

GameShelf uses a GitFlow-inspired workflow:

- `main` contains stable releases
- `develop` is the integration branch
- `feature/*` branches contain new features and refactors
- `release/*` branches prepare releases
- `hotfix/*` branches contain urgent fixes

Direct pushes to `main` and `develop` are not allowed. Changes must go through pull requests.

Commits follow Conventional Commits:

```text
feat(scanner): add Epic Games manifest discovery
fix(gog): ignore the GOG Galaxy client
refactor(repository): decouple scanners from the UI
docs(readme): rewrite project documentation
```

## Documentation

Project documentation is currently being written.

## Contributing

Contribution guidelines are available in `CONTRIBUTING.md`.

## License

GameShelf is licensed under the MIT License.