import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import OpenAI from "openai";
import {validateInsightText} from "./validators";

initializeApp();
const db = getFirestore();
const openaiApiKey = defineSecret("OPENAI_API_KEY");

// Heavenly Stems cycle (10 stems, repeating)
const HEAVENLY_STEMS = [
  "Gab (甲)", "Eul (乙)", "Byeong (丙)", "Jeong (丁)", "Mu (戊)",
  "Gi (己)", "Gyeong (庚)", "Sin (辛)", "Im (壬)", "Gye (癸)",
];

// Earthly Branches cycle (12 branches, repeating)
const EARTHLY_BRANCHES = [
  "Ja (子)", "Chuk (丑)", "In (寅)", "Myo (卯)", "Jin (辰)", "Sa (巳)",
  "O (午)", "Mi (未)", "Sin (申)", "Yu (酉)", "Sul (戌)", "Hae (亥)",
];

// Five elements mapped to Heavenly Stems
const STEM_ELEMENTS: Record<number, string> = {
  0: "Wood", 1: "Wood", // Gab, Eul
  2: "Fire", 3: "Fire", // Byeong, Jeong
  4: "Earth", 5: "Earth", // Mu, Gi
  6: "Metal", 7: "Metal", // Gyeong, Sin
  8: "Water", 9: "Water", // Im, Gye
};

const ELEMENT_THEMES: Record<string, string> = {
  Wood: "growth, flexibility, vision",
  Fire: "warmth, clarity, expression",
  Earth: "stability, nourishment, grounding",
  Metal: "precision, refinement, letting go",
  Water: "flow, depth, adaptation",
};

// Generating cycle: each element produces the next
const ELEMENT_GENERATES: Record<string, string> = {
  Wood: "Fire", Fire: "Earth", Earth: "Metal", Metal: "Water", Water: "Wood",
};

// Controlling cycle: each element restrains the target
const ELEMENT_CONTROLS: Record<string, string> = {
  Wood: "Earth", Earth: "Water", Water: "Fire", Fire: "Metal", Metal: "Wood",
};

// Zodiac animals aligned to Earthly Branch cycle (1900 = Rat)
const ZODIAC_ANIMALS = [
  "Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
  "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig",
];

/**
 * Returns the approximate zodiac animal for a birth year.
 * Approximate — does not account for Lunar New Year boundary.
 */
function getBirthZodiac(birthDate: Date): string {
  const year = birthDate.getUTCFullYear();
  const index = ((year - 1900) % 12 + 12) % 12;
  return ZODIAC_ANIMALS[index];
}

/**
 * Describes the relationship of a birth element to today's element
 * from the perspective of the person (how today's energy meets them).
 */
function getElementRelationship(birthEl: string, dayEl: string): string {
  if (birthEl === dayEl) return "resonates with";
  if (ELEMENT_GENERATES[birthEl] === dayEl) return "feeds into";
  if (ELEMENT_GENERATES[dayEl] === birthEl) return "is nourished by";
  if (ELEMENT_CONTROLS[birthEl] === dayEl) return "tempers";
  if (ELEMENT_CONTROLS[dayEl] === birthEl) return "is challenged by";
  return "meets";
}

/**
 * Calculate the day's Heavenly Stem and Earthly Branch index
 * using the standard sexagenary cycle. The reference date is
 * January 1, 1900 which was day Gab-Ja (index 0).
 */
function calculateDayStemBranch(dateStr: string): {
  stemIndex: number;
  branchIndex: number;
} {
  const referenceDate = new Date("1900-01-01T00:00:00Z");
  const targetDate = new Date(dateStr + "T00:00:00Z");
  const diffMs = targetDate.getTime() - referenceDate.getTime();
  const daysDiff = Math.round(diffMs / (1000 * 60 * 60 * 24));

  const stemIndex = ((daysDiff % 10) + 10) % 10;
  const branchIndex = ((daysDiff % 12) + 12) % 12;

  return {stemIndex, branchIndex};
}

