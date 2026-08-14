(() => {
  const app = document.getElementById('app');
  const confirmEl = document.getElementById('confirm');
  const rulesList = document.getElementById('rules-list');
  const linksGrid = document.getElementById('links-grid');

  let state = {
    confirmDisconnect: true,
    allowMap: true,
    allowSettings: true,
  };

  const resourceName = (() => {
    try {
      if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
      }
    } catch (_) {}
    return 'veebiiz_pausemenu';
  })();

  async function post(event, data = {}) {
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

  function openExternal(url) {
    if (!url) return;
    try {
      if (typeof window.invokeNative === 'function') {
        window.invokeNative('openUrl', url);
        return;
      }
    } catch (_) {}
    window.open(url, '_blank', 'noopener,noreferrer');
  }

  function setText(id, value, fallback = '—') {
    const el = document.getElementById(id);
    if (!el) return;
    const text = value === undefined || value === null || value === '' ? fallback : String(value);
    el.textContent = text;
  }

  function renderRules(rules = []) {
    rulesList.innerHTML = '';
    rules.forEach((rule) => {
      const li = document.createElement('li');
      li.innerHTML = `
        <div>
          <div class="rule-title"></div>
          <div class="rule-body"></div>
        </div>
      `;
      li.querySelector('.rule-title').textContent = rule.title || 'Rule';
      li.querySelector('.rule-body').textContent = rule.body || '';
      rulesList.appendChild(li);
    });
  }

  function iconGlyph(icon) {
    switch (icon) {
      case 'discord':
        return 'D';
      case 'globe':
        return 'W';
      case 'cart':
        return '$';
      case 'video':
        return '▶';
      default:
        return '→';
    }
  }

  function renderLinks(links = []) {
    linksGrid.innerHTML = '';
    links.forEach((link) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'link-btn';
      btn.innerHTML = `
        <span class="link-icon"></span>
        <span class="link-label"></span>
        <span class="link-desc"></span>
      `;
      btn.querySelector('.link-icon').textContent = iconGlyph(link.icon);
      btn.querySelector('.link-label').textContent = link.label || 'Link';
      btn.querySelector('.link-desc').textContent = link.description || link.url || '';
      btn.addEventListener('click', () => {
        openExternal(link.url);
        post('openLink', { url: link.url, id: link.id });
      });
      linksGrid.appendChild(btn);
    });
  }

  function setTab(tab) {
    document.querySelectorAll('.nav-btn[data-tab]').forEach((btn) => {
      btn.classList.toggle('is-active', btn.dataset.tab === tab);
    });
    document.querySelectorAll('.panel').forEach((panel) => {
      panel.classList.toggle('is-active', panel.dataset.panel === tab);
    });
  }

  function applyPlayerData(data = {}) {
    setText('player-name', data.name);
    setText('player-id', data.serverId);
    setText('player-ping', data.ping);
    setText('player-job', data.job, 'Civilian');
    setText('player-job-grade', data.jobGrade, '');
    setText('player-cash', data.cash, '$0');
    setText('player-bank', data.bank, '$0');
    setText(
      'player-online',
      data.playersOnline != null ? `${data.playersOnline}/${data.maxClients || '?'}` : null
    );
    setText('player-gang', data.gang, 'None');
    setText('player-playtime', data.playtime);
    setText('player-license', data.licenseShort);
    setText('player-framework', data.framework);
  }

  function showConfirm(show) {
    confirmEl.classList.toggle('hidden', !show);
  }

  function openUi(payload = {}) {
    state.confirmDisconnect = payload.confirmDisconnect !== false;
    state.allowMap = payload.allowMap !== false;
    state.allowSettings = payload.allowSettings !== false;

    setText('server-name', payload.serverName, 'SERVER');
    setText('server-tagline', payload.tagline, '');
    setText('footer-hint', payload.footerHint, 'ESC to resume');

    document.getElementById('btn-map').classList.toggle('hidden', !state.allowMap);
    document.getElementById('btn-settings').classList.toggle('hidden', !state.allowSettings);

    if (payload.theme && payload.theme.primary) {
      document.documentElement.style.setProperty('--yellow', payload.theme.primary);
    }

    renderRules(payload.rules || []);
    renderLinks(payload.links || []);
    setTab('overview');
    showConfirm(false);

    app.classList.remove('hidden', 'is-closing');
    app.classList.add('is-open');
    app.setAttribute('aria-hidden', 'false');
  }

  function closeUi() {
    if (app.classList.contains('hidden')) return;
    app.classList.remove('is-open');
    app.classList.add('is-closing');
    showConfirm(false);
    window.setTimeout(() => {
      app.classList.add('hidden');
      app.classList.remove('is-closing');
      app.setAttribute('aria-hidden', 'true');
    }, 160);
  }

  document.getElementById('nav').addEventListener('click', (event) => {
    const btn = event.target.closest('.nav-btn');
    if (!btn) return;

    if (btn.dataset.tab) {
      setTab(btn.dataset.tab);
      return;
    }

    if (btn.dataset.action === 'map') {
      post('openMap');
      return;
    }

    if (btn.dataset.action === 'settings') {
      post('openSettings');
    }
  });

  document.getElementById('btn-resume').addEventListener('click', () => {
    post('resume');
  });

  document.getElementById('btn-disconnect').addEventListener('click', () => {
    if (state.confirmDisconnect) {
      showConfirm(true);
    } else {
      post('disconnect');
    }
  });

  document.getElementById('confirm-cancel').addEventListener('click', () => {
    showConfirm(false);
  });

  document.getElementById('confirm-ok').addEventListener('click', () => {
    post('disconnect');
  });

  window.addEventListener('keydown', (event) => {
    if (app.classList.contains('hidden')) return;
    if (event.key === 'Escape') {
      event.preventDefault();
      if (!confirmEl.classList.contains('hidden')) {
        showConfirm(false);
        return;
      }
      post('close');
    }
  });

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    const action = msg.action;
    const data = msg.data || {};

    switch (action) {
      case 'open':
        openUi(data);
        break;
      case 'close':
        closeUi();
        break;
      case 'playerData':
        applyPlayerData(data);
        break;
      case 'openExternal':
        openExternal(data.url);
        break;
      default:
        break;
    }
  });

  // Browser preview helper: open with ?preview=1
  if (new URLSearchParams(window.location.search).has('preview')) {
    openUi({
      serverName: 'VeeBiiz RP',
      tagline: 'Stay sharp. Play fair. Build the city.',
      rules: [
        { title: 'Respect players & staff', body: 'No harassment or toxic behavior.' },
        { title: 'No RDM / VDM', body: 'Always have a valid roleplay reason.' },
        { title: 'Value your life', body: 'Fear RP matters.' },
      ],
      links: [
        { id: 'discord', label: 'Discord', description: 'Community hub', url: 'https://discord.gg/example', icon: 'discord' },
        { id: 'website', label: 'Website', description: 'Rules & apps', url: 'https://example.com', icon: 'globe' },
        { id: 'store', label: 'Store', description: 'Support the server', url: 'https://example.com/store', icon: 'cart' },
        { id: 'tiktok', label: 'TikTok', description: 'Highlights', url: 'https://tiktok.com', icon: 'video' },
      ],
      footerHint: 'ESC to resume · Preview mode',
      theme: { primary: '#F5C518' },
    });
    applyPlayerData({
      name: 'Jordan Reyes',
      serverId: 17,
      ping: 42,
      job: 'Mechanic',
      jobGrade: 'Senior',
      cash: '$3,450',
      bank: '$28,900',
      playersOnline: 64,
      maxClients: 128,
      gang: 'None',
      playtime: '42h 15m',
      licenseShort: 'a1b2c3d4',
      framework: 'qbox',
    });
  }
})();
