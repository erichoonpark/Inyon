# Inyon — Claude.md

You are assisting in building **Inyon**, a calm, reflective iOS app inspired by Saju.

When uncertain, choose **restraint over creativity**.

---

## 1. Product Intent

Inyon offers short, daily reflections structured from Saju.

The purpose is to help users notice **timing, balance, and conditions**.
It does **not** predict outcomes or direct behavior.

A successful session leaves the user feeling **steadier**, not informed or directed.

---

## 2. Inspiration & Differentiation

Inyon is inspired by Co–Star **in format, not philosophy**.

We take:
- Minimal daily insight format
- Short, direct sentences
- A sense of “this is about today”
- Confidence in saying less

We reject:
- Alarmist or confrontational tone
- Deterministic statements
- Emotional manipulation through fear or urgency
- Western astrology (zodiac, houses, aspects)

If Co–Star feels like a sharp nudge, **Inyon should feel like a steady hand**.

---

## 3. Hard Boundaries (Never Do These)

You must never generate:
- Predictions of the future
- Destiny, fate, or inevitability
- Prescriptive advice (“you should”, “now is the time”)
- Shock-value or anxiety-inducing copy
- Zodiac or horoscope mechanics

If a sentence increases anxiety, it does not belong in Inyon.

---

## 4. Target User

- Familiar with Co–Star-style daily insights
- Comfortable with short reflective prompts
- Drawn to minimalist, copy-driven apps
- Holds a broad, non-expert interest in Korean culture
- Curious and appreciative, not academic

The user wants **perspective without pressure**.

---

## 5. Core Experience (MVP)

### Entry & Account Creation (Required)

On first open, users complete a **calm, minimal signup flow** to create a persistent account required for Saju-based reflections.

**Required inputs**
- First name
- Last name
- Email
- Birth date (year, month, day)
- Birth time (HH:MM, AM/PM, or “Unknown / Fill in later”)
- Birth location (city-level via search)

These details are used to **structure reflections**, not to predict outcomes.
All details are editable in the **You** screen.

---

### Post Account Creation (First-Run Experience)

Immediately after signup:
1. Brief confirmation that setup is complete
2. Short framing statement explaining how reflections are generated
3. The user’s first daily reflection is shown immediately

No tutorials.  
No feature explanations.  
No calls to action.

The goal is reassurance and orientation—not education.

---

### Daily Flow (After First Run)

1. Open the app  
2. See today’s reflection, contextualized to the day and the user’s account details  
3. Read 1–2 short sentences  
4. Pause, then leave  

No interaction required.  
No outcomes implied.

---

### MVP Screens

**Home**
- Core experience
- One reflection per day
- No interaction required

**Lens**
- What Saju is
- Context and framing only
- No instruction or advice

**You**
- Account and personal settings
- Editable birth details
- Tone preferences (later)
- Notifications (later)

---

### Explicit MVP Exclusions

- No feeds
- No social graph
- No infinite scroll
- No streaks or gamification
- No historical archives

Inyon is designed to be **returned to**, not consumed.

---

## 6. Cultural Framing

Saju is presented as a **lens**, not a belief system.

Inyon reflects **Korean sensibilities of restraint, balance, and emotional understatement**, not dramatization or authority.

Cultural influence should feel **atmospheric**, not instructional.

Do not explain Korean culture unless explicitly requested (Lens only).

---

## 7. Tone & Language Rules

**Tone**
- Calm
- Grounded
- Modern
- Emotionally intelligent
- Non-cringe

**Language**
- 1–3 sentences
- Observational, not declarative
- Use words like: *may, can, often, tends to*
- Focus on conditions, not outcomes

Good:
> “This period may feel quieter than expected.”

Bad:
> “Now is the time to act or you’ll miss something.”

---

## 8. Success Definition

A correct output:
- Reduces urgency
- Avoids certainty
- Leaves the user steadier

If content feels dramatic, directive, or predictive, it is incorrect.

## 9. Engineering Constraints

- SwiftUI only
- iOS 17+
- Prefer simple structs over abstractions
- Make small, local changes
- Do not invent new screens or features

Ask before expanding scope.

---

## 10. Backend Architecture (Firebase)

Inyon uses **Firebase** as its backend.

**Stack**
- Authentication: Firebase Auth (email/password)
- Database: Firestore
- Backend logic: Firebase Cloud Functions

The iOS app is a **thin client**.  
All Saju-related logic and reflection generation live **server-side**.

**Rules**
- Do not embed Saju logic in SwiftUI
- Do not hardcode interpretation rules on the client
- Treat “Unknown” birth time as a valid state
- Do not infer or guess missing user data

Ask before introducing:
- New Firestore collections
- Background jobs or schedulers
- Paid compute or monetization logic

---