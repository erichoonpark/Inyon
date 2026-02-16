# Inyon GitHub Issue Drafts

Copy each section into a new GitHub issue.

## 1) US-001
**Title:** [P0] US-001: Email/Password signup in active onboarding

**Labels:** `P0`, `auth`, `onboarding`, `mvp`

**Body:**
```md
## User Story
As a new user, I can create an account from the active onboarding flow so setup is truly persistent and authenticated.

## Scope
Implement email/password account creation in `AccountCreationView` and connect it to `AuthService`.

## Acceptance Criteria
- [ ] User can create an account from `AccountCreationView` using email/password.
- [ ] On success, auth state updates and user is routed into main app.
- [ ] On failure, user sees actionable error text and can retry.

## Notes
- Remove current TODO button behavior that calls completion without real auth.
```

## 2) US-002
**Title:** [P0] US-002: Email/Password login in active login view

**Labels:** `P0`, `auth`, `onboarding`, `mvp`

**Body:**
```md
## User Story
As a returning user, I can log in with email/password from the active login view.

## Scope
Implement email/password login in `LoginView` and route success to authenticated app state.

## Acceptance Criteria
- [ ] User can sign in from `LoginView` using email/password.
- [ ] Invalid credentials surface a visible error.
- [ ] Successful login routes to main app without relaunch.

## Notes
- Replace TODO placeholder action for email login button.
```

## 3) US-003
**Title:** [P0] US-003: Capture required MVP identity fields in canonical flow

**Labels:** `P0`, `onboarding`, `data-model`, `mvp`

**Body:**
```md
## User Story
As a new user, I can enter first name, last name, and email in the active onboarding flow.

## Scope
Ensure active onboarding collects required identity fields and persists them to the user document.

## Acceptance Criteria
- [ ] First name, last name, and email are collected in the same flow users currently use.
- [ ] Required fields are validated before submit.
- [ ] Data is saved to Firestore user record.

## Notes
- `SignupFlowView` currently collects these but is not the canonical flow.
```

## 4) US-004
**Title:** [P0] US-004: Unify onboarding into one canonical implementation

**Labels:** `P0`, `onboarding`, `refactor`, `mvp`

**Body:**
```md
## User Story
As a product team, onboarding follows one canonical flow to avoid duplicated logic.

## Scope
Consolidate `OnboardingFlow` and `SignupFlowView` behavior into a single implementation.

## Acceptance Criteria
- [ ] Duplicate onboarding/signup logic is removed or merged (`OnboardingFlow` vs `SignupFlowView`).
- [ ] One source of truth for step order and persistence.
- [ ] No dead-end auth buttons remain in user-facing flow.

## Notes
- Keep UX consistent with current onboarding design direction.
```

## 5) US-005
**Title:** [P0] US-005: Replace Home placeholder with backend reflection payload

**Labels:** `P0`, `home`, `backend`, `mvp`

**Body:**
```md
## User Story
As a user, I see personalized daily reflection content generated server-side.

## Scope
Replace static Home copy with reflection fetched from backend (Firebase Functions/Firestore output).

## Acceptance Criteria
- [ ] Home fetches reflection content generated server-side.
- [ ] Placeholder hardcoded reflection is removed from default path.
- [ ] If backend is unavailable, user sees graceful fallback state.

## Notes
- Keep tone aligned with `CLAUDE.md` constraints.
```

## 6) US-006
**Title:** [P0] US-006: First-run post-signup reflection experience

**Labels:** `P0`, `onboarding`, `home`, `mvp`

**Body:**
```md
## User Story
As a new user, I get setup confirmation and first reflection immediately after signup.

## Scope
Implement first-run transition from successful signup to initial personalized reflection experience.

## Acceptance Criteria
- [ ] Immediately after signup, user sees setup-complete framing and first reflection.
- [ ] Flow occurs once for first run and does not repeat on later launches.

## Notes
- Keep confirmation minimal and calm.
```

