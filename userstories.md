# Inyon User Stories

## Already Done

- [x] As a new user, I can see an onboarding entry screen with paths for getting started or logging in, so I can choose my path.
- [x] As a new user, I can provide birth date and birth city during onboarding, so the app can store my core birth context.
- [x] As a new user, I can optionally provide birth time or mark it unknown, so I can continue even without complete data.
- [x] As a new user, I can select one or more personal anchors (Direction, Energy, Love, Work, Rest), so reflections can align with what matters to me.
- [x] As a user, my onboarding context is persisted to Firestore, so my setup is not lost between sessions.
- [x] As a signed-in user, I am routed into the main app; as a signed-out user, I remain in onboarding.
- [x] As a user, I can navigate between Home, Guide, and You tabs in a custom bottom navigation.
- [x] As a user, I can read a calm educational guide about Saju concepts and the five elements.
- [x] As a user, I can open element detail sheets from the Guide for deeper context.
- [x] As a user, I can edit my birth context and personal anchors from the You screen and save changes.
- [x] As a user, I can toggle notification preferences and a preferred time, and persist those settings.
- [x] As a team, we have baseline tests for onboarding data flow logic and app icon configuration.

## Needed / Not Finished Yet

### Account Creation & Login
- [x] As a new user, I can sign up with Apple.
- [x] As a new user, I can sign up with email.
- [x] As a returning user, I can log in with Apple and access my profile.
- [x] As a returning user, I can log in with email and access my profile.
- [x] As a new user, onboarding data is saved to Firestore.
- [x] On successful signup, user is navigated to HomeView.
- [x] Auth loading state shows ProgressView.
- [ ] As a user, I receive clear error messages and retry paths when auth fails.

### MVP Data Requirements Alignment
- [ ] As a new user, I can enter first name, last name, and email in the active onboarding path (currently collected in an unused `SignupFlowView`).
- [ ] As a product team, onboarding follows one canonical flow (either integrate `SignupFlowView` or remove/merge it) to avoid duplicated logic.

### Reflection Experience
- [ ] As a user, I see a personalized daily reflection generated server-side (Firebase Functions), not static placeholder copy.
- [ ] As a user, I get my first reflection immediately after signup with a brief setup-complete framing state.
- [ ] As a user, Home updates with real user-specific timing context from backend data.

### Guide & Navigation Completeness
- [ ] As a user, tapping “View my chart” performs real navigation (currently TODO).
- [ ] As a user, any chart/personal context destination has at least a minimal implemented screen.

### Data Quality & Reliability
- [ ] As a user, saves/loads provide success or failure feedback instead of silent failure.
- [ ] As a user, derived lunar birthday and zodiac are accurate or explicitly labeled as unavailable until accurate logic is implemented.
- [ ] As a user, profile and onboarding fields are validated consistently (required fields, formatting, edge cases).

### Notifications
- [ ] As a user, I can grant notification permission and receive daily reflections at my preferred time.
- [ ] As a user, notification scheduling respects local timezone and app settings.

### Testing & Readiness
- [ ] As a team, we have tests for auth flows (signup/login/logout), Firestore persistence, and end-to-end onboarding completion.
- [ ] As a team, we have UI tests for critical flows (onboarding completion, tab navigation, profile edits).
- [ ] As a team, analytics events are wired to a real analytics backend (not debug print stubs only).

## In Progress / Not Covered by Tests

- [ ] Firestore save failure handling
- [ ] Auth error state rendering
- [ ] Onboarding multi-select persistence validation

## Suggested Priority Order

1. Implement email/password + Apple auth in the active onboarding/login views.
2. Unify onboarding/signup into one canonical flow and capture all MVP required fields.
3. Ship backend-generated daily reflections and replace Home placeholders.
4. Complete first-run post-signup experience (setup complete + first reflection).
5. Finish chart CTA destination and harden data/error handling.
6. Add notification permission/scheduling and expand automated test coverage.

## Sprint-Ready Backlog

### P0 (Must Ship for MVP)

- [ ] **US-001: Email/Password Signup in active onboarding**
  - **Acceptance Criteria**
  - User can create an account from `AccountCreationView` using email/password.
  - On success, auth state updates and user is routed into main app.
  - On failure, user sees actionable error text and can retry.

- [ ] **US-002: Email/Password Login in active login view**
  - **Acceptance Criteria**
  - User can sign in from `LoginView` using email/password.
  - Invalid credentials surface a visible error.
  - Successful login routes to main app without relaunch.

- [ ] **US-003: Capture required MVP identity fields in canonical flow**
  - **Acceptance Criteria**
  - First name, last name, and email are collected in the same flow users currently use.
  - Required fields are validated before submit.
  - Data is saved to Firestore user record.

- [ ] **US-004: Unify onboarding into one canonical implementation**
  - **Acceptance Criteria**
  - Duplicate onboarding/signup logic is removed or merged (`OnboardingFlow` vs `SignupFlowView`).
  - One source of truth for step order and persistence.
  - No dead-end auth buttons remain in user-facing flow.

- [ ] **US-005: Replace Home placeholder with backend reflection payload**
  - **Acceptance Criteria**
  - Home fetches reflection content generated server-side.
  - Placeholder hardcoded reflection is removed from default path.
  - If backend is unavailable, user sees graceful fallback state.

- [ ] **US-006: First-run post-signup reflection experience**
  - **Acceptance Criteria**
  - Immediately after signup, user sees setup-complete framing and first reflection.
  - Flow occurs once for first run and does not repeat on later launches.

### P1 (Important Next)

- [ ] **US-007: Apple Sign In for signup and login**
  - **Acceptance Criteria**
  - Apple sign-in works from both account creation and login entry points.
  - Auth session persists across relaunch.
  - User cancellation and provider errors are handled cleanly.

- [ ] **US-008: Save/load reliability and explicit error states**
  - **Acceptance Criteria**
  - Firestore read/write errors are surfaced in UI.
  - Save button reflects pending/success/failure states.
  - Silent failure behavior is removed.

- [ ] **US-009: Chart CTA routes to real destination**
  - **Acceptance Criteria**
  - “View my chart” opens a concrete screen.
  - Destination has at least minimal meaningful content.
  - No TODO-only tap action remains.

- [ ] **US-010: Notification permission + schedule**
  - **Acceptance Criteria**
  - User can grant/deny local notifications.
  - Preferred time is used for daily schedule in local timezone.
  - Disabled toggle cancels scheduled notifications.

### P2 (Quality and Hardening)

- [ ] **US-011: Derived context correctness (lunar/zodiac)**
  - **Acceptance Criteria**
  - Derived fields are either accurate or explicitly unavailable.
  - “Approximate” placeholder logic is removed from production path.

- [ ] **US-012: Analytics production wiring**
  - **Acceptance Criteria**
  - Guide and key funnel events send to real analytics backend.
  - Debug print-only analytics paths are replaced for release builds.

- [ ] **US-013: Auth + onboarding + persistence test coverage**
  - **Acceptance Criteria**
  - Tests cover signup/login success and failure paths.
  - Tests cover onboarding completion and Firestore persistence.
  - At least one UI test validates critical onboarding happy path.

## Proposed Sprint Breakdown

### Sprint 1 (MVP unblock)
- US-001
- US-002
- US-003
- US-004

### Sprint 2 (Core product value)
- US-005
- US-006
- US-008

### Sprint 3 (Polish + growth)
- US-007
- US-009
- US-010
- US-011
- US-012
- US-013
