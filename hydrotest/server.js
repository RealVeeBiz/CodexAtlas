const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const express = require('express');
const cookieParser = require('cookie-parser');

const ROOT = __dirname;
const DATA_DIR = path.join(ROOT, 'data');
const QUESTIONS_FILE = path.join(DATA_DIR, 'questions.json');
const RESULTS_FILE = path.join(DATA_DIR, 'results.json');
const SESSIONS_FILE = path.join(DATA_DIR, 'sessions.json');

function loadEnvFile() {
  const envPath = path.join(ROOT, '.env');
  if (!fs.existsSync(envPath)) return;
  const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (!(key in process.env)) process.env[key] = value;
  }
}

loadEnvFile();

const PORT = Number(process.env.PORT || 3000);
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'hydroadmin';
const QUESTIONS_PER_TEST = Number(process.env.QUESTIONS_PER_TEST || 8);
const PASS_PERCENT = Number(process.env.PASS_PERCENT || 70);
const SESSION_TTL_MS = 2 * 60 * 60 * 1000;

const app = express();
app.use(express.json({ limit: '1mb' }));
app.use(cookieParser());
app.use(express.static(path.join(ROOT, 'public')));

function readJson(file, fallback) {
  try {
    if (!fs.existsSync(file)) return fallback;
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return fallback;
  }
}

function writeJson(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
}

function loadQuestions() {
  const data = readJson(QUESTIONS_FILE, []);
  return Array.isArray(data) ? data : [];
}

function saveQuestions(list) {
  writeJson(QUESTIONS_FILE, list);
}

function loadResults() {
  const data = readJson(RESULTS_FILE, []);
  return Array.isArray(data) ? data : [];
}

function saveResult(entry) {
  const results = loadResults();
  results.unshift(entry);
  writeJson(RESULTS_FILE, results.slice(0, 500));
}

/** @type {Map<string, { name: string, key: Record<string, number>, total: number, createdAt: number }>} */
const sessions = new Map();

function pruneSessions() {
  const now = Date.now();
  for (const [id, session] of sessions) {
    if (now - session.createdAt > SESSION_TTL_MS) sessions.delete(id);
  }
}

function shuffle(list) {
  const t = [...list];
  for (let i = t.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [t[i], t[j]] = [t[j], t[i]];
  }
  return t;
}

function newId(prefix = 'q') {
  return `${prefix}${Date.now().toString(36)}${crypto.randomBytes(2).toString('hex')}`;
}

function sanitizeQuestion(input, existingId) {
  if (!input || typeof input !== 'object') return { error: 'Données invalides.' };
  const question = String(input.question || '').trim();
  if (!question) return { error: 'La question est requise.' };

  if (!Array.isArray(input.answers) || input.answers.length < 2) {
    return { error: 'Au moins 2 réponses sont requises.' };
  }

  const answers = [];
  for (let i = 0; i < input.answers.length; i += 1) {
    const text = String(input.answers[i] || '').trim();
    if (!text) return { error: `Réponse #${i + 1} vide.` };
    answers.push(text);
  }

  const correct = Number(input.correct);
  if (!Number.isInteger(correct) || correct < 0 || correct >= answers.length) {
    return { error: 'Index de bonne réponse invalide.' };
  }

  return {
    question: {
      id: existingId || (input.id ? String(input.id) : newId()),
      category: String(input.category || 'Général').trim() || 'Général',
      question,
      answers,
      correct,
      active: input.active !== false,
    },
  };
}

function isAdmin(req) {
  return req.cookies && req.cookies.hydro_admin === '1';
}

function requireAdmin(req, res, next) {
  if (!isAdmin(req)) {
    return res.status(401).json({ error: 'Non autorisé.' });
  }
  return next();
}

app.get('/api/config', (_req, res) => {
  res.json({
    title: 'Hydro-Québec',
    subtitle: 'Test de compétence',
    questionsPerTest: QUESTIONS_PER_TEST,
    passPercent: PASS_PERCENT,
  });
});