## 7) US-007
**Title:** [P1] US-007: Apple Sign In for signup and login

**Labels:** `P1`, `auth`, `apple-sign-in`

**Body:**
```md
## User Story
As a user, I can sign in with Apple during signup and login.

## Scope
Integrate Sign in with Apple for both account creation and returning-user login paths.

## Acceptance Criteria
- [ ] Apple sign-in works from both account creation and login entry points.
- [ ] Auth session persists across relaunch.
- [ ] User cancellation and provider errors are handled cleanly.
```

## 8) US-008
**Title:** [P1] US-008: Save/load reliability and explicit error states

**Labels:** `P1`, `firestore`, `ux`, `reliability`

**Body:**
```md
## User Story
As a user, I get clear feedback when profile data fails to load or save.

## Scope
Add visible error/success/loading states for Firestore operations in profile/onboarding persistence flows.

## Acceptance Criteria
- [ ] Firestore read/write errors are surfaced in UI.
- [ ] Save button reflects pending/success/failure states.
- [ ] Silent failure behavior is removed.

## Notes
- Current save path in `YouView` fails silently.
```

## 9) US-009
**Title:** [P1] US-009: Chart CTA routes to real destination

**Labels:** `P1`, `guide`, `navigation`

**Body:**
```md
## User Story
As a user, tapping “View my chart” opens a real chart/context destination.

## Scope
Wire CTA navigation from Guide to an implemented destination screen.

## Acceptance Criteria
- [ ] “View my chart” opens a concrete screen.
- [ ] Destination has at least minimal meaningful content.
- [ ] No TODO-only tap action remains.
```

## 10) US-010
**Title:** [P1] US-010: Notification permission and daily schedule

**Labels:** `P1`, `notifications`, `settings`

**Body:**
```md
## User Story
As a user, I can receive daily reflection notifications at my preferred time.

## Scope
Request notification permission and schedule/cancel local notifications based on profile settings.

## Acceptance Criteria
- [ ] User can grant/deny local notifications.
- [ ] Preferred time is used for daily schedule in local timezone.
- [ ] Disabled toggle cancels scheduled notifications.
```

## 11) US-011
**Title:** [P2] US-011: Derived context correctness (lunar/zodiac)

**Labels:** `P2`, `profile`, `data-correctness`

**Body:**
```md
## User Story
As a user, derived context values are accurate or clearly unavailable.

## Scope
Replace placeholder lunar/zodiac logic or gate display until accurate implementation exists.

## Acceptance Criteria
- [ ] Derived fields are either accurate or explicitly unavailable.
- [ ] “Approximate” placeholder logic is removed from production path.
```

## 12) US-012
**Title:** [P2] US-012: Analytics production wiring

**Labels:** `P2`, `analytics`, `instrumentation`

**Body:**
```md
## User Story
As a team, key funnel and engagement events are captured in production analytics.

## Scope
Replace debug print analytics stubs with real event instrumentation.

## Acceptance Criteria
- [ ] Guide and key funnel events send to real analytics backend.
- [ ] Debug print-only analytics paths are replaced for release builds.
```

## 13) US-013
**Title:** [P2] US-013: Auth/onboarding/persistence test coverage

**Labels:** `P2`, `testing`, `qa`

**Body:**
```md
## User Story
As a team, core auth and onboarding behaviors are protected by automated tests.

## Scope
Add unit/integration/UI tests for auth flows and critical onboarding persistence paths.

## Acceptance Criteria
- [ ] Tests cover signup/login success and failure paths.
- [ ] Tests cover onboarding completion and Firestore persistence.
- [ ] At least one UI test validates critical onboarding happy path.
```

## Optional Milestone Mapping
- **Sprint 1:** US-001, US-002, US-003, US-004
- **Sprint 2:** US-005, US-006, US-008
- **Sprint 3:** US-007, US-009, US-010, US-011, US-012, US-013