interface InsightResponse {
  insightText: string;
}

export const getDailyInsight = onCall(
  {secrets: [openaiApiKey], region: "us-central1"},
  async (request) => {
    // Auth required
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const {timeZoneId, localDate} = request.data;

    if (!timeZoneId || !localDate) {
      throw new HttpsError(
        "invalid-argument",
        "timeZoneId and localDate are required."
      );
    }

    // Validate date format
    if (!/^\d{4}-\d{2}-\d{2}$/.test(localDate)) {
      throw new HttpsError(
        "invalid-argument",
        "localDate must be YYYY-MM-DD format."
      );
    }

    // Reject dates more than 2 days from today to prevent historical abuse.
    // ±2 days covers all UTC offsets (max is UTC+14 / UTC-12 = 26 hours apart).
    const todayMs = Date.now();
    const requestedMs = new Date(localDate + "T00:00:00Z").getTime();
    const diffDays = Math.abs(todayMs - requestedMs) / (1000 * 60 * 60 * 24);
    if (diffDays > 2) {
      throw new HttpsError(
        "invalid-argument",
        "localDate must be within 2 days of today."
      );
    }

    // Sanitize timezone for use as Firestore doc ID (slashes are path separators)
    const safeTimeZoneId = timeZoneId.replace(/\//g, "~");
    const docId = `${localDate}_${safeTimeZoneId}`;
    const docRef = db
      .collection("users")
      .doc(uid)
      .collection("dailyInsights")
      .doc(docId);

    // Check cache
    const cached = await docRef.get();
    if (cached.exists) {
      const data = cached.data()!;
      return {
        localDate: data.localDate,
        timeZoneId: data.timeZoneId,
        dayElement: data.dayElement,
        elementTheme: data.elementTheme,
        heavenlyStem: data.heavenlyStem,
        earthlyBranch: data.earthlyBranch,
        insightText: data.insightText,
        generatedAt: data.generatedAt?.toMillis() ?? Date.now(),
        version: data.version,
      };
    }

    // Calculate Saju day data
    const {stemIndex, branchIndex} = calculateDayStemBranch(localDate);
    const heavenlyStem = HEAVENLY_STEMS[stemIndex];
    const earthlyBranch = EARTHLY_BRANCHES[branchIndex];
    const dayElement = STEM_ELEMENTS[stemIndex];
    const elementTheme = ELEMENT_THEMES[dayElement];

    // Load user birth context for personalization
    const onboardingDoc = await db
      .collection("users")
      .doc(uid)
      .get();

    let birthContext = "";
    if (onboardingDoc.exists) {
      const obData = onboardingDoc.data()!;
      if (obData.birthDate) {
        const bd = obData.birthDate.toDate();
        const birthStem = calculateDayStemBranch(
          bd.toISOString().split("T")[0]
        );
        const birthElement = STEM_ELEMENTS[birthStem.stemIndex];
        const birthTheme = ELEMENT_THEMES[birthElement];
        const zodiac = getBirthZodiac(bd);
        const relationship = getElementRelationship(birthElement, dayElement);
        birthContext =
          `Birth element: ${birthElement} (${birthTheme})\n` +
          `Birth zodiac: ${zodiac} year\n` +
          `Their ${birthElement} nature ${relationship} today's ${dayElement} energy — ` +
          `let this dynamic inform the reflection naturally.`;

        const anchors: string[] = Array.isArray(obData.personalAnchors)
          ? obData.personalAnchors
          : [];
        if (anchors.length > 0) {
          birthContext +=
            `\nUser's current focus areas: ${anchors.join(", ")}. ` +
            `Subtly let these inform the reflection if natural — don't name them.`;
        }
      }
    }

    // Generate insight via OpenAI with timeout and retry
    const openai = new OpenAI({apiKey: openaiApiKey.value()});

    const prompt = `You are Inyon — a dry, precise voice shaped by Korean Saju.
Not mystical. Not a wellness app. Just honest about what you notice.

Today's Saju:
- Date: ${localDate}
- Heavenly Stem: ${heavenlyStem}
- Earthly Branch: ${earthlyBranch}
- Element: ${dayElement} — ${elementTheme}
${birthContext ? `\nUser context:\n${birthContext}` : ""}

Write one daily insight. Follow every rule:

STRUCTURE
1. 1–2 sentences. Total: 10–22 words.
2. Sentence 1 is a declarative observation — state what you notice, as if you've been watching. No hedge required. This is the line someone screenshots.
3. Sentence 2 (optional): one quiet lean. A door barely open. Hedge allowed here.

TONE
4. Dry. Like a friend who sees you clearly and doesn't soften it.
5. Specific enough to feel slightly uncomfortable — not alarming, just close.
6. Gen Z / millennial register. Not corporate, not spiritual.
7. Let the Saju context shape what you notice — never name the Saju terms.

EXAMPLES (aim for this quality)
Good: "The plan you've been sitting on is starting to look like a wall."
Good: "You've been carrying the conversation that hasn't happened yet."
Good: "Your calendar has more room than your head thinks it does."
Good: "There's an answer you already have but haven't said out loud."
Bad: "Things may feel a bit uncertain right now." — too vague, no character
Bad: "You might want to check in with yourself today." — sounds like a wellness app

BANNED WORDS — never use any of these:
- Saju terms: element, stem, branch, zodiac, birth element, day's element
- Wellness filler: energy, vibes, vibe, universe, flow, alignment, resonance, synergy, journey, path, forces, cosmic, spirit, higher, meant to be
- Vague: shift, dynamic

SAFETY
8. No predictions about future outcomes. No advice. No "you should" or "now is the time".
9. No fear. No urgency. No drama.
10. Observations about current state are fine — they don't need hedging.

Respond with only valid JSON: {"insightText": "..."}`;

    const maxRetries = 2;
    let parsed: InsightResponse | null = null;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 25000);

        const completion = await openai.chat.completions.create(
          {
            model: "gpt-4o-mini",
            messages: [{role: "user", content: prompt}],
            response_format: {type: "json_object"},
            temperature: 0.85,
            max_tokens: 150,
          },
          {signal: controller.signal}
        );

        clearTimeout(timeoutId);

        const content = completion.choices[0]?.message?.content;
        if (!content) {
          throw new Error("Empty response from model.");
        }

        parsed = JSON.parse(content) as InsightResponse;

        if (!parsed.insightText || typeof parsed.insightText !== "string") {
          throw new Error("Reflection content is missing or wrong type.");
        }
        const validation = validateInsightText(parsed.insightText);
        if (!validation.valid) {
          throw new Error(
            `Reflection failed validation: ${validation.errors.join("; ")}`
          );
        }

        break; // Success — exit retry loop
      } catch (err: unknown) {
        const isLastAttempt = attempt === maxRetries;
        const error = err instanceof Error ? err : new Error(String(err));

        if (isLastAttempt) {
          if (error.name === "AbortError") {
            throw new HttpsError(
              "deadline-exceeded",
              "Reflection generation timed out."
            );
          }
          throw new HttpsError("internal", "Failed to generate reflection.");
        }

        // Wait before retrying (exponential backoff: 1s, 2s)
        await new Promise((resolve) =>
          setTimeout(resolve, Math.pow(2, attempt) * 1000)
        );
      }
    }

    if (!parsed) {
      throw new HttpsError("internal", "Failed to generate reflection.");
    }

    const version = "v2";
    const generatedAt = Timestamp.now();

    // Persist to Firestore
    const payload = {
      localDate,
      timeZoneId,
      dayElement,
      elementTheme,
      heavenlyStem,
      earthlyBranch,
      insightText: parsed!.insightText,
      generatedAt,
      version,
      source: "generated",
    };

    await docRef.set(payload);

    return {
      ...payload,
      generatedAt: generatedAt.toMillis(),
    };
  }
);
