# Inyon

## Git Hooks

This project uses a **pre-push hook** that blocks `git push` unless both unit tests and UI/E2E tests pass.

### Install

```bash
./scripts/setup-git-hooks.sh
```

### What it runs

1. **Unit tests** (`InyonTests`) — must all pass
2. **UI/E2E tests** (`InyonUITests`) — must exist and pass

### Bypass (discouraged)

```bash
git push --no-verify
```
