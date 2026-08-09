window.VPIEditor = (() => {
  let zones = {};
  let currentZoneId = null;
  let currentSocketId = null;
  let playerCoords = null;

  const els = {
    root: () => document.getElementById('editor'),
    zoneSelect: () => document.getElementById('editor-zone-select'),
    socketList: () => document.getElementById('editor-socket-list'),
    form: () => document.getElementById('editor-form'),
    empty: () => document.getElementById('editor-empty'),
  };

  function open(data) {
    zones = structuredClone(data.zones || {});
    playerCoords = data.playerCoords || null;
    els.root().classList.remove('hidden');
    renderZoneSelect();
    const first = Object.keys(zones)[0];
    if (first) selectZone(first);
  }

  function close() {
    els.root().classList.add('hidden');
  }

  function renderZoneSelect() {
    const select = els.zoneSelect();
    select.innerHTML = Object.keys(zones).map((id) => {
      const z = zones[id];
      return `<option value="${id}">${z.label || id}</option>`;
    }).join('');
    select.onchange = () => selectZone(select.value);
  }

  function selectZone(id) {
    currentZoneId = id;
    currentSocketId = null;
    els.zoneSelect().value = id;
    renderSockets();
    showForm(false);
  }

  function renderSockets() {
    const zone = zones[currentZoneId];
    const list = els.socketList();
    const sockets = (zone && zone.sockets) || [];
    list.innerHTML = sockets.map((s) => (
      `<li data-id="${s.id}" class="${s.id === currentSocketId ? 'active' : ''}">${s.label || s.id}</li>`
    )).join('');
    list.querySelectorAll('li').forEach((li) => {
      li.onclick = () => selectSocket(li.getAttribute('data-id'));
    });
  }

  function selectSocket(socketId) {
    currentSocketId = socketId;
    renderSockets();
    const socket = getSocket();
    if (!socket) return showForm(false);
    showForm(true);
    document.getElementById('f-id').value = socket.id || '';
    document.getElementById('f-label').value = socket.label || '';
    document.getElementById('f-x').value = socket.coords?.x ?? 0;
    document.getElementById('f-y').value = socket.coords?.y ?? 0;
    document.getElementById('f-z').value = socket.coords?.z ?? 0;
    document.getElementById('f-rx').value = socket.rotation?.x ?? 0;
    document.getElementById('f-ry').value = socket.rotation?.y ?? 0;
    document.getElementById('f-rz').value = socket.rotation?.z ?? 0;
    document.getElementById('f-items').value = (socket.allowedItems || []).join(', ');
    document.getElementById('f-max').value = socket.maxObjects || 1;
    document.getElementById('f-ownership').value = socket.ownership || 'public';
    document.getElementById('f-job').value = socket.job || '';
    document.getElementById('f-interactions').value = (socket.allowedInteractions || []).join(', ');
  }

  function getSocket() {
    const zone = zones[currentZoneId];
    if (!zone || !zone.sockets) return null;
    return zone.sockets.find((s) => s.id === currentSocketId) || null;
  }

  function showForm(show) {
    els.form().classList.toggle('hidden', !show);
    els.empty().classList.toggle('hidden', show);
  }

  function readFormIntoSocket() {
    const socket = getSocket();
    if (!socket) return;
    const newId = document.getElementById('f-id').value.trim();
    socket.id = newId;
    socket.label = document.getElementById('f-label').value.trim();
    socket.coords = {
      x: num('f-x'),
      y: num('f-y'),
      z: num('f-z'),
    };
    socket.rotation = {
      x: num('f-rx'),
      y: num('f-ry'),
      z: num('f-rz'),
    };
    socket.allowedItems = splitCsv(document.getElementById('f-items').value);
    socket.maxObjects = Math.max(1, parseInt(document.getElementById('f-max').value, 10) || 1);
    socket.ownership = document.getElementById('f-ownership').value;
    socket.job = document.getElementById('f-job').value.trim() || undefined;
    socket.allowedInteractions = splitCsv(document.getElementById('f-interactions').value);
    currentSocketId = newId;
  }

  function num(id) {
    return parseFloat(document.getElementById(id).value) || 0;
  }

  function splitCsv(value) {
    return String(value || '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  }

  function addZone() {
    const id = `zone_${Date.now().toString(36)}`;
    zones[id] = {
      id,
      label: 'New Zone',
      coords: playerCoords || { x: 0, y: 0, z: 0 },
      radius: 10,
      ownership: 'public',
      sockets: [],
    };
    renderZoneSelect();
    selectZone(id);
  }

  function addSocket() {
    if (!currentZoneId) return;
    const zone = zones[currentZoneId];
    zone.sockets = zone.sockets || [];
    const id = `socket_${zone.sockets.length + 1}`;
    zone.sockets.push({
      id,
      label: `Socket #${zone.sockets.length + 1}`,
      coords: playerCoords || { x: 0, y: 0, z: 0 },
      rotation: { x: 0, y: 0, z: 0 },
      allowedItems: [],
      maxObjects: 1,
      ownership: zone.ownership || 'public',
      job: zone.job,
    });
    selectSocket(id);
  }

  function deleteSocket() {
    if (!currentZoneId || !currentSocketId) return;
    const zone = zones[currentZoneId];
    zone.sockets = (zone.sockets || []).filter((s) => s.id !== currentSocketId);
    currentSocketId = null;
    renderSockets();
    showForm(false);
  }

  function useMyPosition() {
    window.VPIApp.post('editorGetCoords', {}).then((coords) => {
      if (!coords) return;
      playerCoords = coords;
      document.getElementById('f-x').value = coords.x.toFixed(3);
      document.getElementById('f-y').value = coords.y.toFixed(3);
      document.getElementById('f-z').value = coords.z.toFixed(3);
    });
  }

  function save() {
    if (currentSocketId) readFormIntoSocket();
    const zone = zones[currentZoneId];
    if (!zone) return;
    // normalize vector tables for Lua
    if (zone.coords) {
      zone.coords = { x: zone.coords.x, y: zone.coords.y, z: zone.coords.z };
    }
    (zone.sockets || []).forEach((s) => {
      s.coords = { x: s.coords.x, y: s.coords.y, z: s.coords.z };
      s.rotation = { x: s.rotation?.x || 0, y: s.rotation?.y || 0, z: s.rotation?.z || 0 };
    });
    window.VPIApp.post('editorSave', { zone });
    close();
  }

  function cancel() {
    window.VPIApp.post('editorCancel', {});
    close();
  }

  function bind() {
    document.getElementById('editor-add-zone').onclick = addZone;
    document.getElementById('editor-add-socket').onclick = addSocket;
    document.getElementById('editor-delete-socket').onclick = deleteSocket;
    document.getElementById('editor-use-coords').onclick = useMyPosition;
    document.getElementById('editor-save').onclick = save;
    document.getElementById('editor-cancel').onclick = cancel;
    document.getElementById('editor-close').onclick = cancel;

    ['f-id','f-label','f-x','f-y','f-z','f-rx','f-ry','f-rz','f-items','f-max','f-ownership','f-job','f-interactions']
      .forEach((id) => {
        const el = document.getElementById(id);
        if (el) el.addEventListener('change', () => {
          if (currentSocketId) {
            const prev = currentSocketId;
            readFormIntoSocket();
            if (prev !== currentSocketId) renderSockets();
          }
        });
      });
  }

  return { open, close, bind };
})();
