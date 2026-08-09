window.VPIApp = (() => {
  const resource = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'veebiiz_physicalitems';

  async function post(event, data = {}) {
    const resp = await fetch(`https://${resource}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    try {
      return await resp.json();
    } catch {
      return null;
    }
  }

  function setPlacement(data) {
    const el = document.getElementById('placement');
    const status = document.getElementById('placement-status');
    const detail = document.getElementById('placement-detail');

    if (!data || !data.active) {
      el.classList.add('hidden');
      return;
    }

    el.classList.remove('hidden');
    if (data.valid) {
      status.textContent = 'Valid placement';
      status.className = 'placement-status valid';
      detail.textContent = `${data.zoneLabel || data.zoneId || ''} · ${data.socketLabel || data.socketId || ''}`;
    } else if (data.socketId) {
      status.textContent = 'Invalid placement';
      status.className = 'placement-status invalid';
      detail.textContent = `${data.socketLabel || data.socketId} is not compatible`;
    } else {
      status.textContent = 'Searching for socket…';
      status.className = 'placement-status';
      detail.textContent = 'Walk near a compatible placement socket';
    }
  }

  function setCarry(data) {
    const el = document.getElementById('carry');
    const label = document.getElementById('carry-label');
    if (!data || !data.active) {
      el.classList.add('hidden');
      return;
    }
    el.classList.remove('hidden');
    label.textContent = `Carrying ${data.label || data.item || 'item'}`;
  }

  function setDebug(data) {
    const el = document.getElementById('debug');
    const body = document.getElementById('debug-body');
    if (!data) {
      el.classList.add('hidden');
      return;
    }
    el.classList.remove('hidden');
    body.textContent = [
      `ZONE: ${data.zone || '-'}`,
      `SOCKET: ${data.socket || '-'}`,
      `OBJECT: ${data.object || '-'}`,
      `ENTITY: ${data.entity || '-'}`,
      `ITEM: ${data.item || '-'}`,
      `DISTANCE: ${data.distance || '-'}m`,
      `OWNERSHIP: ${data.ownership || '-'}`,
      `STATE: ${JSON.stringify(data.state || {})}`,
    ].join('\n');
  }

  window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};
    switch (action) {
      case 'showPrompt':
        window.VPIPrompt.show(data || {});
        break;
      case 'hidePrompt':
        window.VPIPrompt.hide();
        break;
      case 'placement':
        setPlacement(data);
        break;
      case 'carry':
        setCarry(data);
        break;
      case 'debug':
        setDebug(data);
        break;
      case 'openEditor':
        window.VPIEditor.open(data || {});
        break;
      default:
        break;
    }
  });

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      const editor = document.getElementById('editor');
      if (!editor.classList.contains('hidden')) {
        window.VPIEditor.close();
        post('editorCancel', {});
      }
    }
  });

  window.VPIEditor.bind();
  post('ready', {});

  return { post };
})();
