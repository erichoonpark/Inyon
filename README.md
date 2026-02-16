# Inyon

## Git Hooks

This project uses a **pre-push hook** that blocks `git push` unless both unit tests and UI/E2E tests pass.

### Install

```bash
./scripts/setup-git-hooks.sh
```

### Simulator Selection Behavior

The pre-push hook uses `scripts/select_simulator.sh` and selects simulators by **exact device name** in this order:

1. `iPhone 17 Pro`
2. `iPhone 17`
3. `iPhone 16e`
4. `iPhone 16`
5. First available iOS simulator (fallback)

This prevents substring mistakes like matching `iPhone 16e` and then trying to run on nonexistent `iPhone 16`.

### What the Hook Runs

1. **Unit tests** (`InyonTests`) must pass.
2. **UI/E2E tests** (`InyonUITests`) must exist and pass.

If `InyonUITests` is missing, pre-push fails closed.

### Bypass (Discouraged)

```bash
git push --no-verify
```

## Data Consistency Guarantees

Anonymous-to-authenticated onboarding migration now uses Firestore transaction semantics:

1. Anonymous onboarding data and authenticated onboarding context are read in one transaction.
2. Existing authenticated user fields win on conflict.
3. Anonymous onboarding doc is deleted in the same successful transaction commit.
4. Migration errors are propagated; onboarding completion should not proceed on failure.

## Testing Matrix

| Area | Path | Purpose |
|---|---|---|
| Unit/Integration | `Tests/` | Business logic, onboarding/auth flow, migration behavior |
| UI/E2E | `UITests/` | Critical user flows in simulator |
| Hook/Script | `scripts/` + `.githooks/` | Pre-push gate behavior and simulator selection |

## Deterministic UI Test Mode

`AuthService` supports UITest-only auth behavior via launch environment.

- `INYON_UI_TEST_AUTH_MODE=sign_in_failure`: forces deterministic sign-in failure without live backend call.

This mode is used only by UI tests and does not affect production runtime behavior.

## How To Verify Before Push

```bash
bash scripts/prepush_hook_tests.sh
bash -n .githooks/pre-push

SIM_DEST="$(bash scripts/select_simulator.sh --destination)"
xcodebuild test -project Inyon.xcodeproj -scheme Inyon -destination "$SIM_DEST" -only-testing:InyonTests
xcodebuild test -project Inyon.xcodeproj -scheme Inyon -destination "$SIM_DEST" -only-testing:InyonUITests
```
