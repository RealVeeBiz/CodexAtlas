(() => {
  const toastEl = document.getElementById('toast');
  const loginView = document.getElementById('view-login');
  const adminView = document.getElementById('view-admin');

  let questions = [];
  let editingId = null;

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

  function showAdmin(loggedIn) {
    loginView.classList.toggle('hidden', loggedIn);
    adminView.classList.toggle('hidden', !loggedIn);
  }

  function renderList(selectId) {
    const list = document.getElementById('question-list');
    list.innerHTML = '';
    questions.forEach((q) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'q-item';
      if (q.active === false) btn.classList.add('is-inactive');
      if (selectId && q.id === selectId) btn.classList.add('is-active');
      btn.innerHTML = '<span class="q-item-cat"></span><span class="q-item-text"></span>';
      btn.querySelector('.q-item-cat').textContent = q.category || 'Général';
      btn.querySelector('.q-item-text').textContent = q.question || '(sans titre)';
      btn.addEventListener('click', () => loadEditor(q.id));
      list.appendChild(btn);
    });
  }

  function clearEditor() {
    editingId = null;
    document.getElementById('question-form').classList.add('hidden');
    document.getElementById('admin-empty').classList.remove('hidden');
    document.querySelectorAll('.q-item').forEach((el) => el.classList.remove('is-active'));
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
    return { answers: texts, correct: checked ? Number(checked.value) : 0 };
  }

  function loadEditor(id) {
    const q = questions.find((item) => item.id === id);
    if (!q) return;
    editingId = id;
    document.getElementById('admin-empty').classList.add('hidden');
    document.getElementById('question-form').classList.remove('hidden');
    document.getElementById('edit-id').value = q.id || '';
    document.getElementById('edit-category').value = q.category || '';
    document.getElementById('edit-question').value = q.question || '';
    document.getElementById('edit-active').checked = q.active !== false;
    renderEditAnswers(q.answers || [], q.correct ?? 0);
    renderList(id);
  }

  async function refreshQuestions(selectId) {
    const data = await api('/api/admin/questions');
    questions = data.questions || [];
    renderList(selectId);
    if (selectId) {
      const still = questions.find((q) => q.id === selectId);
      if (still) loadEditor(still.id);
      else clearEditor();
    }
  }

  async function refreshResults() {
    const data = await api('/api/admin/results');
    const box = document.getElementById('results-list');
    box.innerHTML = '';
    const rows = data.results || [];
    if (!rows.length) {
      box.innerHTML = '<p class="muted">Aucun résultat pour le moment.</p>';
      return;
    }
    rows.slice(0, 20).forEach((r) => {
      const row = document.createElement('div');
      row.className = `result-row ${r.passed ? 'is-pass' : 'is-fail'}`;
      const when = r.at ? new Date(r.at).toLocaleString('fr-CA') : '';
      row.innerHTML = `
        <strong></strong>
        <span class="result-row-score"></span>
        <span class="result-row-meta"></span>
      `;
      row.querySelector('strong').textContent = r.name || '—';
      row.querySelector('.result-row-score').textContent =
        `${r.percent}% (${r.correct}/${r.total}) · ${r.passed ? 'Réussi' : 'Échec'}`;
      row.querySelector('.result-row-meta').textContent = when;
      box.appendChild(row);
    });
  }

  async function enterAdmin() {
    showAdmin(true);
    await refreshQuestions();
    await refreshResults();
    clearEditor();
  }

  document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const password = document.getElementById('admin-password').value;
    try {
      await api('/api/admin/login', {
        method: 'POST',
        body: JSON.stringify({ password }),
      });
      await enterAdmin();
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  document.getElementById('btn-logout').addEventListener('click', async () => {
    await api('/api/admin/logout', { method: 'POST', body: '{}' });
    showAdmin(false);
    document.getElementById('admin-password').value = '';
  });

  document.getElementById('btn-new-question').addEventListener('click', () => {
    editingId = null;
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

  document.getElementById('question-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const { answers, correct } = collectEditAnswers();
    const question = {
      id: document.getElementById('edit-id').value || undefined,
      category: document.getElementById('edit-category').value.trim() || 'Général',
      question: document.getElementById('edit-question').value.trim(),
      answers,
      correct,
      active: document.getElementById('edit-active').checked,
    };
    if (!question.question) {
      showToast('La question est requise.', 'error');
      return;
    }
    if (answers.some((a) => !String(a).trim())) {
      showToast('Toutes les réponses doivent être remplies.', 'error');
      return;
    }
    try {
      const data = await api('/api/admin/questions', {
        method: 'POST',
        body: JSON.stringify({ question }),
      });
      questions = data.questions || [];
      const id = data.question?.id;
      renderList(id);
      if (id) loadEditor(id);
      showToast('Question enregistrée.', 'success');
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  document.getElementById('btn-delete-question').addEventListener('click', async () => {
    const id = document.getElementById('edit-id').value;
    if (!id) {
      clearEditor();
      return;
    }
    if (!window.confirm('Supprimer cette question?')) return;
    try {
      const data = await api(`/api/admin/questions/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
      questions = data.questions || [];
      renderList();
      clearEditor();
      showToast('Question supprimée.', 'success');
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  document.getElementById('btn-refresh-results').addEventListener('click', async () => {
    try {
      await refreshResults();
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  (async () => {
    try {
      const me = await api('/api/admin/me');
      if (me.admin) await enterAdmin();
      else showAdmin(false);
    } catch (_) {
      showAdmin(false);
    }
  })();
})();
