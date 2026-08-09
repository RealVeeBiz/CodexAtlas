window.VPIPrompt = (() => {
  const root = () => document.getElementById('prompt');
  const labelEl = () => document.getElementById('prompt-label');
  const categoryEl = () => document.getElementById('prompt-category');
  const metaEl = () => document.getElementById('prompt-meta');
  const actionsEl = () => document.getElementById('prompt-actions');

  let hideTimer = null;
  let currentObjectId = null;

  function show(data) {
    const el = root();
    if (hideTimer) {
      clearTimeout(hideTimer);
      hideTimer = null;
    }
    el.classList.remove('hidden', 'hiding');

    currentObjectId = data.objectId;
    labelEl().textContent = data.label || 'Item';
    categoryEl().textContent = data.category || 'Object';

    const lines = data.lines || [];
    metaEl().innerHTML = lines.map((l) => `<div>${escapeHtml(l)}</div>`).join('');

    const actions = data.interactions || [];
    actionsEl().innerHTML = actions.map((a) => {
      const icon = window.VPIIcons.get(a.icon || 'hand');
      return `<li data-action="${escapeAttr(a.name)}">
        <kbd>${escapeHtml(a.key || '•')}</kbd>
        <span class="action-label">${escapeHtml(a.label || a.name)}</span>
        <span class="action-icon">${icon}</span>
      </li>`;
    }).join('');

    actionsEl().querySelectorAll('li').forEach((li) => {
      li.addEventListener('click', () => {
        const action = li.getAttribute('data-action');
        window.VPIApp.post('selectInteraction', {
          objectId: currentObjectId,
          action,
        });
      });
    });
  }

  function hide() {
    const el = root();
    if (el.classList.contains('hidden')) return;
    el.classList.add('hiding');
    hideTimer = setTimeout(() => {
      el.classList.add('hidden');
      el.classList.remove('hiding');
      hideTimer = null;
    }, 150);
  }

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function escapeAttr(str) {
    return escapeHtml(str).replace(/"/g, '&quot;');
  }

  return { show, hide };
})();
