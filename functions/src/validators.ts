export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

export const BANNED_WORDS = [
  // Saju terms — must not appear in output
  "element", "stem", "branch", "zodiac",
  "birth element", "day's element",
  // Wellness filler
  "energy", "vibes", "vibe", "universe", "flow", "alignment",
  "resonance", "synergy", "journey", "path", "forces", "cosmic",
  "spirit", "spirits", "higher", "meant to be",
  // Vague connectives
  "shift", "shifts", "dynamic", "dynamics",
];

export function countWords(text: string): number {
  return text.trim().split(/\s+/).filter((w) => w.length > 0).length;
}

export function countSentences(text: string): number {
  return text.split(/[.!?]+(?:\s|$)/).filter((s) => s.trim().length > 0).length;
}

export function validateInsightText(text: string): ValidationResult {
  const errors: string[] = [];

  const words = countWords(text);
  if (words < 25) errors.push(`Too short: ${words} words (min 25)`);
  if (words > 45) errors.push(`Too long: ${words} words (max 45)`);

  const sentences = countSentences(text);
  if (sentences !== 2) errors.push(`Expected 2 sentences, got ${sentences}`);

  const lower = text.toLowerCase();
  const found = BANNED_WORDS.filter((w) => lower.includes(w.toLowerCase()));
  if (found.length > 0) errors.push(`Banned words found: ${found.join(", ")}`);

  return {valid: errors.length === 0, errors};
}
