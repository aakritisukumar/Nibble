const { setGlobalOptions } = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ maxInstances: 10, region: "asia-south1" });

const claudeApiKey = defineSecret("CLAUDE_API_KEY");

const DAILY_LIMIT = 10;
const MAX_INPUT_LENGTH = 500;

const SYSTEM_PROMPT =
  'You are a nutrition assistant. When given food input, respond ONLY with valid JSON. ' +
  'If input contains specific foods, respond with a JSON array: ' +
  '[{"name": string, "calories": int, "protein": int, "carbs": int, "fat": int}]. ' +
  'If the input is too vague to estimate (e.g. "had lunch", "ate something"), ' +
  'respond with a JSON object: {"clarify": "your follow-up question asking for specifics"}. ' +
  'No explanation, no markdown, no code fences, just raw JSON.';

// dateKey format: "2026-03-22" — resets automatically each day
function todayKey() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

exports.parseFood = onCall(
  { secrets: [claudeApiKey] },
  async (request) => {
    // 1. Auth check
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const uid = request.auth.uid;
    const userInput = (request.data.input || "").trim();

    // 2. Input validation
    if (!userInput) {
      throw new HttpsError("invalid-argument", "Input is empty.");
    }
    if (userInput.length > MAX_INPUT_LENGTH) {
      throw new HttpsError("invalid-argument", "Input too long (max 500 characters).");
    }

    // 3. Usage check + increment using a transaction (prevents race conditions)
    const db = admin.firestore();
    const dayKey = todayKey();
    const usageRef = db
      .collection("users").doc(uid)
      .collection("usage").doc("daily");

    let callsUsed;
    try {
      callsUsed = await db.runTransaction(async (t) => {
        const snap = await t.get(usageRef);
        const data = snap.exists ? snap.data() : { calls: 0, dayKey };

        // Reset counter if it's a new day
        const currentCalls = data.dayKey === dayKey ? data.calls : 0;

        if (currentCalls >= DAILY_LIMIT) {
          throw new HttpsError(
            "resource-exhausted",
            `Daily limit of ${DAILY_LIMIT} messages reached. Resets tomorrow.`
          );
        }

        t.set(usageRef, { calls: currentCalls + 1, dayKey });
        return currentCalls + 1;
      });
    } catch (e) {
      // Re-throw HttpsErrors directly (limit reached), wrap others
      if (e instanceof HttpsError) throw e;
      throw new HttpsError("internal", "Usage check failed.");
    }

    // 4. Call Claude API
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": claudeApiKey.value(),
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 512,
        system: SYSTEM_PROMPT,
        messages: [{ role: "user", content: userInput }],
      }),
    });

    if (!response.ok) {
      throw new HttpsError("internal", "Claude API error: " + response.status);
    }

    const result = await response.json();
    const rawText = result.content[0].text;

    // Strip markdown fences if Claude adds them anyway
    const cleaned = rawText
      .replace(/```json\s*/g, "")
      .replace(/```\s*/g, "")
      .trim();

    return {
      result: cleaned,
      callsUsed,
      callsLimit: DAILY_LIMIT,
    };
  }
);
