(() => {
  const app = document.getElementById('app');
  const toastEl = document.getElementById('toast');

  const views = {
    welcome: document.getElementById('view-welcome'),
    test: document.getElementById('view-test'),
    result: document.getElementById('view-result'),
    admin: document.getElementById('view-admin'),
  };

  let state = {
    mode: null,
    questions: [],
    index: 0,
    answers: {},
    candidateName: '',
    adminQuestions: [],
    editingId: null,
    passPercent: 70,
    preview: false,
  };

  const resourceName = (() => {
    try {
      if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
      }
    } catch (_) {}
    return 'veebiiz_hydrotest';
  })();

  async function post(event, data = {}) {
    if (state.preview) {
      return handlePreview(event, data);
    }
    try {
      const res = await fetch(`https://${resourceName}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
      });
      return await res.json().catch(() => ({ ok: true }));
    } catch (_) {
      return { ok: false };
    }
  }

  function applyTheme(theme = {}) {
    if (theme.primary) document.documentElement.style.setProperty('--primary', theme.primary);
    if (theme.primaryDark) document.documentElement.style.setProperty('--primary-dark', theme.primaryDark);
    if (theme.background) document.documentElement.style.setProperty('--bg', theme.background);
    if (theme.surface) document.documentElement.style.setProperty('--surface', theme.surface);
    if (theme.text) document.documentElement.style.setProperty('--text', theme.text);
    if (theme.danger) document.documentElement.style.setProperty('--danger', theme.danger);
    if (theme.success) document.documentElement.style.setProperty('--success', theme.success);
  }

  function showToast(message, type = 'info') {
    if (!message) return;
    toastEl.textContent = message;
    toastEl.classList.remove('hidden', 'is-error', 'is-success');
    if (type === 'error') toastEl.classList.add('is-error');
    if (type === 'success') toastEl.classList.add('is-success');
    toastEl.classList.add('is-visible');
    window.clearTimeout(showToast._t);
    showToast._t = window.setTimeout(() => {
      toastEl.classList.remove('is-visible');
    }, 2600);
  }

  function showView(name) {
    Object.entries(views).forEach(([key, el]) => {
      el.classList.toggle('hidden', key !== name);
    });
    state.mode = name;
  }

  function openApp() {
    app.classList.remove('hidden');
    app.classList.add('is-open');
    app.setAttribute('aria-hidden', 'false');
  }

  function closeApp() {
    app.classList.remove('is-open');
    window.setTimeout(() => {
      app.classList.add('hidden');
      app.setAttribute('aria-hidden', 'true');
      Object.values(views).forEach((el) => el.classList.add('hidden'));
      state.mode = null;
    }, 160);
  }

  function openWelcome(data = {}) {
    applyTheme(data.theme);
    document.getElementById('welcome-title').textContent = data.title || 'Hydro-Québec';
    document.getElementById('welcome-subtitle').textContent = data.subtitle || 'Test de compétence';
    document.getElementById('meta-count').textContent = data.questionsPerTest ?? 8;
    document.getElementById('meta-pass').textContent = data.passPercent ?? 70;
    document.getElementById('welcome-hint').textContent = data.footerHint || 'ESC pour fermer';
    document.getElementById('candidate-name').value = '';
    state.passPercent = data.passPercent ?? 70;
    openApp();
    showView('welcome');
    window.setTimeout(() => document.getElementById('candidate-name').focus(), 50);
  }

  function openTest(data = {}) {
    applyTheme(data.theme);
    state.questions = data.questions || [];
    state.index = 0;
    state.answers = {};
    state.candidateName = data.candidateName || '';
    state.passPercent = data.passPercent ?? 70;

    document.getElementById('test-brand').textContent = data.title || 'Hydro-Québec';
    document.getElementById('test-candidate').textContent = state.candidateName;
    document.getElementById('progress-total').textContent = String(state.questions.length);

    openApp();
    showView('test');
    renderQuestion();
  }

  function renderQuestion() {
    const q = state.questions[state.index];
    if (!q) return;

    const card = document.querySelector('.question-card');
    card.style.animation = 'none';
    // eslint-disable-next-line no-unused-expressions
    card.offsetHeight;
    card.style.animation = '';

    document.getElementById('q-category').textContent = q.category || 'Général';
    document.getElementById('q-text').textContent = q.question || '';
    document.getElementById('progress-current').textContent = String(state.index + 1);

    const pct = ((state.index + 1) / Math.max(state.questions.length, 1)) * 100;
    document.getElementById('progress-fill').style.width = `${pct}%`;

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
        document.getElementById('btn-next').disabled = false;
      });
      box.appendChild(btn);
    });

    document.getElementById('btn-prev').disabled = state.index === 0;
    const isLast = state.index >= state.questions.length - 1;
    const nextBtn = document.getElementById('btn-next');
    nextBtn.textContent = isLast ? 'Soumettre' : 'Suivant';
    nextBtn.disabled = state.answers[q.id] === undefined;
  }

  function showResult(payload = {}) {
    const result = payload.result || {};
    const panel = document.getElementById('result-panel');
    panel.classList.toggle('is-pass', !!result.passed);
    panel.classList.toggle('is-fail', !result.passed);

    document.getElementById('result-title').textContent = result.passed ? 'Réussi' : 'Échec';
    document.getElementById('result-percent').textContent = String(result.percent ?? 0);
    document.getElementById('result-correct').textContent = String(result.correct ?? 0);
    document.getElementById('result-total').textContent = String(result.total ?? 0);
    document.getElementById('result-msg').textContent =
      payload.message ||
      (result.passed
        ? 'Certification obtenue. Bravo!'
        : `Seuil requis: ${result.passPercent ?? state.passPercent}%.`);

    showView('result');
  }

  function openAdmin(data = {}) {
    applyTheme(data.theme);
    state.adminQuestions = (data.questions || []).map((q) => ({ ...q, answers: [...(q.answers || [])] }));
    document.getElementById('admin-title').textContent = data.title || 'Hydro-Québec';
    document.getElementById('admin-subtitle').textContent = data.subtitle || 'Administration des questions';
    openApp();
    showView('admin');
    renderAdminList();
    clearEditor();
  }

  function renderAdminList(selectId) {
    const list = document.getElementById('question-list');
    list.innerHTML = '';
    state.adminQuestions.forEach((q) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'q-item';
      if (q.active === false) btn.classList.add('is-inactive');
      if (selectId && q.id === selectId) btn.classList.add('is-active');
      btn.innerHTML = `<span class="q-item-cat"></span><span class="q-item-text"></span>`;
      btn.querySelector('.q-item-cat').textContent = q.category || 'Général';
      btn.querySelector('.q-item-text').textContent = q.question || '(sans titre)';
      btn.addEventListener('click', () => loadEditor(q.id));
      list.appendChild(btn);
    });
  }

  function clearEditor() {
    state.editingId = null;
    document.getElementById('question-form').classList.add('hidden');
    document.getElementById('admin-empty').classList.remove('hidden');
    document.querySelectorAll('.q-item').forEach((el) => el.classList.remove('is-active'));
  }

  function loadEditor(id) {
    const q = state.adminQuestions.find((item) => item.id === id);
    if (!q) return;
    state.editingId = id;
    document.getElementById('admin-empty').classList.add('hidden');
    const form = document.getElementById('question-form');
    form.classList.remove('hidden');
    document.getElementById('edit-id').value = q.id || '';
    document.getElementById('edit-category').value = q.category || '';
    document.getElementById('edit-question').value = q.question || '';
    document.getElementById('edit-active').checked = q.active !== false;
    renderEditAnswers(q.answers || [], q.correct ?? 0);
    renderAdminList(id);
  }

  function renderEditAnswers(answers, correctIndex) {
    const box = document.getElementById('edit-answers');
    box.innerHTML = '';
    const list = answers.length ? answers : ['', ''];
    list.forEach((text, i) => {
      const row = document.createElement('div');
      row.className = 'edit-answer-row';
      row.innerHTML = `
        <input type="radio" name="correct-answer" value="${i}" ${i === correctIndex ? 'checked' : ''} />
        <input type="text" class="edit-answer-text" maxlength="220" placeholder="Réponse ${i + 1}" />
        <button type="button" class="btn ghost small edit-remove" title="Retirer">×</button>
      `;
      row.querySelector('.edit-answer-text').value = text;
      row.querySelector('.edit-remove').addEventListener('click', () => {
        const current = collectEditAnswers().answers;
        if (current.length <= 2) {
          showToast('Minimum 2 réponses.', 'error');
          return;
        }
        current.splice(i, 1);
        let correct = collectEditAnswers().correct;
        if (correct >= current.length) correct = current.length - 1;
        if (correct === i) correct = 0;
        else if (correct > i) correct -= 1;
        renderEditAnswers(current, correct);
      });
      box.appendChild(row);
    });
  }

  function collectEditAnswers() {
    const texts = [...document.querySelectorAll('.edit-answer-text')].map((el) => el.value);
    const checked = document.querySelector('input[name="correct-answer"]:checked');
    return {
      answers: texts,
      correct: checked ? Number(checked.value) : 0,
    };
  }

  function collectQuestionFromForm() {
    const { answers, correct } = collectEditAnswers();
    return {
      id: document.getElementById('edit-id').value || undefined,
      category: document.getElementById('edit-category').value.trim() || 'Général',
      question: document.getElementById('edit-question').value.trim(),
      answers,
      correct,
      active: document.getElementById('edit-active').checked,
    };
  }

  // Preview mode helpers (browser without FiveM)
  const PREVIEW_BANK = [
    {
      id: 'q1',
      category: 'Sécurité',
      question: "Avant d'intervenir près d'une ligne électrique aérienne, que devez-vous faire en premier?",
      answers: [
        "Vérifier la distance d'approche sécuritaire et l'état du matériel",
        'Toucher le câble pour tester s\'il est sous tension',
        "Couper l'arbre le plus proche sans balisage",
        'Travailler seul pour aller plus vite',
      ],
      correct: 0,
      active: true,
    },
    {
      id: 'q4',
      category: 'Batterie',
      question: "Lors du manutentionnement d'une batterie de secours (UPS / poste), quel risque principal devez-vous prévenir?",
      answers: [
        "Court-circuit, déversement d'électrolyte et gaz explosifs",
        "Surpression d'eau uniquement",
        'Rayonnement ultraviolet',
        'Congélation immédiate du boîtier',
      ],
      correct: 0,
      active: true,
    },
    {
      id: 'q5',
      category: 'Batterie',
      question: 'Avant de brancher ou de remplacer une batterie de système de contrôle, vous devez:',
      answers: [
        "Isoler l'alimentation, porter les EPI et respecter la polarité",
        'Brancher à chaud sans vérification',
        'Mélanger des batteries de tensions différentes',
        'Court-circuiter les bornes pour tester la charge',
      ],
      correct: 0,
      active: true,
    },
    {
      id: 'q8',
      category: 'Consignation',
      question: 'La consignation électrique a pour but de:',
      answers: [
        "Mettre hors tension et verrouiller l'énergie avant l'intervention",
        'Augmenter la tension pour accélérer le test',
        'Remplacer le permis de travail',
        'Autoriser le travail sous tension sans EPI',
      ],
      correct: 0,
      active: true,
    },
    {
      id: 'q9',
      category: 'Urgence',
      question: 'Vous découvrez un fil tombé au sol après une tempête. Que faire?',
      answers: [
        'Rester à distance, sécuriser la zone et aviser Hydro-Québec / le superviseur',
        'Le ramasser et le remettre sur le poteau',
        'Couper le fil avec une scie',
        'Ignorer et continuer la patrouille',
      ],
      correct: 0,
      active: true,
    },
    {
      id: 'q12',
      category: 'Batterie',
      question: 'Où stocker idéalement des batteries de rechange sur un site?',
      answers: [
        "Dans un local ventilé, sec, à l'abri des sources d'ignition",
        "Près d'un radiateur ouvert",
        'Dans un local fermé sans ventilation',
        "À l'extérieur sans protection",
      ],
      correct: 0,
      active: true,
    },
  ];

  function shuffle(arr) {
    const t = [...arr];
    for (let i = t.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [t[i], t[j]] = [t[j], t[i]];
    }
    return t;
  }

  function handlePreview(event, data) {
    if (event === 'close') {
      closeApp();
      return { ok: true };
    }
    if (event === 'startTest') {
      const name = (data.name || '').trim();
      if (name.length < 2) {
        showToast('Entrez votre nom pour commencer.', 'error');
        return { ok: false };
      }
      const picked = shuffle(PREVIEW_BANK).slice(0, 5).map((q) => {
        const order = q.answers.map((text, i) => ({ text, i }));
        const shuffled = shuffle(order);
        const answers = shuffled.map((x) => x.text);
        const correct = shuffled.findIndex((x) => x.i === q.correct);
        return { id: q.id, category: q.category, question: q.question, answers, _correct: correct };
      });
      state._previewKey = Object.fromEntries(picked.map((q) => [q.id, q._correct]));
      openTest({
        title: 'Hydro-Québec',
        candidateName: name,
        passPercent: 70,
        questions: picked.map(({ id, category, question, answers }) => ({ id, category, question, answers })),
      });
      return { ok: true };
    }
    if (event === 'submitTest') {
      const answers = data.answers || {};
      let correct = 0;
      const total = Object.keys(state._previewKey || {}).length;
      Object.entries(state._previewKey || {}).forEach(([id, expected]) => {
        if (Number(answers[id]) === Number(expected)) correct += 1;
      });
      const percent = total ? Math.round((correct / total) * 100) : 0;
      const passed = percent >= 70;
      showResult({
        result: { correct, total, percent, passed, passPercent: 70, name: state.candidateName },
        message: passed
          ? 'Félicitations — certification Hydro-Québec réussie.'
          : 'Échec du test. Révisez le matériel et réessayez.',
      });
      return { ok: true };
    }
    if (event === 'adminUpsert') {
      const q = data.question || data;
      if (!q.question || !q.answers || q.answers.length < 2) {
        showToast('Question invalide.', 'error');
        return { ok: false };
      }
      if (q.id) {
        const idx = state.adminQuestions.findIndex((x) => x.id === q.id);
        if (idx >= 0) state.adminQuestions[idx] = { ...q };
        else state.adminQuestions.push({ ...q, id: q.id });
      } else {
        const id = `q${Date.now()}`;
        state.adminQuestions.push({ ...q, id });
        q.id = id;
      }
      renderAdminList(q.id);
      loadEditor(q.id);
      showToast('Question enregistrée (aperçu local).', 'success');
      return { ok: true };
    }
    if (event === 'adminDelete') {
      state.adminQuestions = state.adminQuestions.filter((q) => q.id !== data.id);
      renderAdminList();
      clearEditor();
      showToast('Question supprimée (aperçu local).', 'success');
      return { ok: true };
    }
    return { ok: true };
  }

  // Events
  document.getElementById('welcome-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const name = document.getElementById('candidate-name').value.trim();
    post('startTest', { name });
  });

  document.getElementById('btn-prev').addEventListener('click', () => {
    if (state.index <= 0) return;
    state.index -= 1;
    renderQuestion();
  });

  document.getElementById('btn-next').addEventListener('click', () => {
    const q = state.questions[state.index];
    if (!q || state.answers[q.id] === undefined) return;
    if (state.index >= state.questions.length - 1) {
      post('submitTest', { answers: state.answers });
      return;
    }
    state.index += 1;
    renderQuestion();
  });

  document.getElementById('btn-retry').addEventListener('click', () => {
    openWelcome({
      title: 'Hydro-Québec',
      subtitle: 'Test de compétence',
      questionsPerTest: state.questions.length || 8,
      passPercent: state.passPercent,
    });
  });

  document.getElementById('btn-close-result').addEventListener('click', () => post('close'));
  document.getElementById('btn-close-admin').addEventListener('click', () => post('close'));

  document.getElementById('btn-new-question').addEventListener('click', () => {
    const id = `new-${Date.now()}`;
    const blank = {
      id,
      category: 'Général',
      question: '',
      answers: ['', ''],
      correct: 0,
      active: true,
      _isNew: true,
    };
    // Keep out of list until saved — load editor only
    state.editingId = id;
    document.getElementById('admin-empty').classList.add('hidden');
    document.getElementById('question-form').classList.remove('hidden');
    document.getElementById('edit-id').value = '';
    document.getElementById('edit-category').value = 'Général';
    document.getElementById('edit-question').value = '';
    document.getElementById('edit-active').checked = true;
    renderEditAnswers(['', ''], 0);
    document.querySelectorAll('.q-item').forEach((el) => el.classList.remove('is-active'));
    document.getElementById('edit-question').focus();
  });

  document.getElementById('btn-add-answer').addEventListener('click', () => {
    const current = collectEditAnswers();
    current.answers.push('');
    renderEditAnswers(current.answers, current.correct);
  });

  document.getElementById('question-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const question = collectQuestionFromForm();
    if (!question.question) {
      showToast('La question est requise.', 'error');
      return;
    }
    if (question.answers.some((a) => !String(a).trim())) {
      showToast('Toutes les réponses doivent être remplies.', 'error');
      return;
    }
    post('adminUpsert', { question });
  });

  document.getElementById('btn-delete-question').addEventListener('click', () => {
    const id = document.getElementById('edit-id').value;
    if (!id) {
      clearEditor();
      return;
    }
    if (!window.confirm('Supprimer cette question?')) return;
    post('adminDelete', { id });
  });

  window.addEventListener('keydown', (event) => {
    if (app.classList.contains('hidden')) return;
    if (event.key === 'Escape') {
      event.preventDefault();
      post('close');
    }
  });

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    const action = msg.action;
    const data = msg.data || {};

    switch (action) {
      case 'openWelcome':
        openWelcome(data);
        break;
      case 'openTest':
        openTest(data);
        break;
      case 'showResult':
        showResult(data);
        break;
      case 'openAdmin':
        openAdmin(data);
        break;
      case 'adminSaved': {
        state.adminQuestions = data.questions || [];
        const formId = document.getElementById('edit-id').value;
        const still =
          state.adminQuestions.find((q) => q.id === state.editingId) ||
          state.adminQuestions.find((q) => q.id === formId) ||
          state.adminQuestions[state.adminQuestions.length - 1];
        if (still) {
          loadEditor(still.id);
        } else {
          renderAdminList();
          clearEditor();
        }
        break;
      }
      case 'close':
        closeApp();
        break;
      case 'toast':
        showToast(data.message, data.type);
        break;
      default:
        break;
    }
  });

  // Browser preview: ?preview=1 (test) or ?preview=admin
  const params = new URLSearchParams(window.location.search);
  if (params.has('preview')) {
    state.preview = true;
    const mode = params.get('preview');
    if (mode === 'admin') {
      openAdmin({
        title: 'Hydro-Québec',
        subtitle: 'Administration des questions',
        questions: PREVIEW_BANK.map((q) => ({ ...q, answers: [...q.answers] })),
        theme: { primary: '#00A3A1', primaryDark: '#007A78' },
      });
    } else {
      openWelcome({
        title: 'Hydro-Québec',
        subtitle: 'Test de compétence',
        questionsPerTest: 5,
        passPercent: 70,
        footerHint: 'ESC pour fermer · Mode aperçu',
        theme: { primary: '#00A3A1', primaryDark: '#007A78' },
      });
    }
  }
})();
