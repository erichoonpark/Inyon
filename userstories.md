# Inyon User Stories

## Implemented

- As a new user, I can see onboarding entry with `Get Started` and login path selection.
- As a new user, I can provide birth date, city, optional birth time, and personal anchors.
- As a user, onboarding context persists to Firestore.
- As a signed-in user, I am routed into the main app; signed-out users remain in onboarding.
- As a new/returning user, I can sign up and log in with email/password.
- As a user, onboarding save uses returned account UID to avoid auth-listener race.
- As a user, anonymous onboarding migration is transactional:
  - existing authenticated fields win on conflict
  - anonymous onboarding doc is deleted only in successful transaction commit
  - migration errors propagate and block completion path
- As a user, I can edit profile context in You tab and persist changes.
- As a team, pre-push blocks push unless unit and UI/E2E test suites pass.
- As a team, pre-push simulator selection is exact-name and robust to `iPhone 16e` vs `iPhone 16`.

## Partially Implemented

- As a user, I receive clear auth failure feedback and can retry.
  - Implemented for email flows with visible error + retry action.
  - Needs further product copy/normalization for all provider failure cases.
- As a team, automated tests cover core onboarding/auth paths.
  - Unit and UI tests exist for key cases.
  - Broader integration coverage against live backend behavior is still limited.

## Not Implemented

- As a new or returning user, I can authenticate with Apple Sign In.
  - Current code still contains TODOs in `OnboardingFlow.swift` for Apple auth actions.
- As a user, I receive personalized daily reflection content from backend services (still placeholder/static paths).
- As a user, chart CTA routes to fully implemented destination content.
- As a user, notification scheduling is fully wired end-to-end with timezone-aware daily delivery.
- As a team, analytics is fully production-wired beyond debug pathways.

## Testing Matrix

| Category | Location | Current Coverage |
|---|---|---|
| Unit/Integration | `Tests/` | Onboarding/auth logic, migration behavior, data handling |
| UI/E2E | `UITests/` | Onboarding smoke, login failure UX, form validation |
| Hook/Script | `scripts/`, `.githooks/` | Pre-push simulator selection and quality gate behavior |

## How To Verify Before Push

```bash
bash scripts/prepush_hook_tests.sh
bash -n .githooks/pre-push

SIM_DEST="$(bash scripts/select_simulator.sh --destination)"
xcodebuild test -project Inyon.xcodeproj -scheme Inyon -destination "$SIM_DEST" -only-testing:InyonTests
xcodebuild test -project Inyon.xcodeproj -scheme Inyon -destination "$SIM_DEST" -only-testing:InyonUITests
```
