# Contributing to GameShelf

First of all, thank you for your interest in GameShelf!

Whether you're fixing a bug, improving the UI or adding support for a new launcher, every contribution is welcome.

---

## Development Workflow

GameShelf follows a GitFlow-inspired workflow.

1. Create a branch from `develop`

```bash
git checkout develop
git pull
git checkout -b feature/my-feature
```

2. Implement your changes.

3. Test your changes.

4. Commit using the Conventional Commits specification.

Example:

```text
feat(scanner): add Epic Games scanner
fix(gog): ignore GOG Galaxy application
docs(readme): improve installation guide
```

5. Open a Pull Request targeting `develop`.

---

## Coding Guidelines

- Keep the code simple.
- Prefer readability over cleverness.
- Separate UI from business logic.
- Write self-explanatory code.
- Avoid unnecessary dependencies.
- Keep startup performance a priority.

---

## Design Philosophy

GameShelf is built around a few principles:

- ⚡ Performance First
- 💾 Offline First
- 🎮 Launcher Agnostic
- 🧩 Modular Architecture

Every new feature should respect these principles.

---

## Questions

If you're unsure about a feature or an architectural decision, open an issue before starting the implementation.

Happy coding! 🚀