app.post('/api/test/start', (req, res) => {
  pruneSessions();
  const name = String(req.body?.name || '').trim();
  if (name.length < 2) {
    return res.status(400).json({ error: 'Entrez votre nom pour commencer.' });
  }

  const pool = loadQuestions().filter((q) => q.active !== false);
  if (pool.length === 0) {
    return res.status(400).json({ error: 'Aucune question active.' });
  }

  const count = Math.min(QUESTIONS_PER_TEST, pool.length);
  const selected = shuffle(pool).slice(0, count);
  const key = {};
  const questions = selected.map((q) => {
    const paired = shuffle(
      (q.answers || []).map((text, i) => ({ text, original: i }))
    );
    const answers = paired.map((p) => p.text);
    const correctIndex = paired.findIndex((p) => p.original === Number(q.correct));
    key[q.id] = correctIndex;
    return {
      id: q.id,
      category: q.category || '',
      question: q.question,
      answers,
    };
  });

  const sessionId = newId('s');
  sessions.set(sessionId, {
    name,
    key,
    total: questions.length,
    createdAt: Date.now(),
  });

  res.json({
    sessionId,
    candidateName: name,
    passPercent: PASS_PERCENT,
    questions,
  });
});

app.post('/api/test/submit', (req, res) => {
  pruneSessions();
  const sessionId = String(req.body?.sessionId || '');
  const answers = req.body?.answers || {};
  const session = sessions.get(sessionId);
  if (!session) {
    return res.status(400).json({ error: 'Session expirée. Recommencez le test.' });
  }

  let correct = 0;
  for (const [id, expected] of Object.entries(session.key)) {
    if (Number(answers[id]) === Number(expected)) correct += 1;
  }

  const total = session.total;
  const percent = total > 0 ? Math.round((correct / total) * 100) : 0;
  const passed = percent >= PASS_PERCENT;

  const result = {
    id: newId('r'),
    name: session.name,
    correct,
    total,
    percent,
    passed,
    passPercent: PASS_PERCENT,
    at: new Date().toISOString(),
  };

  sessions.delete(sessionId);
  saveResult(result);

  res.json({
    result,
    message: passed
      ? 'Félicitations — certification Hydro-Québec réussie.'
      : 'Échec du test. Révisez le matériel et réessayez.',
  });
});

app.post('/api/admin/login', (req, res) => {
  const password = String(req.body?.password || '');
  if (password !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'Mot de passe incorrect.' });
  }
  res.cookie('hydro_admin', '1', {
    httpOnly: true,
    sameSite: 'lax',
    maxAge: 12 * 60 * 60 * 1000,
  });
  res.json({ ok: true });
});

app.post('/api/admin/logout', (req, res) => {
  res.clearCookie('hydro_admin');
  res.json({ ok: true });
});

app.get('/api/admin/me', (req, res) => {
  res.json({ admin: isAdmin(req) });
});

app.get('/api/admin/questions', requireAdmin, (_req, res) => {
  res.json({ questions: loadQuestions() });
});

app.post('/api/admin/questions', requireAdmin, (req, res) => {
  const questions = loadQuestions();
  const incoming = req.body?.question || req.body;
  const existingId = incoming?.id ? String(incoming.id) : null;
  const found = existingId ? questions.find((q) => q.id === existingId) : null;
  const { question, error } = sanitizeQuestion(incoming, found ? found.id : null);
  if (error) return res.status(400).json({ error });

  if (found) {
    const idx = questions.findIndex((q) => q.id === found.id);
    questions[idx] = question;
  } else {
    questions.push(question);
  }

  saveQuestions(questions);
  res.json({ questions, question });
});

app.delete('/api/admin/questions/:id', requireAdmin, (req, res) => {
  const id = String(req.params.id || '');
  const before = loadQuestions();
  const questions = before.filter((q) => q.id !== id);
  if (questions.length === before.length) {
    return res.status(404).json({ error: 'Question introuvable.' });
  }
  saveQuestions(questions);
  res.json({ questions });
});

app.get('/api/admin/results', requireAdmin, (_req, res) => {
  res.json({ results: loadResults() });
});

app.get('/admin', (_req, res) => {
  res.sendFile(path.join(ROOT, 'public', 'admin.html'));
});

app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api/')) return next();
  res.sendFile(path.join(ROOT, 'public', 'index.html'));
});

if (!fs.existsSync(QUESTIONS_FILE)) {
  writeJson(QUESTIONS_FILE, []);
}
if (!fs.existsSync(RESULTS_FILE)) {
  writeJson(RESULTS_FILE, []);
}

app.listen(PORT, () => {
  console.log(`Hydro-Québec test → http://localhost:${PORT}`);
  console.log(`Admin             → http://localhost:${PORT}/admin`);
  console.log(`Questions         → ${loadQuestions().length}`);
});
