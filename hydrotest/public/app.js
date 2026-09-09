(() => {
  const toastEl = document.getElementById('toast');
  const views = {
    welcome: document.getElementById('view-welcome'),
    test: document.getElementById('view-test'),
    result: document.getElementById('view-result'),
  };

  let state = {
    sessionId: null,
    questions: [],
    index: 0,
    answers: {},
    candidateName: '',
    passPercent: 70,
  };

  async function api(path, options = {}) {
    const res = await fetch(path, {
      headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
      credentials: 'same-origin',
      ...options,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const err = new Error(data.error || 'Erreur réseau');
      err.status = res.status;
      throw err;
    }
    return data;
  }

  function showToast(message, type = 'info') {
    if (!message) return;
    toastEl.textContent = message;
    toastEl.classList.remove('hidden', 'is-error', 'is-success');
    if (type === 'error') toastEl.classList.add('is-error');
    if (type === 'success') toastEl.classList.add('is-success');
    toastEl.classList.add('is-visible');
    window.clearTimeout(showToast._t);
    showToast._t = window.setTimeout(() => toastEl.classList.remove('is-visible'), 2600);
  }

  function showView(name) {
    Object.entries(views).forEach(([key, el]) => {
      el.classList.toggle('hidden', key !== name);
    });
  }

  function renderQuestion() {
    const q = state.questions[state.index];
    if (!q) return;

    const card = document.querySelector('.question-card');
    card.style.animation = 'none';
    card.offsetHeight;
    card.style.animation = '';

    document.getElementById('q-category').textContent = q.category || 'Général';
    document.getElementById('q-text').textContent = q.question || '';
    document.getElementById('progress-current').textContent = String(state.index + 1);
    document.getElementById('progress-fill').style.width =
      `${((state.index + 1) / Math.max(state.questions.length, 1)) * 100}%`;

    const box = document.getElementById('q-answers');
    box.innerHTML = '';
    (q.answers || []).forEach((text, i) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'answer';
      btn.textContent = text;
      if (state.answers[q.id] === i) btn.classList.add('is-selected');
      btn.addEventListener('click', () => {
        state.answers[q.id] = i;
        box.querySelectorAll('.answer').forEach((el) => el.classList.remove('is-selected'));
        btn.classList.add('is-selected');
      });
      box.appendChild(btn);
    });

    document.getElementById('btn-prev').disabled = state.index === 0;
    document.getElementById('btn-next').textContent =
      state.index >= state.questions.length - 1 ? 'Soumettre' : 'Suivant';
  }

  function openTest(payload) {
    state.sessionId = payload.sessionId;
    state.questions = payload.questions || [];
    state.index = 0;
    state.answers = {};
    state.candidateName = payload.candidateName || '';
    state.passPercent = payload.passPercent ?? 70;
    document.getElementById('test-candidate').textContent = state.candidateName;
    document.getElementById('progress-total').textContent = String(state.questions.length);
    showView('test');
    renderQuestion();
  }

  function showResult(payload) {
    const result = payload.result || {};
    const panel = document.getElementById('result-panel');
    panel.classList.toggle('is-pass', !!result.passed);
    panel.classList.toggle('is-fail', !result.passed);
    document.getElementById('result-title').textContent = result.passed ? 'Réussi' : 'Échec';
    document.getElementById('result-percent').textContent = String(result.percent ?? 0);
    document.getElementById('result-correct').textContent = String(result.correct ?? 0);
    document.getElementById('result-total').textContent = String(result.total ?? 0);
    document.getElementById('result-msg').textContent = payload.message || '';
    showView('result');
  }

  async function boot() {
    try {
      const cfg = await api('/api/config');
      document.getElementById('welcome-title').textContent = cfg.title || 'Hydro-Québec';
      document.getElementById('welcome-subtitle').textContent = cfg.subtitle || 'Test de compétence';
      document.getElementById('meta-count').textContent = cfg.questionsPerTest ?? 8;
      document.getElementById('meta-pass').textContent = cfg.passPercent ?? 70;
      state.passPercent = cfg.passPercent ?? 70;
    } catch (_) {
      /* defaults already in HTML */
    }
    showView('welcome');
    document.getElementById('candidate-name').focus();
  }

  document.getElementById('welcome-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('candidate-name').value.trim();
    try {
      const payload = await api('/api/test/start', {
        method: 'POST',
        body: JSON.stringify({ name }),
      });
      openTest(payload);
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  document.getElementById('btn-prev').addEventListener('click', () => {
    if (state.index <= 0) return;
    state.index -= 1;
    renderQuestion();
  });

  document.getElementById('btn-next').addEventListener('click', async () => {
    const q = state.questions[state.index];
    if (!q) return;
    if (state.answers[q.id] === undefined) {
      showToast('Choisissez une réponse pour continuer.', 'error');
      return;
    }
    if (state.index >= state.questions.length - 1) {
      try {
        const payload = await api('/api/test/submit', {
          method: 'POST',
          body: JSON.stringify({ sessionId: state.sessionId, answers: state.answers }),
        });
        showResult(payload);
      } catch (err) {
        showToast(err.message, 'error');
      }
      return;
    }
    state.index += 1;
    renderQuestion();
  });

  document.getElementById('btn-retry').addEventListener('click', () => {
    document.getElementById('candidate-name').value = state.candidateName || '';
    showView('welcome');
  });

  boot();
})();
