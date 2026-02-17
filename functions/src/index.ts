import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import OpenAI from "openai";

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
  Wood: "Growth, flexibility, vision",
  Fire: "Warmth, clarity, expression",
  Earth: "Stability, nourishment, grounding",
  Metal: "Precision, refinement, letting go",
  Water: "Flow, depth, adaptation",
};

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

    // Sanitize timezone for use as Firestore doc ID (slashes are path separators)
    const safeTimeZoneId = timeZoneId.replace(/\//g, "-");
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
      .collection("onboarding")
      .doc("context")
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
        birthContext =
          `The user's birth element is ${birthElement}. ` +
          `Today's element is ${dayElement}. ` +
          `Consider the relationship between these elements.`;
      }
    }

    // Generate insight via OpenAI
    const openai = new OpenAI({apiKey: openaiApiKey.value()});

    const prompt = `You are Inyon, a calm reflective app grounded in Korean Saju tradition.

Today's Saju day data:
- Date: ${localDate}
- Day Element: ${dayElement} (${elementTheme})
- Heavenly Stem: ${heavenlyStem}
- Earthly Branch: ${earthlyBranch}
${birthContext ? `\nUser context:\n- ${birthContext}` : ""}

Write a daily reflection for the user. Rules:
1. Exactly 3-4 sentences.
2. Reflective, calm, non-prescriptive tone.
3. Mention the day's energetic tendency, not prediction.
4. Use hedging language: "may", "can", "tends to", "often".
5. Never predict outcomes, give advice, or use directive language.
6. Never mention medical, legal, or financial topics.
7. Never use fear-based or urgent language.
8. The reflection should leave the reader feeling steadier.

Respond with only valid JSON in this format:
{"insightText": "Your 3-4 sentence reflection here."}`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{role: "user", content: prompt}],
      response_format: {type: "json_object"},
      temperature: 0.7,
      max_tokens: 300,
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new HttpsError("internal", "Failed to generate reflection.");
    }

    let parsed: InsightResponse;
    try {
      parsed = JSON.parse(content) as InsightResponse;
    } catch {
      throw new HttpsError("internal", "Invalid response from model.");
    }

    if (
      !parsed.insightText ||
      typeof parsed.insightText !== "string" ||
      parsed.insightText.length < 20
    ) {
      throw new HttpsError("internal", "Reflection content is invalid.");
    }

    const version = "v1";
    const generatedAt = Timestamp.now();

    // Persist to Firestore
    const payload = {
      localDate,
      timeZoneId,
      dayElement,
      elementTheme,
      heavenlyStem,
      earthlyBranch,
      insightText: parsed.insightText,
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
