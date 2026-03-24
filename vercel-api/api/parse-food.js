const admin = require('firebase-admin');

function initFirebase() {
  if (admin.apps.length) return;
  const sa = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!sa) throw new Error('FIREBASE_SERVICE_ACCOUNT env var is missing');
  let serviceAccount;
  try {
    serviceAccount = JSON.parse(sa);
  } catch {
    throw new Error('FIREBASE_SERVICE_ACCOUNT is not valid JSON');
  }
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const DAILY_LIMIT = 10;
const MAX_INPUT_LENGTH = 500;

const SYSTEM_PROMPT =
  'You are a nutrition assistant. When given food input, respond ONLY with valid JSON. ' +
  'If input contains specific foods with clear portions, respond with a JSON array: ' +
  '[{"name": string, "calories": int, "protein": int, "carbs": int, "fat": int}]. ' +
  'If details are missing, ask exactly ONE combined question covering all unknowns at once ' +
  '(portion size, preparation method, type — whatever is needed): ' +
  '{"clarify": "your single combined question with examples"}. ' +
  'IMPORTANT: If any prior messages exist in the conversation, NEVER ask another question — ' +
  'always return the JSON array using your best estimate from the available context. ' +
  'If the user says they don\'t know (e.g. "not sure", "I don\'t know", "maybe"), use a typical average value ' +
  'and append " (estimate)" to the food name in your response. ' +
  'If the user provides their own calorie count (e.g. "it says 240 kcal on the label", "about 300 calories"), ' +
  'use that exact number and do not override it. ' +
  'If the input is too vague to identify any food (e.g. "had lunch", "ate something"), ask what food they had. ' +
  'No explanation, no markdown, no code fences, just raw JSON.';

function todayKey() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

module.exports = async function handler(req, res) {
  // CORS — needed for mobile HTTP calls
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  // Init Firebase inside handler so errors are catchable
  try {
    initFirebase();
  } catch (e) {
    console.error('Firebase init error:', e.message);
    return res.status(500).json({ error: 'Firebase init failed: ' + e.message });
  }

  // 1. Auth check
  const authHeader = req.headers['authorization'];
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing auth token' });
  }

  let uid;
  try {
    const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
    uid = decoded.uid;
  } catch {
    return res.status(401).json({ error: 'Invalid auth token' });
  }

  // 2. Input validation — support single input or multi-turn messages array
  const input = req.body?.input;
  const messages = req.body?.messages; // optional: [{role, content}, ...]

  if (!messages) {
    const trimmed = (input || '').trim();
    if (!trimmed) return res.status(400).json({ error: 'Input is empty' });
    if (trimmed.length > MAX_INPUT_LENGTH) {
      return res.status(400).json({ error: 'Input too long (max 500 characters)' });
    }
  }

  const claudeMessages = messages || [{ role: 'user', content: input.trim() }];

  // 3. Daily usage check + increment using a transaction
  const db = admin.firestore();
  const dayKey = todayKey();
  const usageRef = db.collection('users').doc(uid).collection('usage').doc('daily');

  let callsUsed;
  try {
    callsUsed = await db.runTransaction(async (t) => {
      const snap = await t.get(usageRef);
      const data = snap.exists ? snap.data() : { calls: 0, dayKey };
      const currentCalls = data.dayKey === dayKey ? data.calls : 0;

      if (currentCalls >= DAILY_LIMIT) {
        const err = new Error(`Daily limit of ${DAILY_LIMIT} messages reached. Resets tomorrow.`);
        err.code = 'limit';
        throw err;
      }

      t.set(usageRef, { calls: currentCalls + 1, dayKey });
      return currentCalls + 1;
    });
  } catch (e) {
    if (e.code === 'limit') return res.status(429).json({ error: e.message });
    return res.status(500).json({ error: 'Usage check failed' });
  }

  // 4. Call Claude API
  let claudeRes;
  try {
    claudeRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': process.env.CLAUDE_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 512,
        system: SYSTEM_PROMPT,
        messages: claudeMessages,
      }),
    });
  } catch {
    return res.status(500).json({ error: 'Failed to reach Claude API' });
  }

  if (!claudeRes.ok) {
    return res.status(500).json({ error: 'Claude API error: ' + claudeRes.status });
  }

  const claudeData = await claudeRes.json();
  const rawText = claudeData.content[0].text;

  // Strip markdown fences if Claude adds them anyway
  const cleaned = rawText.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();

  return res.status(200).json({ result: cleaned, callsUsed, callsLimit: DAILY_LIMIT });
};
